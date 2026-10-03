import { worker, MessageEvents, ErrorEvent } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WorkerRequest, WorkerResponse } from './WorkerProtocol';

const DOMAIN: number = 0x0000;
const TAG: string = 'LayaClient';

export class InferenceResult {
  logits: Float32Array = new Float32Array(0);
  latencyMs: number = 0;
}

/**
 * UI-thread handle for `LayaWorker`.
 *
 * All MindSpore Lite work (the 1.7 GB model load and `predict`) happens on the
 * worker thread; this class only shuttles messages and hands back logits, so the
 * UI thread always stays responsive.
 */
export class LayaEngineClient {
  private readonly workerUrl: string = 'entry/ets/workers/LayaWorker.ets';
  private readonly modelPath: string;
  private readonly metaJson: string;
  private readonly tokenizerJson: string;

  private w: worker.ThreadWorker | null = null;
  private initPromise: Promise<void> | null = null;
  private initResolve: (() => void) | null = null;
  private initReject: ((error: Error) => void) | null = null;
  private inferResolve: ((result: InferenceResult) => void) | null = null;
  private inferReject: ((error: Error) => void) | null = null;
  private nextId: number = 1;

  constructor(modelPath: string, metaJson: string, tokenizerJson: string) {
    this.modelPath = modelPath;
    this.metaJson = metaJson;
    this.tokenizerJson = tokenizerJson;
  }

  /** Create the worker and load the model there; resolves when ready. */
  start(): Promise<void> {
    if (this.initPromise !== null) {
      return this.initPromise;
    }
    this.initPromise = new Promise<void>((resolve, reject) => {
      this.initResolve = (): void => {
        resolve();
      };
      this.initReject = (error: Error): void => {
        reject(error);
      };
    });

    const w: worker.ThreadWorker = new worker.ThreadWorker(this.workerUrl);
    w.onmessage = (e: MessageEvents): void => {
      this.handle(e);
    };
    w.onerror = (e: ErrorEvent): void => {
      hilog.error(DOMAIN, TAG, 'worker error: %{public}s', e.message);
      this.fail(new Error(`worker error: ${e.message}`));
    };
    this.w = w;

    const req: WorkerRequest = {
      type: 'init',
      id: this.nextId++,
      modelPath: this.modelPath,
      metaJson: this.metaJson,
      tokenizerJson: this.tokenizerJson
    };
    w.postMessage(req);
    return this.initPromise;
  }

  /** Run one prediction in the worker; resolves with the raw logits. */
  inferLogits(state: string): Promise<InferenceResult> {
    return new Promise<InferenceResult>((resolve, reject) => {
      if (this.w === null) {
        reject(new Error('worker not started'));
        return;
      }
      this.inferResolve = (result: InferenceResult): void => {
        resolve(result);
      };
      this.inferReject = (error: Error): void => {
        reject(error);
      };
      const req: WorkerRequest = { type: 'infer', id: this.nextId++, state: state };
      this.w.postMessage(req);
    });
  }

  private handle(e: MessageEvents): void {
    const res: WorkerResponse = e.data as WorkerResponse;
    if (res.type === 'ready') {
      const resolve: (() => void) | null = this.initResolve;
      this.initResolve = null;
      this.initReject = null;
      if (resolve !== null) {
        resolve();
      }
      return;
    }
    if (res.type === 'error') {
      this.fail(new Error(res.message !== undefined ? res.message : 'worker error'));
      return;
    }
    if (res.type === 'result') {
      const out = new InferenceResult();
      out.logits = res.logits !== undefined ? new Float32Array(res.logits) : new Float32Array(0);
      out.latencyMs = res.latencyMs !== undefined ? res.latencyMs : 0;
      const resolve: ((result: InferenceResult) => void) | null = this.inferResolve;
      this.inferResolve = null;
      this.inferReject = null;
      if (resolve !== null) {
        resolve(out);
      }
    }
  }

  /** Reject whichever operation is pending and clear the slots. */
  private fail(error: Error): void {
    const rejectInit: ((error: Error) => void) | null = this.initReject;
    this.initResolve = null;
    this.initReject = null;
    if (rejectInit !== null) {
      rejectInit(error);
      return;
    }
    const rejectInfer: ((error: Error) => void) | null = this.inferReject;
    this.inferResolve = null;
    this.inferReject = null;
    if (rejectInfer !== null) {
      rejectInfer(error);
    }
  }
}
