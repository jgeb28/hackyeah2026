/**
 * Message contract between the UI thread and `LayaWorker`.
 *
 * The model load and inference run in the worker so the UI thread never blocks
 * (a 1.7 GB `loadModelFromFile` on the main thread trips the OS
 * THREAD_BLOCK_6S watchdog and kills the app).
 */
export interface WorkerRequest {
  /** 'init' = load tokenizer/meta/model; 'infer' = run one prediction. */
  type: string;
  id: number;
  modelPath?: string;
  metaJson?: string;
  tokenizerJson?: string;
  state?: string;
}

export interface WorkerResponse {
  /** 'ready' | 'result' | 'error'. */
  type: string;
  id: number;
  message?: string;
  /** Raw fp32 logits `[Q, MAX_OPTIONS]` (transferred). */
  logits?: ArrayBuffer;
  latencyMs?: number;
}
