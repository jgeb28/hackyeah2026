import { hilog } from '@kit.PerformanceAnalysisKit';
import { LayaAnswer, LayaRequest, LayaResponse, QuestionType } from '../../domain/model/Decision';
import { GuardianSchema, SchemaQuestion } from '../../domain/model/GuardianSchema';
import { AssetLoader } from '../assets/AssetLoader';
import { InferenceConfig } from '../config/InferenceConfig';
import { InferenceResult, LayaEngineClient } from './LayaEngineClient';

const DOMAIN: number = 0x0000;
const TAG: string = 'LayaDevice';

/** Thrown when the on-device `.ms` asset is not bundled. */
export class ModelNotInstalledError extends Error {
}

/** Shape of the converter's `laya_guardian_meta.json`. */
interface LayaMetaDto {
  prefixes?: number[][];
  markers?: number[][];
  sep_id?: number;
  pad_id?: number;
  max_len?: number;
  questions?: string[];
  labels?: Record<string, string[]>;
  temperatures?: number[];
}

/**
 * Runs Laya locally with MindSpore Lite — no network.
 *
 * The heavy work (loading the 1.7 GB `.ms` and `predict`) runs in `LayaWorker`
 * so this class never blocks the UI thread. Here we only materialise the bundled
 * model into the sandbox, hand the worker its inputs, and turn the returned
 * logits into a Guardian verdict.
 *
 * Graph contract (produced by `~/tmp/convert_laya.py`; see LAYA_INTEGRATION.md):
 *   input  "input_ids"      int32 [Q, max_len]   one Laya sequence per question
 *   input  "attention_mask" int32 [Q, max_len]   1 = real token, 0 = pad
 *   output "logits"         fp32  [1, Q, MAX_OPTIONS]  (temperature-scaled)
 */
export class MindSporeLiteEngine {
  private readonly config: InferenceConfig;
  private readonly assets: AssetLoader;
  private readonly filesDir: string;
  private client: LayaEngineClient | null = null;

  constructor(config: InferenceConfig, assets: AssetLoader, filesDir: string) {
    this.config = config;
    this.assets = assets;
    this.filesDir = filesDir;
  }

  /** Materialise the model (once) and start the worker; safe to call repeatedly. */
  async ensureReady(): Promise<void> {
    if (this.client !== null) {
      return;
    }

    const metaText: string = await this.assets.readText(this.config.metaPath);
    const meta: LayaMetaDto = JSON.parse(metaText) as LayaMetaDto;
    if (meta.prefixes === undefined || meta.prefixes.length === 0) {
      throw new ModelNotInstalledError('laya_guardian_meta.json has no prefixes');
    }

    // MindSpore Lite cannot read a rawfile fd directly: `getRawFdSync` returns
    // the *HAP* fd plus a non-zero `offset`, and `loadModelFromFd` reads from
    // position 0 (=> "Invalid mslite model"). Materialise the asset once.
    const modelPath: string = `${this.filesDir}/${this.config.msFileName}`;
    if (!this.assets.fileExists(modelPath)) {
      try {
        const copied: number = await this.assets.copyRawfileTo(this.config.msModelPath, modelPath);
        hilog.info(DOMAIN, TAG, 'Materialised model: %{public}d bytes -> %{public}s', copied, modelPath);
      } catch (error) {
        hilog.warn(DOMAIN, TAG, 'rawfile model copy failed: %{public}s', describe(error as Error));
      }
    } else {
      hilog.info(DOMAIN, TAG, 'Using existing sandbox model: %{public}s', modelPath);
    }

    const tokenizerText: string = await this.assets.readText(this.config.tokenizerPath);
    const client = new LayaEngineClient(modelPath, metaText, tokenizerText);
    await client.start();
    this.client = client;
    hilog.info(DOMAIN, TAG, 'Engine ready (%{public}s) — inference runs in worker',
      this.config.quantization.dtype);
  }

  async infer(request: LayaRequest): Promise<LayaResponse> {
    await this.ensureReady();
    const client: LayaEngineClient = this.client as LayaEngineClient;
    const result: InferenceResult = await client.inferLogits(request.state);
    return this.decode(result.logits, result.latencyMs);
  }

  private decode(logits: Float32Array, latencyMs: number): LayaResponse {
    const response = new LayaResponse();
    response.model = `laya-${this.config.quantization.dtype}`;
    response.latencyMs = latencyMs;

    const questions: SchemaQuestion[] = GuardianSchema.questions();
    const width: number = GuardianSchema.maxOptions();
    for (let q = 0; q < questions.length; q++) {
      const schema: SchemaQuestion = questions[q];
      const offset: number = q * width;
      const count: number = schema.labels.length;
      const probs: number[] = softmax(logits, offset, count);
      response.answers[schema.key] = this.toAnswer(schema, probs);
    }
    return response;
  }

  private toAnswer(schema: SchemaQuestion, probs: number[]): LayaAnswer {
    const answer = new LayaAnswer();
    answer.kind = schema.kind;

    const probabilities: Record<string, number> = {};
    let bestIndex: number = 0;
    for (let i = 0; i < probs.length; i++) {
      probabilities[schema.labels[i]] = probs[i];
      if (probs[i] > probs[bestIndex]) {
        bestIndex = i;
      }
    }
    answer.probabilities = probabilities;
    answer.confidence = probs[bestIndex];

    if (schema.kind === QuestionType.NOUL) {
      answer.noul = probs.length > 1 ? probs[1] : 0;
    } else if (schema.kind === QuestionType.SCORE) {
      let expected: number = 0;
      for (let i = 0; i < probs.length; i++) {
        expected += i * probs[i];
      }
      answer.score = expected;
    } else {
      answer.choice = schema.labels[bestIndex];
    }
    return answer;
  }
}

/** Numerically-stable softmax over `count` values starting at `offset`. */
function softmax(values: Float32Array, offset: number, count: number): number[] {
  const out: number[] = new Array<number>(count);
  let max: number = values[offset];
  for (let i = 1; i < count; i++) {
    if (values[offset + i] > max) {
      max = values[offset + i];
    }
  }
  let sum: number = 0;
  for (let i = 0; i < count; i++) {
    const e: number = Math.exp(values[offset + i] - max);
    out[i] = e;
    sum += e;
  }
  for (let i = 0; i < count; i++) {
    out[i] = out[i] / sum;
  }
  return out;
}

/** Best-effort error description (ArkTS error objects stringify to `{}`). */
function describe(error: Error): string {
  if (error === undefined || error === null) {
    return 'unknown error';
  }
  const message: string = error.message !== undefined ? error.message : String(error);
  const stack: string = error.stack !== undefined ? error.stack : '';
  return `${message} | ${stack}`;
}
