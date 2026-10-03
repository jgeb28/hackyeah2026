// OCR seam: Core Vision Kit text recognition (RGBA_8888); returns '' on failure.
import { image } from '@kit.ImageKit';
import { textRecognition } from '@kit.CoreVisionKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianOcr';

export interface OcrEngine {
  recognize(pixelMap: image.PixelMap): Promise<string>;
}

async function toRgba(pixelMap: image.PixelMap): Promise<image.PixelMap> {
  const info: image.ImageInfo = await pixelMap.getImageInfo();
  if (info.pixelFormat === image.PixelMapFormat.RGBA_8888) {
    return pixelMap;
  }
  const buffer: ArrayBuffer = new ArrayBuffer(pixelMap.getPixelBytesNumber());
  await pixelMap.readPixelsToBuffer(buffer);
  const options: image.InitializationOptions = {
    size: { width: info.size.width, height: info.size.height },
    srcPixelFormat: info.pixelFormat,
    pixelFormat: image.PixelMapFormat.RGBA_8888
  };
  return await image.createPixelMap(buffer, options);
}

export class CoreVisionOcrEngine implements OcrEngine {
  private ready: boolean = false;

  async recognize(pixelMap: image.PixelMap): Promise<string> {
    try {
      if (!this.ready) {
        this.ready = await textRecognition.init();
      }
      const rgba: image.PixelMap = await toRgba(pixelMap);
      try {
        const result: textRecognition.TextRecognitionResult =
          await textRecognition.recognizeText({ pixelMap: rgba });
        return result.value ?? '';
      } finally {
        // Don't keep the converted frame.
        if (rgba !== pixelMap) {
          await rgba.release();
        }
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'ocr failed code=%{public}d msg=%{public}s', (err as BusinessError).code,
        (err as BusinessError).message);
      return '';
    }
  }
}
