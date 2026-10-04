// One-shot screen scan: capture -> PP-OCRv4 -> classify. No canned fallback:
// if capture or OCR fails we surface the real error instead of faking text.
import { screenshot, window } from '@kit.ArkUI';
import { image } from '@kit.ImageKit';
import { common, abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { createOcrEngine } from '../dev/BackendFactory';
import { IslandOverlay } from '../alert/IslandOverlay';
import { RectPx } from '../ocr/OcrTypes';
import { LayaClassifier } from './LayaClassifier';
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
  private laya: LayaClassifier = new LayaClassifier();

  /** Capture the screen once, read the real text, and classify it. */
  async scanOnce(): Promise<ScanOutcome> {
    let frame: image.PixelMap | undefined = undefined;
    let text: string = '';
    let error: string = '';
    try {
      await this.ensurePermission();
      frame = await screenshot.capture();
      const rects: RectPx[] = await ScreenScanner.chromeRects(frame);
      hilog.info(DOMAIN, TAG, 'chrome rects: %{public}d', rects.length);
      text = await createOcrEngine().recognize(frame, rects);
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

    let result: ScanResult | null = null;
    if (text.length > 0) {
      try {
        result = await this.laya.classify(text);
      } catch (err) {
        error = 'The screen text was read, but the on-device model is unavailable.';
        hilog.error(DOMAIN, TAG, 'laya classify failed: %{public}s', JSON.stringify(err));
      }
    }
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

  /** Deterministic chrome regions to drop: status bar, nav bar, and our own island window. */
  private static async chromeRects(frame: image.PixelMap): Promise<RectPx[]> {
    const rects: RectPx[] = [];
    const info: image.ImageInfo = await frame.getImageInfo();
    const W: number = info.size.width;
    const H: number = info.size.height;
    try {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      const win: window.Window = await window.getLastWindow(ctx);
      const avoid: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      if (avoid.topRect.height > 0) {
        rects.push({ left: 0, top: 0, width: W, height: avoid.topRect.height });
      }
      if (avoid.bottomRect.height > 0) {
        rects.push({ left: 0, top: H - avoid.bottomRect.height, width: W, height: avoid.bottomRect.height });
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'avoid-area query failed: %{public}s', JSON.stringify(err));
    }
    const isl: window.Rect | null = IslandOverlay.rectPx();
    if (isl !== null) {
      rects.push({ left: isl.left, top: isl.top, width: isl.width, height: isl.height });
    }
    return rects;
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
