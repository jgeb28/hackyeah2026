// Optional cloud settings: the user's own DeepSeek API key, stored on-device.
// No server of ours: the app calls DeepSeek directly with the user's key.
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianCloud';
const STORE: string = 'guardian_cloud';
const KEY: string = 'deepseek_key';

export class DeepSeekSettings {
  private static store: preferences.Preferences | null = null;
  private static apiKey: string = '';

  static async load(context: common.UIAbilityContext): Promise<void> {
    try {
      DeepSeekSettings.store = await preferences.getPreferences(context, STORE);
      const k: preferences.ValueType = DeepSeekSettings.store.getSync(KEY, '');
      DeepSeekSettings.apiKey = typeof k === 'string' ? k : '';
      hilog.info(DOMAIN, TAG, 'cloud key present=%{public}s', DeepSeekSettings.apiKey.length > 0 ? 'yes' : 'no');
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'load failed: %{public}s', JSON.stringify(err));
    }
  }

  static get hasKey(): boolean {
    return DeepSeekSettings.apiKey.length > 0;
  }

  static get key(): string {
    return DeepSeekSettings.apiKey;
  }

  static async setKey(context: common.UIAbilityContext, key: string): Promise<void> {
    DeepSeekSettings.apiKey = key.trim();
    try {
      if (DeepSeekSettings.store === null) {
        DeepSeekSettings.store = await preferences.getPreferences(context, STORE);
      }
      DeepSeekSettings.store.putSync(KEY, DeepSeekSettings.apiKey);
      await DeepSeekSettings.store.flush();
      hilog.info(DOMAIN, TAG, 'cloud key saved present=%{public}s', DeepSeekSettings.apiKey.length > 0 ? 'yes' : 'no');
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'set failed: %{public}s', JSON.stringify(err));
    }
  }
}
