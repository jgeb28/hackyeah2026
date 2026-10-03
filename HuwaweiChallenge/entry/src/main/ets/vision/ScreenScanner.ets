// One-shot screen scan: capture -> PP-OCRv4 -> classify. No canned fallback:
// if capture or OCR fails we surface the real error instead of faking text.
import { screenshot } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { OcrEngine, ScreenOcrEngine } from './OcrEngine';
import { ScreenClassifier } from './ScreenClassifier';
import { ScanResult } from '../trigger/TriggerTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianScanner';
const CAPTURE: Permissions = 'ohos.permission.CUSTOM_SCREEN_CAPTURE';

export interface ScanOutcome {
  text: string;
  result: ScanResult | null;
  /** Human-readable failure reason, or '' on success. */
  error: string;
}

export class ScreenScanner {
  private ocr: OcrEngine = new ScreenOcrEngine();

  /** Capture the screen once, read the real text, and classify it. */
  async scanOnce(): Promise<ScanOutcome> {
    let frame: image.PixelMap | undefined = undefined;
    let text: string = '';
    let error: string = '';
    try {
      await this.ensurePermission();
      frame = await screenshot.capture();
      text = await this.ocr.recognize(frame);
    } catch (err) {
      error = ScreenScanner.describe(err);
      hilog.warn(DOMAIN, TAG, 'scan failed: %{public}s', JSON.stringify(err));
    } finally {
      if (frame !== undefined) {
        frame.release().catch((e: Error) => {
          hilog.warn(DOMAIN, TAG, 'release failed: %{public}s', e.message);
        });
      }
    }

    const result: ScanResult | null = text.length > 0 ? ScreenClassifier.strongest(text) : null;
    hilog.info(DOMAIN, TAG, 'scan text=%{public}d error=%{public}s', text.length, error);
    return { text, result, error };
  }

  /** `CUSTOM_SCREEN_CAPTURE` is a normal, user-granted permission: ask for it first. */
  private async ensurePermission(): Promise<void> {
    try {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(ctx, [CAPTURE]);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'permission request failed: %{public}s', JSON.stringify(err));
    }
  }

  private static describe(err: Object): string {
    const code: number | undefined = (err as BusinessError).code;
    if (code === 201) {
      return 'Screen-capture permission was denied. Enable it in Settings.';
    }
    if (code === 801) {
      return 'This device/image cannot capture the screen (no screenshot service).';
    }
    if (code === 1400003) {
      return 'The display service is unavailable right now.';
    }
    return `Screen capture failed (code ${code ?? '?'}).`;
  }
}
