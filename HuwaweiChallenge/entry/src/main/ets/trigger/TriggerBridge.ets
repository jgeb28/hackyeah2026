/**
 * TriggerBridge — fallback ingestion for environments where a third-party
 * accessibility service cannot be enabled (e.g. the Oniro x86 emulator, whose
 * Settings exposes no "installed services" toggle).
 *
 * The messaging app publishes a common event (`MESSAGE_RENDERED_EVENT`) as it
 * renders each message; the main app subscribes and feeds the same
 * TriggerEngine, so the classifier/rules pipeline is exercised unchanged.
 *
 * On a real HarmonyOS device the accessibility path
 * (GuardianAccessibilityExtAbility) is the primary trigger; this bridge is a
 * documented fallback for demoing the pipeline on the emulator.
 */
import { commonEventManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { TriggerEngine, TARGET_BUNDLE } from './TriggerEngine';
import { TriggerSource } from './TriggerTypes';

/** Must match the event name published by `mocks/mockchat`. */
export const MESSAGE_RENDERED_EVENT: string = 'com.hackyeah.mockchat.MESSAGE_RENDERED';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianBridge';

export class TriggerBridge {
  private static instance: TriggerBridge | null = null;
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;

  static get(): TriggerBridge {
    if (TriggerBridge.instance === null) {
      TriggerBridge.instance = new TriggerBridge();
    }
    return TriggerBridge.instance;
  }

  /** Subscribe once; safe to call repeatedly. */
  start(): void {
    if (this.subscriber !== null) {
      return;
    }
    const info: commonEventManager.CommonEventSubscribeInfo = {
      events: [MESSAGE_RENDERED_EVENT]
    };
    commonEventManager.createSubscriber(info).then((sub: commonEventManager.CommonEventSubscriber) => {
      this.subscriber = sub;
      commonEventManager.subscribe(sub, (err: Object, data: commonEventManager.CommonEventData) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `subscribe callback error: ${err}`);
          return;
        }
        const text: string = data.data ?? '';
        if (text.length === 0) {
          return;
        }
        TriggerEngine.get().onTextRendered(TARGET_BUNDLE, text, TriggerSource.COMMON_EVENT);
      });
      hilog.info(DOMAIN, TAG, 'common-event bridge subscribed');
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, `createSubscriber failed: ${e}`);
    });
  }
}
