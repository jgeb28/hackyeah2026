// OcrEngine — PP-OCRv4 text detection + recognition on MindSpore Lite.
//
// The single entry point is `extractTextFromImage(pixelMap, resourceManager)`:
// it runs the detection model to find text quads, crops each one, runs the
// recognition model, CTC-decodes it, and returns the lines in reading order.
//
// Models live in resources/rawfile/ocr/{det.ms, rec.ms, ppocr_keys_v1.txt} and
// are loaded once and cached. Detection input is NHWC float32 [1,960,960,3];
// recognition input is NHWC float32 [1,48,960,3].
import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { util } from '@kit.ArkTS';
import { OcrBox, OcrResult, OcrLine } from './OcrTypes';
import { findDetBoxes, sortBoxes } from './DbPostprocess';
import { affineCrop, detPreprocess, recPreprocess, DET_SIZE, rgbaToBgr } from './ImageOps';
import { ctcDecode, loadChars } from './CtcDecode';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianOcr';

const DET_MODEL: string = 'ocr/det.ms';
const REC_MODEL: string = 'ocr/rec.ms';
const DICT_FILE: string = 'ocr/ppocr_keys_v1.txt';

export class OcrEngine {
  private static instance: OcrEngine | null = null;

  private det: mindSporeLite.Model | null = null;
  private rec: mindSporeLite.Model | null = null;
  private chars: string[] = [];
  private loading: Promise<void> | null = null;

  static get(): OcrEngine {
    if (OcrEngine.instance === null) {
      OcrEngine.instance = new OcrEngine();
    }
    return OcrEngine.instance;
  }

  /** Load both models and the dictionary once (idempotent). */
  async ensureLoaded(mgr: resourceManager.ResourceManager): Promise<void> {
    if (this.det !== null && this.rec !== null) {
      return;
    }
    if (this.loading !== null) {
      return this.loading;
    }
    this.loading = this.load(mgr);
    try {
      await this.loading;
    } finally {
      this.loading = null;
    }
  }

  private async load(mgr: resourceManager.ResourceManager): Promise<void> {
    const ctx: mindSporeLite.Context = {
      target: ['cpu'],
      cpu: { threadNum: 4, precisionMode: 'preferred_fp32' }
    };
    const detBuf = await this.rawBuffer(mgr, DET_MODEL);
    const recBuf = await this.rawBuffer(mgr, REC_MODEL);
    const dict = await mgr.getRawFileContent(DICT_FILE);
    this.chars = loadChars(util.TextDecoder.create('utf-8').decodeToString(dict));

    const t0 = Date.now();
    this.det = await mindSporeLite.loadModelFromBuffer(detBuf, ctx);
    this.rec = await mindSporeLite.loadModelFromBuffer(recBuf, ctx);
    hilog.info(DOMAIN, TAG, `models loaded in ${Date.now() - t0} ms, classes=${this.chars.length}`);
  }

  private async rawBuffer(mgr: resourceManager.ResourceManager, path: string): Promise<ArrayBuffer> {
    const bytes: Uint8Array = await mgr.getRawFileContent(path);
    return bytes.buffer.slice(bytes.byteOffset, bytes.byteOffset + bytes.byteLength);
  }

  /** The complete function: extract every text line from a bitmap. */
  async extract(pixelMap: image.PixelMap): Promise<OcrResult> {
    if (this.det === null || this.rec === null) {
      throw new Error('OcrEngine not loaded; call ensureLoaded first');
    }
    const info = await pixelMap.getImageInfo();
    const w: number = info.size.width;
    const h: number = info.size.height;
    const rgbaBuf = new ArrayBuffer(w * h * 4);
    await pixelMap.readPixelsToBuffer(rgbaBuf);
    const bgr = rgbaToBgr(new Uint8Array(rgbaBuf), w, h);

    // --- detection ---
    const detIn = detPreprocess(bgr, w, h);
    const detInputs = this.det.getInputs();
    detInputs[0].setData(detIn.data.buffer);
    const tDet = Date.now();
    const detOut = await this.det.predict(detInputs);
    const prob = new Float32Array(detOut[0].getData());
    const boxes: OcrBox[] = sortBoxes(findDetBoxes(prob, DET_SIZE, DET_SIZE, detIn.scale));
    hilog.info(DOMAIN, TAG, `detect ${boxes.length} boxes in ${Date.now() - tDet} ms`);

    // --- recognition ---
    const lines: OcrLine[] = [];
    const tRec = Date.now();
    for (const box of boxes) {
      const crop = affineCrop(bgr, w, h, box.points);
      if (crop.width < 2 || crop.height < 2) {
        continue;
      }
      const recIn = recPreprocess(crop);
      const recInputs = this.rec.getInputs();
      recInputs[0].setData(recIn.buffer);
      const recOut = await this.rec.predict(recInputs);
      const shape: number[] = recOut[0].shape;
      const t: number = shape.length === 3 ? shape[1] : shape[0];
      const c: number = shape.length === 3 ? shape[2] : shape[1];
      const decoded = ctcDecode(new Float32Array(recOut[0].getData()), t, c, this.chars);
      if (decoded.text.trim().length > 0) {
        lines.push({ text: decoded.text, confidence: decoded.confidence, box });
      }
    }
    hilog.info(DOMAIN, TAG, `recognized ${lines.length} lines in ${Date.now() - tRec} ms`);

    const texts: string[] = [];
    for (const line of lines) {
      texts.push(line.text);
    }
    return { text: texts.join('\n'), lines };
  }
}

/** Convenience wrapper around the shared engine. */
export async function extractTextFromImage(
  pixelMap: image.PixelMap,
  mgr: resourceManager.ResourceManager
): Promise<OcrResult> {
  const engine = OcrEngine.get();
  await engine.ensureLoaded(mgr);
  return engine.extract(pixelMap);
}
