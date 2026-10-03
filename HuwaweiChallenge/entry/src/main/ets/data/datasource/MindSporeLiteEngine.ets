import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GuardianSchema, SchemaQuestion } from '../../domain/model/GuardianSchema';
import { LayaAnswer, LayaRequest, LayaResponse, QuestionType } from '../../domain/model/Decision';
import { AssetLoader } from '../assets/AssetLoader';
import { InferenceConfig } from '../config/InferenceConfig';
import { BpeTokenizer } from './BpeTokenizer';

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
 * Graph contract (produced by `~/tmp/convert_laya.py`; see LAYA_INTEGRATION.md):
 *   input  "input_ids"      int32 [Q, max_len]   one Laya sequence per question
 *   input  "attention_mask" int32 [Q, max_len]   1 = real token, 0 = pad
 *   output "logits"         fp32  [1, Q, MAX_OPTIONS]  (temperature-scaled)
 *
 * The app builds each sequence exactly like Laya's `build_sequence`:
 *   prefix + state_tokens + [SEP] + pad     (prefixes come from meta.json)
 *
 * Acceleration: `target = ['nnrt','cpu']` asks for the NNRt backend (Kirin NPU)
 * and transparently falls back to CPU on the emulator.
 */
export class MindSporeLiteEngine {
  private readonly config: InferenceConfig;
  private readonly assets: AssetLoader;
  private readonly tokenizer: BpeTokenizer;
  private model: mindSporeLite.Model | null = null;

  // From meta.json
  private prefixes: number[][] = [];
  private sepId: number = 50282;
  private padId: number = 50283;
  private maxLen: number = 512;

  constructor(config: InferenceConfig, assets: AssetLoader) {
    this.config = config;
    this.assets = assets;
    this.tokenizer = new BpeTokenizer();
  }

  /** Load the tokenizer, meta and graph once; safe to call repeatedly. */
  async ensureReady(): Promise<void> {
    if (this.model !== null) {
      return;
    }

    if (!this.tokenizer.isReady()) {
      await this.tokenizer.load(this.assets, this.config.tokenizerPath);
    }

    const metaText: string = await this.assets.readText(this.config.metaPath);
    const meta: LayaMetaDto = JSON.parse(metaText) as LayaMetaDto;
    this.prefixes = meta.prefixes !== undefined ? meta.prefixes : [];
    this.sepId = meta.sep_id !== undefined ? meta.sep_id : this.sepId;
    this.padId = meta.pad_id !== undefined ? meta.pad_id : this.padId;
    this.maxLen = meta.max_len !== undefined ? meta.max_len : this.config.maxSeqLen;
    if (this.prefixes.length === 0) {
      throw new ModelNotInstalledError('laya_guardian_meta.json has no prefixes');
    }

    let fd: number;
    try {
      fd = this.assets.openFd(this.config.msModelPath);
    } catch (error) {
      throw new ModelNotInstalledError(`Missing on-device model: ${this.config.msModelPath}`);
    }

    this.model = await mindSporeLite.loadModelFromFd(fd, this.buildContext());
    hilog.info(DOMAIN, TAG, 'Loaded %{public}s (%{public}s, maxLen=%{public}d)',
      this.config.msModelPath, this.config.quantization.dtype, this.maxLen);
  }

  async infer(request: LayaRequest): Promise<LayaResponse> {
    await this.ensureReady();
    const model: mindSporeLite.Model = this.model as mindSporeLite.Model;
    const inputs: mindSporeLite.MSTensor[] = model.getInputs();

    const state: number[] = this.tokenizer.encode(request.state);
    const q: number = this.prefixes.length;
    const s: number = this.maxLen;
    const ids: Int32Array = new Int32Array(q * s);
    const mask: Int32Array = new Int32Array(q * s);

    for (let qi = 0; qi < q; qi++) {
      const prefix: number[] = this.prefixes[qi];
      const room: number = s - prefix.length - 1;
      const base: number = qi * s;
      let pos: number = 0;
      for (let i = 0; i < prefix.length; i++) {
        ids[base + pos] = prefix[i];
        mask[base + pos] = 1;
        pos++;
      }
      const n: number = state.length < room ? state.length : room;
      for (let i = 0; i < n; i++) {
        ids[base + pos] = state[i];
        mask[base + pos] = 1;
        pos++;
      }
      ids[base + pos] = this.sepId;
      mask[base + pos] = 1;
      pos++;
      for (; pos < s; pos++) {
        ids[base + pos] = this.padId;
        mask[base + pos] = 0;
      }
    }

    inputs[0].setData(ids.buffer);
    if (inputs.length > 1) {
      inputs[1].setData(mask.buffer);
    }

    const started: number = Date.now();
    const outputs: mindSporeLite.MSTensor[] = await model.predict(inputs);
    const latency: number = Date.now() - started;

    const logits: Float32Array = new Float32Array(outputs[0].getData());
    return this.decode(logits, latency);
  }

  /**
   * MindSpore Lite execution context: prefer NNRt (NPU), fall back to CPU.
   *
   * The shipped fp32 `.ms` was validated with fp32 CPU math, so we use
   * `enforce_fp32` here to reproduce those exact results on the emulator.
   */
  buildContext(): mindSporeLite.Context {
    const context: mindSporeLite.Context = {};
    if (this.config.useNpu) {
      context.target = ['nnrt', 'cpu'];
      const nnrt: mindSporeLite.NNRTDevice = {};
      context.nnrt = nnrt;
    } else {
      context.target = ['cpu'];
    }

    const cpu: mindSporeLite.CpuDevice = {};
    cpu.threadNum = this.config.cpuThreads;
    cpu.precisionMode = 'enforce_fp32';
    context.cpu = cpu;
    return context;
  }

  private decode(logits: Float32Array, latencyMs: number): LayaResponse {
    const response = new LayaResponse();
    response.model = `laya-${this.config.quantization.dtype}`;
    response.latencyMs = latencyMs;

    const questions: SchemaQuestion[] = GuardianSchema.QUESTIONS;
    const width: number = GuardianSchema.MAX_OPTIONS;
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
