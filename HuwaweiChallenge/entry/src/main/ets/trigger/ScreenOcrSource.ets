// ScreenOcrSource — Phase 2 ingestion: capture an image, OCR it, feed the engine.
// The capture function is injected so this source is device-agnostic (the still
// path uses @ohos.screenshot / AVScreenCapture on device; tests inject a stub).
import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { IngestSource, ScanJob } from './IngestSource';
import { extractTextFromImage } from '../ocr/OcrEngine';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianOcrSource';

export type ScreenCapture = () => Promise<image.PixelMap>;

export class ScreenOcrSource implements IngestSource {
  name: string = 'ocr';
  private emit: ((job: ScanJob) => void) | null = null;
  private readonly capture: ScreenCapture;
  private readonly resMgr: resourceManager.ResourceManager;

  constructor(capture: ScreenCapture, resMgr: resourceManager.ResourceManager) {
    this.capture = capture;
    this.resMgr = resMgr;
  }

  enabled(): boolean {
    return true;
  }

  start(emit: (job: ScanJob) => void): void {
    this.emit = emit;
  }

  stop(): void {
    this.emit = null;
  }

  /** Capture, OCR, and emit one job. Returns the raw text (for callers/tests). */
  async scanOnce(bundleName: string): Promise<string> {
    const shot: image.PixelMap = await this.capture();
    const result = await extractTextFromImage(shot, this.resMgr);
    if (this.emit !== null && result.text.trim().length > 0) {
      this.emit({
        bundleName,
        text: result.text,
        timestampMs: Date.now()
      });
    }
    hilog.info(DOMAIN, TAG, `ocr scan -> ${result.lines.length} lines`);
    return result.text;
  }
}
