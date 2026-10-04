// Full-screen floating window that hosts the region selector (pages/SelectArea).
// The user taps two opposite corners; we destroy this window and hand the rect
// (in vp, display-relative) back so the caller can capture + crop.
import { common } from '@kit.AbilityKit';
import { window, display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianSelector';
const WIN_NAME: string = 'guardian_area_selector';

export type RectHandler = (x: number, y: number, w: number, h: number) => void;

export class SelectorOverlay {
  private static win: window.Window | null = null;
  private static ctx: common.UIAbilityContext | undefined = undefined;
  private static onRect: RectHandler | null = null;

  static setContext(context: common.UIAbilityContext): void {
    SelectorOverlay.ctx = context;
  }

  static isShown(): boolean {
    return SelectorOverlay.win !== null;
  }

  /** Show the full-screen selector; `onRect` is called with the chosen vp rect. */
  static async show(onRect: RectHandler): Promise<boolean> {
    if (SelectorOverlay.ctx === undefined) {
      hilog.warn(DOMAIN, TAG, 'no context; selector skipped');
      return false;
    }
    SelectorOverlay.onRect = onRect;
    try {
      const d: display.Display = display.getDefaultDisplaySync();
      const win: window.Window = await window.createWindow({
        name: WIN_NAME,
        windowType: window.WindowType.TYPE_FLOAT,
        ctx: SelectorOverlay.ctx
      });
      await win.loadContent('pages/SelectArea');
      await win.resize(d.width, d.height);
      await win.moveWindowTo(0, 0);
      await win.showWindow();
      try {
        await win.setWindowBackgroundColor('#00000000');
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'transparent background failed');
      }
      SelectorOverlay.win = win;
      hilog.info(DOMAIN, TAG, 'selector shown %{public}dx%{public}d', d.width, d.height);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'selector failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /** Confirm: close the selector first (so it isn't captured), then deliver the rect. */
  static async finish(x: number, y: number, w: number, h: number): Promise<void> {
    const cb: RectHandler | null = SelectorOverlay.onRect;
    await SelectorOverlay.destroy();
    // Let the display service settle after the window is gone; capturing too soon
    // fails with 1400003 ("display service unavailable").
    await SelectorOverlay.delay(300);
    if (cb !== null) {
      cb(x, y, w, h);
    }
  }

  static async cancel(): Promise<void> {
    SelectorOverlay.onRect = null;
    await SelectorOverlay.destroy();
  }

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  private static async destroy(): Promise<void> {
    const win: window.Window | null = SelectorOverlay.win;
    SelectorOverlay.win = null;
    SelectorOverlay.onRect = null;
    if (win === null) {
      return;
    }
    try {
      await win.destroyWindow();
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'destroy failed: %{public}s', JSON.stringify(err));
    }
  }
}
