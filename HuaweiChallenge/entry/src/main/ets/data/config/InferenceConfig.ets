/**
 * Data-layer configuration for on-device, offline Laya inference.
 *
 * Security posture: Guardian runs the model **entirely on the device** by default.
 * The optional network paths (the dev "Remote GPU" backend and the user-key DeepSeek
 * "Describe" action) live in `dev/` and are documented in AI_INTEGRATION.md; this
 * config only describes the local MindSpore Lite artefacts and the accelerator.
 */

/**
 * Weight configuration for the on-device model.
 *
 * Quantisation is a build-time step with the MindSpore Lite converter (see
 * AI_INTEGRATION.md). This records which artefact the app must load.
 *
 *   dtype   | ~size (421M params) | use
 *   --------|---------------------|------------------------------------------
 *   fp16    | ~840 MB             | best accuracy; too big for the emulator
 *   q8      | ~420 MB             | good default for a phone
 *   q4      | ~210 MB             | smallest; best for CPU / emulator
 */
export interface ModelQuantization {
  /** One of 'fp16' | 'q8' | 'q4'. */
  dtype: string;
}

export class InferenceConfig {
  // --- On-device artefacts (entry/src/main/resources/rawfile/) --------------
  /** Converted MindSpore Lite graph bundled in rawfile (optional). */
  msModelPath: string = 'laya_en_w8_s256.ms';
  /** Model file name (same file) in the app sandbox `filesDir` — used for large models. */
  msFileName: string = 'laya_en_w8_s256.ms';
  /** Converter metadata: question prefixes, SEP/PAD ids, max_len. */
  metaPath: string = 'laya_guardian_meta.json';
  /** Hugging Face fast-tokenizer definition (ByteLevel BPE), copied verbatim. */
  tokenizerPath: string = 'tokenizer.json';

  quantization: ModelQuantization = { dtype: 'w8' };

  // --- Execution ------------------------------------------------------------
  /** Request the NNRt backend (Kirin NPU); MindSpore Lite falls back to CPU. */
  useNpu: boolean = true;
  cpuThreads: number = 4;
  /** CPU half-precision eager mode. */
  preferFp16: boolean = true;

  /** Fallback sequence length if meta.json is unavailable. */
  maxSeqLen: number = 512;
}
