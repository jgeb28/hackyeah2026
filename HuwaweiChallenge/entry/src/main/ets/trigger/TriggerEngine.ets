/**
 * TriggerEngine — the "when do we scan" + "what is the verdict" core.
 *
 * Ingestion is pluggable (`IngestSource`, DESIGN.md §7): the SDK source
 * (`InAppSdkSource`) feeds it today; accessibility / OCR / system sources feed
 * the same `onTextRendered` seam. Policy (dedupe/budget) lives in the
 * platform-free `ScanPolicy`; classification in `Classify`.
 *
 * Injecting a policy + alert sink keeps the engine unit- and integration-
 * testable without touching notifications.
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ScanRequest, ScanResult, TriggerSource, Verdict } from './TriggerTypes';
import { classifyText } from './Classify';
import { DEFAULT_SCAN_POLICY, ScanPolicy } from './ScanPolicy';
import { TriggerAlertSink } from './IngestSource';
import { NotificationService } from '../alert/NotificationService';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianTrigger';

/** Only the messaging app is observed by the demo (per-app gate, design §7). */
export const TARGET_BUNDLE: string = 'com.hackyeah.mockchat';

export class TriggerEngine {
  private static instance: TriggerEngine | null = null;

  private policy: ScanPolicy;
  private alertSink: TriggerAlertSink;
  private scanCount: number = 0;

  constructor(policy?: ScanPolicy, alertSink?: TriggerAlertSink) {
    this.policy = policy ?? new ScanPolicy(DEFAULT_SCAN_POLICY);
    this.alertSink = alertSink ?? NotificationService.get();
  }

  static get(): TriggerEngine {
    if (TriggerEngine.instance === null) {
      TriggerEngine.instance = new TriggerEngine();
    }
    return TriggerEngine.instance;
  }

  /**
   * THE TRIGGER. Called by an ingestion source whenever text is rendered in the
   * observed app. Returns the verdict, or `null` when the scan was skipped by
   * dedupe/budget (so callers can distinguish "skipped" from "SAFE").
   */
  onTextRendered(bundleName: string, text: string, source: TriggerSource): ScanResult | null {
    if (!this.policy.decide(text)) {
      return null;
    }

    const now: number = Date.now();
    this.scanCount++;
    const request: ScanRequest = { bundleName, source, text, timestampMs: now };
    const result: ScanResult = classifyText(text);
    this.handle(request, result);
    return result;
  }

  /** React to a verdict (DESIGN.md §10: local notification via the sink). */
  private handle(request: ScanRequest, result: ScanResult): void {
    const action: string = result.verdict === Verdict.SAFE ? 'none' : 'ALERT';
    const line: string =
      `trigger #${this.scanCount} via=${request.source} bundle=${request.bundleName} ` +
      `chars=${request.text.length} => ${result.verdict}/${result.category} action=${action}`;
    if (action === 'ALERT') {
      hilog.warn(DOMAIN, TAG, line);
      this.alertSink.alert(result, request.text, request.source);
    } else {
      hilog.info(DOMAIN, TAG, line);
    }
  }
}
