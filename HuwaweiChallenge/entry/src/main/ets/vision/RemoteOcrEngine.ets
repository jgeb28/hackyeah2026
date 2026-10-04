import { image } from '@kit.ImageKit';
import { OcrEngine } from './OcrEngine';
import { RectPx } from '../ocr/OcrTypes';
import { BackendSettings } from '../dev/BackendSettings';
import { RemoteClient } from '../dev/RemoteClient';

interface OcrResponse {
  text?: string;
}

/** Dev-only OCR adapter: POSTs the captured frame to the host dev server. */
export class RemoteOcrEngine implements OcrEngine {
  // `excludedRects` is applied by the on-device engine; the dev remote path sends
  // the frame as-is (kept for interface parity).
  async recognize(pixelMap: image.PixelMap, excludedRects?: RectPx[]): Promise<string> {
    const packer: image.ImagePacker = image.createImagePacker();
    let jpeg: ArrayBuffer;
    try {
      const options: image.PackingOption = { format: 'image/jpeg', quality: 80 };
      jpeg = await packer.packing(pixelMap, options);
    } finally {
      packer.release();
    }
    const body: string = await RemoteClient.post(`${BackendSettings.baseUrl}/ocr`, jpeg, 'image/jpeg');
    const parsed: OcrResponse = JSON.parse(body) as OcrResponse;
    return parsed.text !== undefined ? parsed.text : '';
  }
}
