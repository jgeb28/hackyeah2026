// One-shot screen scan: capture -> OCR -> classify. The image is released immediately.
import { screenshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { OcrEngine, CoreVisionOcrEngine } from './OcrEngine';
import { ScreenClassifier } from './ScreenClassifier';
import { ScanResult } from '../trigger/TriggerTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianScanner';

/** Safe sample messages for the demo when on-device OCR is unavailable (emulator). */
const SAFE_SAMPLES: string[] = [
  'Lunch at 12:30 today? No worries if not.',
  'See you at the gym at 7. Bring water.',
  'Happy birthday! Have a great day.'
];
/** Scam sample messages for the demo when on-device OCR is unavailable (emulator). */
const SCAM_SAMPLES: string[] = [
  "Hi sweetie, it's me, I had an accident and my phone broke. Don't call now - send 4,800 urgently before 6pm, or I could lose my license.",
  'Your parcel is on hold. A small customs fee of 2.99 PLN is required, pay within 12 hours at this link or it will be returned to sender.',
  'Congratulations, you have won a 5,000 PLN gift card. To claim your prize, confirm your card details and the SMS code within 10 minutes.'
];

function pick(list: string[]): string {
  const index: number = Math.floor(Math.random() * list.length);
  return list[index];
}

export interface ScanOutcome {
  text: string;
  result: ScanResult | null;
  /** 'scam' | 'safe' when a built-in sample was used (OCR returned nothing), otherwise ''. */
  sample: string;
}

export class ScreenScanner {
  private ocr: OcrEngine = new CoreVisionOcrEngine();

  /** Capture the screen once, read the text, and classify it. */
  async scanOnce(): Promise<ScanOutcome> {
    let frame: image.PixelMap | undefined = undefined;
    let text: string = '';
    try {
      frame = await screenshot.capture();
      text = await this.ocr.recognize(frame);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'scan failed: %{public}s', JSON.stringify(err));
    } finally {
      if (frame !== undefined) {
        frame.release().catch((e: Error) => {
          hilog.warn(DOMAIN, TAG, 'release failed: %{public}s', e.message);
        });
      }
    }

    let sample: string = '';
    if (text.length === 0) {
      // OCR is unavailable (emulator): pick a random sample so the demo varies.
      const scam: boolean = Math.random() < 0.5;
      text = pick(scam ? SCAM_SAMPLES : SAFE_SAMPLES);
      sample = scam ? 'scam' : 'safe';
    }
    const result: ScanResult | null = ScreenClassifier.strongest(text);
    hilog.info(DOMAIN, TAG, 'scan text=%{public}d sample=%{public}s', text.length, sample);
    return { text, result, sample };
  }
}
