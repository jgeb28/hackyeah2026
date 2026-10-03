// InAppSdkSource — subscribe to SDK reports and emit ScanJobs (DESIGN §7.1).
import { commonEventManager } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { GUARDIAN_MESSAGE_EVENT, GuardianReport, decodeReport } from '@hackyeah/guardian_sdk';
import { IngestSource, ScanJob } from '../trigger/IngestSource';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianSdkSource';

export class InAppSdkSource implements IngestSource {
  name: string = 'sdk';
  private subscriber: commonEventManager.CommonEventSubscriber | null = null;
  private emit: ((job: ScanJob) => void) | null = null;

  enabled(): boolean {
    return true;
  }

  start(emit: (job: ScanJob) => void): void {
    if (this.subscriber !== null) {
      return;
    }
    this.emit = emit;

    const info: commonEventManager.CommonEventSubscribeInfo = {
      events: [GUARDIAN_MESSAGE_EVENT]
    };
    commonEventManager.createSubscriber(info).then((sub: commonEventManager.CommonEventSubscriber) => {
      this.subscriber = sub;
      commonEventManager.subscribe(sub, (err: Object, data: commonEventManager.CommonEventData) => {
        if (err) {
          hilog.error(DOMAIN, TAG, `subscribe callback error: ${err}`);
          return;
        }
        const report: GuardianReport | null = decodeReport(data.data ?? '');
        if (report === null || report.text.length === 0) {
          return;
        }
        const job: ScanJob = {
          bundleName: report.bundleName,
          text: report.text,
          messageId: report.messageId,
          timestampMs: report.timestampMs ?? Date.now()
        };
        if (this.emit !== null) {
          this.emit(job);
        }
      });
      hilog.info(DOMAIN, TAG, 'SDK source subscribed');
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, `createSubscriber failed: ${e}`);
    });
  }

  stop(): void {
    if (this.subscriber === null) {
      return;
    }
    commonEventManager.unsubscribe(this.subscriber);
    this.subscriber = null;
    this.emit = null;
  }
}
