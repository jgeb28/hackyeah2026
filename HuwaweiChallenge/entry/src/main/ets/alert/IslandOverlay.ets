// Floating smart-island window (TYPE_FLOAT) so the user can scan while using other apps.
import { common, wantAgent } from '@kit.AbilityKit';
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { window, display } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianIslandWin';
const WIN_NAME: string = 'guardian_island_overlay';
const WIN_XL_VP: number = 300;
const WIN_XS_W_VP: number = 180;
const WIN_XS_H_VP: number = 56;
const WIN_XL_H_VP: number = 320;
const WIN_Y_VP: number = 40;
const BUNDLE: string = 'com.example.huwaweichallenge';

export class IslandOverlay {
  private static win: window.Window | null = null;
  private static ctx: common.UIAbilityContext | undefined = undefined;
  private static bgStarted: boolean = false;

  static setContext(context: common.UIAbilityContext): void {
    IslandOverlay.ctx = context;
  }

  static isShown(): boolean {
    return IslandOverlay.win !== null;
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
      const w: number = IslandOverlay.dp(WIN_XS_W_VP);
      const h: number = IslandOverlay.dp(WIN_XS_H_VP);
      const win: window.Window = await window.createWindow({
        name: WIN_NAME,
        windowType: window.WindowType.TYPE_FLOAT,
        ctx: IslandOverlay.ctx
      });
      await win.loadContent('pages/FloatingIsland');
      await win.resize(w, h);
      await win.moveWindowTo(IslandOverlay.centerX(w), IslandOverlay.dp(WIN_Y_VP));
      await win.showWindow();
      try {
        await win.setWindowBackgroundColor('#00000000');
      } catch (e) {
        hilog.warn(DOMAIN, TAG, 'transparent background failed');
      }
      IslandOverlay.win = win;
      await IslandOverlay.startBackground();
      hilog.info(DOMAIN, TAG, 'island window shown');
      return true;
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'island failed: %{public}s', JSON.stringify(err));
      return false;
    }
  }

  /** Grow/shrink the floating window with the island so it blocks as little as possible. */
  static resize(expanded: boolean): void {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    const w: number = IslandOverlay.dp(expanded ? WIN_XL_VP : WIN_XS_W_VP);
    const h: number = IslandOverlay.dp(expanded ? WIN_XL_H_VP : WIN_XS_H_VP);
    win.resize(w, h).then(() => {
      return win.moveWindowTo(IslandOverlay.centerX(w), IslandOverlay.dp(WIN_Y_VP));
    }).catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'resize failed: %{public}s', err.message);
    });
  }

  static close(): void {
    const win: window.Window | null = IslandOverlay.win;
    if (win === null) {
      return;
    }
    IslandOverlay.win = null;
    win.destroyWindow().catch((err: Error) => {
      hilog.warn(DOMAIN, TAG, 'destroy failed: %{public}s', err.message);
    });
    IslandOverlay.stopBackground();
  }

  private static dp(vp: number): number {
    const d: display.Display = display.getDefaultDisplaySync();
    return Math.round(vp * d.densityPixels);
  }

  private static centerX(winW: number): number {
    const d: display.Display = display.getDefaultDisplaySync();
    return Math.max(0, Math.round((d.width - winW) / 2));
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
