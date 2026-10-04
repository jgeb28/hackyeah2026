// OCR seam for the on-screen scanner. Runs the on-device PP-OCRv4 engine
// (ets/ocr/) so the screenshot path recognises text with the same model as OcrDemo.
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { extractTextFromImage } from '../ocr/OcrEngine';
import { OcrResult, RectPx } from '../ocr/OcrTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianOcr';

export interface OcrEngine {
  recognize(pixelMap: image.PixelMap, excludedRects?: RectPx[]): Promise<string>;
}

export class ScreenOcrEngine implements OcrEngine {
  async recognize(pixelMap: image.PixelMap, excludedRects: RectPx[] = []): Promise<string> {
    try {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      const result: OcrResult = await extractTextFromImage(pixelMap, ctx.resourceManager, excludedRects);
      return result.text;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'ppocr failed: %{public}s', JSON.stringify(err));
      return '';
    }
  }
}
