// Floating alert window (TYPE_FLOAT) over other apps; sized to the text length.
import { window, display } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0A11;
const TAG = 'GuardianOverlay';
const WIN_NAME = 'guardian_alert_overlay';
const WIN_WIDTH_VP = 320;
const CHARS_PER_LINE = 44;
const LINE_H_VP = 18;
const FIXED_VP = 98;
const MAX_LINES = 4;
const MIN_HEIGHT_VP = 116;
const MAX_HEIGHT_VP = 178;

export class AlertOverlay {
  private static win: window.Window | null = null;
  private static ctx: common.Context | undefined = undefined;

  static setContext(context: common.Context): void {
    AlertOverlay.ctx = context;
  }

  private static heightVp(body: string): number {
    const lines: number = Math.min(MAX_LINES, Math.max(1, Math.ceil(body.length / CHARS_PER_LINE)));
    const height: number = FIXED_VP + lines * LINE_H_VP;
    return Math.min(MAX_HEIGHT_VP, Math.max(MIN_HEIGHT_VP, height));
  }

  /** Show (or refresh) the overlay. Returns false when the window is not permitted. */
  static async show(title: string, body: string, color: string): Promise<boolean> {
    if (AlertOverlay.ctx === undefined) {
      hilog.warn(DOMAIN, TAG, 'no context; overlay skipped');
      return false;
    }
    AppStorage.setOrCreate<string>('guardianTitle', title);
    AppStorage.setOrCreate<string>('guardianBody', body);
    AppStorage.setOrCreate<string>('guardianColor', color);

    try {
      const d: display.Display = display.getDefaultDisplaySync();
      const density: number = d.densityPixels;
      const winW: number = Math.round(WIN_WIDTH_VP * density);
      const winH: number = Math.round(AlertOverlay.heightVp(body) * density);
      const x: number = Math.max(0, Math.round((d.width - winW) / 2));
      const y: number = Math.round(40 * density);

      if (AlertOverlay.win !== null) {
        await AlertOverlay.win.resize(winW, winH);
        await AlertOverlay.win.showWindow();
        return true;
      }
      const win: window.Window = await window.createWindow({
        name: WIN_NAME,
        windowType: window.WindowType.TYPE_FLOAT,
        ctx: AlertOverlay.ctx
      });
      await win.loadContent('pages/SentinelOverlay');
      await win.resize(winW, winH);
      await win.moveWindowTo(x, y);
      await win.showWindow();
      try {
        await win.setWindowBackgroundColor('#00000000');
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'transparent background failed');
      }
      AlertOverlay.win = win;
      hilog.info(DOMAIN, TAG, 'overlay shown');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'overlay failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  static close(): void {
    const win: window.Window | null = AlertOverlay.win;
    if (win === null) {
      return;
    }
    AlertOverlay.win = null;
    win.destroyWindow().catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'destroy failed: %{public}s', err.message);
    });
  }
}
