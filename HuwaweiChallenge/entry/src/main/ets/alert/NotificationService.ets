// NotificationService — posts local alerts; implements TriggerAlertSink (DESIGN §10).
import { notificationManager } from '@kit.NotificationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ScanResult, TriggerSource, Verdict } from '../trigger/TriggerTypes';
import { TriggerAlertSink } from '../trigger/IngestSource';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianNotify';

/** Notification channel/group tag (shown in logs and, later, the overlay). */
export const NOTIFY_CHANNEL: string = 'guardian_alerts';

export class NotificationService implements TriggerAlertSink {
  private static instance: NotificationService | null = null;
  private nextId: number = 1000;

  static get(): NotificationService {
    if (NotificationService.instance === null) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /** Post the user-facing alert for a non-SAFE verdict. */
  alert(result: ScanResult, sourceText: string, source: TriggerSource): void {
    const via: string = `${source}`;
    const isCritical: boolean = result.verdict === Verdict.CRITICAL;
    const title: string = isCritical ? 'Potential scam detected' : 'Suspicious message';
    const body: string = sourceText.length > 140 ? `${sourceText.substring(0, 140)}\u2026` : sourceText;
    const signals: string = result.signals.length > 0 ? result.signals.join(' \u00B7 ') : 'Guardian';

    const request: notificationManager.NotificationRequest = {
      id: this.nextId++,
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: title,
          text: body,
          additionalText: `${signals} (via ${via})`
        }
      }
    };

    notificationManager.publish(request).then(() => {
      hilog.info(DOMAIN, TAG,
        `notification #${request.id} published: ${result.verdict}/${result.category} via=${via}`);
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, `publish failed: ${e}`);
    });
  }
}
