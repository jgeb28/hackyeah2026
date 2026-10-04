// One-shot screen scan: capture -> PP-OCRv4 -> classify. No canned fallback:
// if capture or OCR fails we surface the real error instead of faking text.
import { screenshot, window, display } from '@kit.ArkUI';
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

/** A user-selected area, in vp, relative to the display origin. */
export interface ScanRegion {
  x: number;
  y: number;
  width: number;
  height: number;
}

export class ScreenScanner {
  private laya: LayaClassifier = new LayaClassifier();

  /**
   * Capture the screen once, read the real text, and classify it.
   * When `region` is given, the capture is cropped to that area first.
   */
  async scanOnce(region?: ScanRegion): Promise<ScanOutcome> {
    let frame: image.PixelMap | undefined = undefined;
    let text: string = '';
    let error: string = '';
    try {
      await this.ensurePermission();
      hilog.info(DOMAIN, TAG, 'scan start: region=%{public}s',
        region !== undefined
          ? `${Math.round(region.x)},${Math.round(region.y)} ${Math.round(region.width)}x${Math.round(region.height)}`
          : 'full');
      // Hide our own island so it is not part of the capture.
      await IslandOverlay.hide();
      await ScreenScanner.delay(200);
      try {
        frame = await ScreenScanner.captureWithRetry();
      } finally {
        await IslandOverlay.reveal();
      }
      if (region !== undefined) {
        await ScreenScanner.cropToRegion(frame, region);
      }
      const rects: RectPx[] = region !== undefined ? [] : await ScreenScanner.chromeRects(frame);
      hilog.info(DOMAIN, TAG, 'chrome rects: %{public}d', rects.length);
      text = await createOcrEngine().recognize(frame, rects);
    } catch (err) {
      error = ScreenScanner.describe(err);
      const reason: string = (err as Error).message !== undefined ? (err as Error).message : '';
      hilog.warn(DOMAIN, TAG, 'scan failed: %{public}s (raw=%{public}s)', error, reason);
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
        const reason: string = (err as Error).message !== undefined ? (err as Error).message : '';
        error = reason.length > 0
          ? `The screen text was read, but the on-device model could not run (${reason}).`
          : 'The screen text was read, but the on-device model is unavailable.';
        hilog.error(DOMAIN, TAG, 'laya classify failed: %{public}s', reason);
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

  /** Capture, retrying once shortly after a transient display-service failure. */
  private static async captureWithRetry(): Promise<image.PixelMap> {
    try {
      return await screenshot.capture();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'capture failed, retrying: %{public}s', JSON.stringify(err));
      await ScreenScanner.delay(350);
      return await screenshot.capture();
    }
  }

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  /** Crop the capture to the user's area (vp -> px, clamped to the image). */
  private static async cropToRegion(frame: image.PixelMap, region: ScanRegion): Promise<void> {
    const d: display.Display = display.getDefaultDisplaySync();
    const s: number = d.densityPixels;
    const info: image.ImageInfo = await frame.getImageInfo();
    const x: number = Math.max(0, Math.round(region.x * s));
    const y: number = Math.max(0, Math.round(region.y * s));
    let w: number = Math.round(region.width * s);
    let h: number = Math.round(region.height * s);
    if (x + w > info.size.width) {
      w = info.size.width - x;
    }
    if (y + h > info.size.height) {
      h = info.size.height - y;
    }
    if (w < 2 || h < 2) {
      return;
    }
    const reg: image.Region = { x: x, y: y, size: { width: w, height: h } };
    await frame.crop(reg);
    hilog.info(DOMAIN, TAG, 'cropped to %{public}d,%{public}d %{public}dx%{public}d', x, y, w, h);
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
