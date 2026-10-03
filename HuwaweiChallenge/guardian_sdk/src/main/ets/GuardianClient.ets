// GuardianClient — host-app entry point of the SDK (DESIGN §7.1).
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
    // NOTE: CommonEventPublishData.bundleName targets a *subscriber* bundle, so
    // it must NOT be set to the publisher's name (that would drop the event).
    // Provenance travels inside the payload; we also expose it as a parameter.
    const options: commonEventManager.CommonEventPublishData = {
      data: payload,
      parameters: { publisherBundleName: bundleName }
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
