/**
 * NotificationService — the primary AlertSurface (DESIGN.md §9).
 *
 * When the trigger produces a non-SAFE verdict, the accessibility extension /
 * bridge publishes a local notification ("push" to the user) with the verdict
 * and the human-readable signals. Tapping it (later) opens the Guardian overlay.
 *
 * Usage: notificationManager.publish() — no restricted permission; the user must
 * have allowed notifications for the app (publish fails with 1600020 otherwise).
 */
import { notificationManager } from '@kit.NotificationKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ScanResult, Verdict } from '../trigger/TriggerTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianNotify';

/** From which ingestion path the alert came (shown in the notification). */
export const NOTIFY_CHANNEL: string = 'guardian_alerts';

export class NotificationService {
  private static instance: NotificationService | null = null;
  private nextId: number = 1000;

  static get(): NotificationService {
    if (NotificationService.instance === null) {
      NotificationService.instance = new NotificationService();
    }
    return NotificationService.instance;
  }

  /** Post the user-facing alert for a non-SAFE verdict. */
  publish(result: ScanResult, sourceText: string, via: string): void {
    const isCritical: boolean = result.verdict === Verdict.CRITICAL;
    const title: string = isCritical ? 'Potential scam detected' : 'Suspicious message';
    const body: string = sourceText.length > 140 ? `${sourceText.substring(0, 140)}…` : sourceText;
    const signals: string = result.signals.length > 0 ? result.signals.join(' · ') : 'Guardian';

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
      hilog.info(DOMAIN, TAG, `notification #${request.id} published: ${result.verdict}/${result.category} via=${via}`);
    }).catch((e: Object) => {
      hilog.error(DOMAIN, TAG, `publish failed: ${e}`);
    });
  }
}
