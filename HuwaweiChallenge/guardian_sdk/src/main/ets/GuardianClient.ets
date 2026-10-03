/**
 * GuardianClient — the host-app entry point of the Guardian SDK.
 *
 * `report()` serializes a `GuardianReport` and hands it to an injectable
 * `ReportEmitter`. The default emitter publishes the SDK common event, which the
 * Guardian engine listens for (`InAppSdkSource`). Injecting an emitter keeps the
 * client testable without touching the event subsystem.
 */
import { commonEventManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GUARDIAN_MESSAGE_EVENT, GuardianReport, encodeReport } from './GuardianProtocol';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianSdk';

/** Sink the client publishes through; injectable for tests. */
export interface ReportEmitter {
  emit(event: string, payload: string, bundleName: string): void;
}

/** Default emitter: a common event delivered to the Guardian engine. */
export class CommonEventEmitter implements ReportEmitter {
  emit(event: string, payload: string, bundleName: string): void {
    const options: commonEventManager.CommonEventPublishData = {
      bundleName: bundleName,
      data: payload
    };
    commonEventManager.publish(event, options, (err: Object) => {
      if (err) {
        hilog.error(DOMAIN, TAG, `publish ${event} failed: ${err}`);
      }
    });
  }
}

/** Host-app entry point: report rendered text to Guardian. */
export class GuardianClient {
  private emitter: ReportEmitter;

  constructor(emitter?: ReportEmitter) {
    this.emitter = emitter ?? new CommonEventEmitter();
  }

  /** Report one rendered message. Cheap and fire-and-forget. */
  report(report: GuardianReport): void {
    const payload: string = encodeReport(report);
    this.emitter.emit(GUARDIAN_MESSAGE_EVENT, payload, report.bundleName);
  }
}
