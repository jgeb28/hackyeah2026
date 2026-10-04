// Floating smart-island window (TYPE_FLOAT), anchored around the camera cutout so
// the user can scan while using other apps.
import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { window, display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianIslandWin';
const WIN_NAME: string = 'guardian_island_overlay';
const WIN_XS_W_VP: number = 164;
const WIN_XS_H_VP: number = 52;
const WIN_XL_VP: number = 276;
const WIN_XL_H_VP: number = 288;
const DETAIL_W_VP: number = 320;
const DETAIL_H_VP: number = 560;
const DETAIL_Y_VP: number = 80;
const BUNDLE: string = 'com.example.huwaweichallenge';

export class IslandOverlay {
  private static win: window.Window | null = null;
  private static ctx: common.UIAbilityContext | undefined = undefined;
  private static bgStarted: boolean = false;
  private static detailMode: boolean = false;
  /** Camera-cutout centre x (px) and the capsule's top y (px). */
  private static camCx: number = 0;
  private static topY: number = 0;

  static setContext(context: common.UIAbilityContext): void {
    IslandOverlay.ctx = context;
  }

  static isShown(): boolean {
    return IslandOverlay.win !== null;
  }

  /** Hide the island from captures (privacy mode); restore with reveal(). */
  static async hide(): Promise<void> {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    try {
      await win.setWindowPrivacyMode(true);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'privacy on failed: %{public}s', JSON.stringify(err));
    }
  }

  /** Leave privacy mode after hide(). */
  static async reveal(): Promise<void> {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    try {
      await win.setWindowPrivacyMode(false);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'privacy off failed: %{public}s', JSON.stringify(err));
    }
  }

  /** Current floating-window rect in px, or null when the island is not shown. */
  static rectPx(): window.Rect | null {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return null;
    }
    try {
      return win.getWindowProperties().windowRect;
    } catch (err) {
      return null;
    }
  }

  /** Show (or re-show) the floating island. Returns false when not permitted. */
  static async show(): Promise<boolean> {
    if (IslandOverlay.ctx === undefined) {
      hilog.warn(DOMAIN, TAG, 'no context; island skipped');
      return false;
    }
    if (IslandOverlay.win !== null) {
      await IslandOverlay.win.showWindow();
      return true;
    }
    try {
      await IslandOverlay.computePlacement();
      const w: number = IslandOverlay.dp(WIN_XS_W_VP);
      const h: number = IslandOverlay.dp(WIN_XS_H_VP);
      const win: window.Window = await window.createWindow({
        name: WIN_NAME,
        windowType: window.WindowType.TYPE_FLOAT,
        ctx: IslandOverlay.ctx
      });
      await win.loadContent('pages/FloatingIsland');
      await win.resize(w, h);
      await win.moveWindowTo(IslandOverlay.xFor(w), IslandOverlay.topY);
      await win.showWindow();
      try {
        await win.setWindowBackgroundColor('#00000000');
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'transparent background failed');
      }
      IslandOverlay.win = win;
      await IslandOverlay.startBackground();
      hilog.info(DOMAIN, TAG, 'island shown at x=%{public}d y=%{public}d', IslandOverlay.xFor(w), IslandOverlay.topY);
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'island failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /** Grow/shrink the floating window between the capsule and the expanded card. */
  static resize(expanded: boolean): void {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    const w: number = IslandOverlay.dp(expanded ? WIN_XL_VP : WIN_XS_W_VP);
    const h: number = IslandOverlay.dp(expanded ? WIN_XL_H_VP : WIN_XS_H_VP);
    win.resize(w, h).then(() => {
      return win.moveWindowTo(IslandOverlay.xFor(w), IslandOverlay.topY);
    }).catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'resize failed: %{public}s', err.message);
    });
  }

  /** Grow the window to host the incident detail page, or shrink back to the island. */
  static setDetailMode(on: boolean): void {
    if (IslandOverlay.detailMode === on) {
      return;
    }
    IslandOverlay.detailMode = on;
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    const d: display.Display = display.getDefaultDisplaySync();
    const maxW: number = d.width / d.densityPixels;
    const maxH: number = d.height / d.densityPixels;
    const wVp: number = on ? Math.min(DETAIL_W_VP, maxW - 16) : WIN_XL_VP;
    const hVp: number = on ? Math.min(DETAIL_H_VP, maxH - 140) : WIN_XL_H_VP;
    const y: number = on ? IslandOverlay.dp(DETAIL_Y_VP) : IslandOverlay.topY;
    const w: number = IslandOverlay.dp(wVp);
    const h: number = IslandOverlay.dp(hVp);
    win.resize(w, h).then(() => {
      return win.moveWindowTo(IslandOverlay.xFor(w), y);
    }).catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'detail resize failed: %{public}s', err.message);
    });
  }

  static close(): void {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    IslandOverlay.win = null;
    IslandOverlay.detailMode = false;
    win.destroyWindow().catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'destroy failed: %{public}s', err.message);
    });
    IslandOverlay.stopBackground();
  }

  /** Read the camera cutout so the capsule hugs it; falls back to top-centre. */
  private static async computePlacement(): Promise<void> {
    const d: display.Display = display.getDefaultDisplaySync();
    let cx: number = d.width / 2;
    let topY: number = IslandOverlay.dp(6);
    try {
      const cut: display.CutoutInfo = await d.getCutoutInfo();
      if (cut.boundingRects.length > 0) {
        const r: display.Rect = cut.boundingRects[0];
        cx = r.left + r.width / 2;
        topY = Math.max(0, Math.round(r.top + r.height + IslandOverlay.dp(4)));
      }
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'cutout unavailable: %{public}s', JSON.stringify(err));
    }
    IslandOverlay.camCx = cx;
    IslandOverlay.topY = topY;
  }

  private static xFor(winW: number): number {
    return Math.max(0, Math.round(IslandOverlay.camCx - winW / 2));
  }

  private static dp(vp: number): number {
    const d: display.Display = display.getDefaultDisplaySync();
    return Math.round(vp * d.densityPixels);
  }

  // Keep the process responsive so the island still reacts while the app is backgrounded.
  private static async startBackground(): Promise<void> {
    if (IslandOverlay.bgStarted || IslandOverlay.ctx === undefined) {
      return;
    }
    try {
      const info: wantAgent.WantAgentInfo = {
        wants: [{ bundleName: BUNDLE, abilityName: 'EntryAbility' }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0
      };
      const agent = await wantAgent.getWantAgent(info);
      await backgroundTaskManager.startBackgroundRunning(IslandOverlay.ctx,
        backgroundTaskManager.BackgroundMode.DATA_TRANSFER, agent);
      IslandOverlay.bgStarted = true;
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'background task failed: %{public}s', JSON.stringify(err));
    }
  }

  private static stopBackground(): void {
    if (!IslandOverlay.bgStarted || IslandOverlay.ctx === undefined) {
      return;
    }
    IslandOverlay.bgStarted = false;
    backgroundTaskManager.stopBackgroundRunning(IslandOverlay.ctx).catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'stop background failed: %{public}s', err.message);
    });
  }
}
