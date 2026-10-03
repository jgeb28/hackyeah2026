import { worker, MessageEvents, ThreadWorkerGlobalScope } from '@kit.ArkTS';
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BpeTokenizer } from '../data/datasource/BpeTokenizer';
import { WorkerRequest, WorkerResponse } from '../data/datasource/WorkerProtocol';

const DOMAIN: number = 0x0000;
const TAG: string = 'LayaWorker';
const port: ThreadWorkerGlobalScope = worker.workerPort;

interface MetaDto {
  prefixes?: number[][];
  sep_id?: number;
  pad_id?: number;
  max_len?: number;
}

let tokenizer: BpeTokenizer = new BpeTokenizer();
let model: mindSporeLite.Model | null = null;
let prefixes: number[][] = [];
let sepId: number = 50282;
let padId: number = 50283;
let maxLen: number = 512;

/** CPU-only context (the emulator has no NNRt/NPU device). */
function buildContext(): mindSporeLite.Context {
  const context: mindSporeLite.Context = {};
  context.target = ['cpu'];
  const cpu: mindSporeLite.CpuDevice = {};
  cpu.threadNum = 4;
  cpu.precisionMode = 'enforce_fp32';
  context.cpu = cpu;
  return context;
}

async function onInit(req: WorkerRequest): Promise<void> {
  tokenizer.loadFromJson(req.tokenizerJson as string);
  const meta: MetaDto = JSON.parse(req.metaJson as string) as MetaDto;
  prefixes = meta.prefixes !== undefined ? meta.prefixes : [];
  sepId = meta.sep_id !== undefined ? meta.sep_id : sepId;
  padId = meta.pad_id !== undefined ? meta.pad_id : padId;
  maxLen = meta.max_len !== undefined ? meta.max_len : maxLen;

  hilog.info(DOMAIN, TAG, 'loading model from %{public}s', req.modelPath as string);
  model = await mindSporeLite.loadModelFromFile(req.modelPath as string, buildContext());
  hilog.info(DOMAIN, TAG, 'model loaded (prefixes=%{public}d maxLen=%{public}d)', prefixes.length, maxLen);
  const res: WorkerResponse = { type: 'ready', id: req.id };
  port.postMessage(res);
}

async function onInfer(req: WorkerRequest): Promise<void> {
  const current: mindSporeLite.Model | null = model;
  if (current === null) {
    const res: WorkerResponse = { type: 'error', id: req.id, message: 'model not loaded' };
    port.postMessage(res);
    return;
  }

  const state: number[] = tokenizer.encode(req.state as string);
  const q: number = prefixes.length;
  const s: number = maxLen;
  const ids: Int32Array = new Int32Array(q * s);
  const mask: Int32Array = new Int32Array(q * s);

  for (let qi = 0; qi < q; qi++) {
    const prefix: number[] = prefixes[qi];
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
    ids[base + pos] = sepId;
    mask[base + pos] = 1;
    pos++;
    for (; pos < s; pos++) {
      ids[base + pos] = padId;
      mask[base + pos] = 0;
    }
  }

  const inputs: mindSporeLite.MSTensor[] = current.getInputs();
  inputs[0].setData(ids.buffer);
  if (inputs.length > 1) {
    inputs[1].setData(mask.buffer);
  }

  const started: number = Date.now();
  const outputs: mindSporeLite.MSTensor[] = await current.predict(inputs);
  const latency: number = Date.now() - started;

  const raw: Float32Array = new Float32Array(outputs[0].getData());
  const logits: Float32Array = new Float32Array(raw.length);
  logits.set(raw);
  const logitsBuffer: ArrayBuffer = logits.buffer as ArrayBuffer;
  hilog.info(DOMAIN, TAG, 'infer ok: tokens=%{public}d latency=%{public}d', state.length, latency);
  const res: WorkerResponse = { type: 'result', id: req.id, logits: logitsBuffer, latencyMs: latency };
  port.postMessage(res, [logitsBuffer]);
}

port.onmessage = (e: MessageEvents): void => {
  const req: WorkerRequest = e.data as WorkerRequest;
  if (req.type === 'init') {
    onInit(req).catch((error: Error): void => {
      const res: WorkerResponse = {
        type: 'error', id: req.id,
        message: error.message !== undefined ? error.message : String(error)
      };
      port.postMessage(res);
    });
  } else if (req.type === 'infer') {
    onInfer(req).catch((error: Error): void => {
      const res: WorkerResponse = {
        type: 'error', id: req.id,
        message: error.message !== undefined ? error.message : String(error)
      };
      port.postMessage(res);
    });
  }
};
