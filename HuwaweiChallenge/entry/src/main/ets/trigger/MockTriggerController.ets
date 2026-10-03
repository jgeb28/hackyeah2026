// Mock trigger: a global shortcut reports the next KB incident via the SDK (no own messages).
import { inputConsumer, KeyCode } from '@kit.InputKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GuardianClient, GuardianReport } from '@hackyeah/guardian_sdk';
import { IncidentKnowledge, KbIncident } from '../kb/IncidentKnowledge';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianTrigger';

/** Bundle name of the (stand-in) host messaging app that reports rendered text. */
const MOCK_HOST_BUNDLE: string = 'com.hackyeah.mockchat';

/** Global shortcut: Alt + Shift + E. */
const HOTKEY: inputConsumer.HotkeyOptions = {
  preKeys: [KeyCode.KEYCODE_ALT_LEFT, KeyCode.KEYCODE_SHIFT_LEFT],
  finalKey: KeyCode.KEYCODE_E,
  isRepeat: false
};

let registered: boolean = false;
let cursor: number = 0;
const client: GuardianClient = new GuardianClient();

function reportIncident(incident: KbIncident): void {
  hilog.info(DOMAIN, TAG, `report incident ${incident.id} (${incident.category}/${incident.severity})`);
  const payload: GuardianReport = {
    bundleName: MOCK_HOST_BUNDLE,
    text: incident.text,
    messageId: incident.id,
    category: incident.category,
    severity: incident.severity
  };
  client.report(payload);
}

function onHotkey(options: inputConsumer.HotkeyOptions): void {
  MockTriggerController.reportNext();
}

export class MockTriggerController {
  /** Report the next KB incident (used by the global shortcut). */
  static reportNext(): void {
    const total: number = IncidentKnowledge.count();
    if (total === 0) {
      hilog.warn(DOMAIN, TAG, 'KB empty');
      return;
    }
    const incident: KbIncident | undefined = IncidentKnowledge.at(cursor % total);
    cursor++;
    if (incident !== undefined) {
      reportIncident(incident);
    }
  }

  static register(): void {
    if (registered) {
      return;
    }
    try {
      inputConsumer.on('hotkeyChange', HOTKEY, onHotkey);
      registered = true;
      hilog.info(DOMAIN, TAG, 'mock trigger registered (Alt+Shift+E)');
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'register failed: %{public}s', JSON.stringify(err));
    }
  }

  static unregister(): void {
    if (!registered) {
      return;
    }
    try {
      inputConsumer.off('hotkeyChange', HOTKEY, onHotkey);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'unregister failed: %{public}s', JSON.stringify(err));
    }
    registered = false;
  }
}
