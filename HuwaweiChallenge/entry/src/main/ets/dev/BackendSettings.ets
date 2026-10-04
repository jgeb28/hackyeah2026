import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'BackendSettings';
const STORE: string = 'guardian_dev';

export class Backend {
  static readonly DEVICE: string = 'device';
  static readonly REMOTE: string = 'remote';
}

/**
 * Dev-only backend switch (persisted). Default is on-device; the remote mode
 * routes OCR and LAY A to the host dev server (see the separate devserver folder).
 */
export class BackendSettings {
  private static current: string = Backend.DEVICE;
  private static host: string = '127.0.0.1';
  private static port: number = 9100;
  private static store: preferences.Preferences | null = null;

  static async load(context: common.UIAbilityContext): Promise<void> {
    try {
      BackendSettings.store = await preferences.getPreferences(context, STORE);
      const b: preferences.ValueType = BackendSettings.store.getSync('backend', Backend.DEVICE);
      const h: preferences.ValueType = BackendSettings.store.getSync('host', '127.0.0.1');
      const p: preferences.ValueType = BackendSettings.store.getSync('port', 9100);
      BackendSettings.current = typeof b === 'string' ? b : Backend.DEVICE;
      BackendSettings.host = typeof h === 'string' ? h : '127.0.0.1';
      BackendSettings.port = typeof p === 'number' ? p : 9100;
      hilog.info(DOMAIN, TAG, 'loaded backend=%{public}s host=%{public}s:%{public}d',
        BackendSettings.current, BackendSettings.host, BackendSettings.port);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'load failed: %{public}s', JSON.stringify(error));
    }
  }

  static get mode(): string {
    return BackendSettings.current;
  }

  static get isRemote(): boolean {
    return BackendSettings.current === Backend.REMOTE;
  }

  static get baseUrl(): string {
    return `http://${BackendSettings.host}:${BackendSettings.port}`;
  }

  static async setBackend(context: common.UIAbilityContext, mode: string): Promise<void> {
    BackendSettings.current = mode;
    try {
      if (BackendSettings.store === null) {
        BackendSettings.store = await preferences.getPreferences(context, STORE);
      }
      BackendSettings.store.putSync('backend', mode);
      await BackendSettings.store.flush();
      hilog.info(DOMAIN, TAG, 'backend set to %{public}s', mode);
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'set failed: %{public}s', JSON.stringify(error));
    }
  }
}
