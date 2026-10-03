// TriggerEngine — scan policy + classify + alert dispatch (DESIGN §7/§10).
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

  /** Trigger from an incident report: category/severity from the KB drive the result. */
  onReport(bundleName: string, text: string, category: string | undefined, severity: string | undefined,
    source: TriggerSource): ScanResult | null {
    if (!this.policy.decide(text)) {
      return null;
    }
    const now: number = Date.now();
    this.scanCount++;
    const request: ScanRequest = { bundleName, source, text, timestampMs: now };
    const result: ScanResult = TriggerEngine.fromIncident(category, severity);
    this.handle(request, result);
    return result;
  }

  private static fromIncident(category: string | undefined, severity: string | undefined): ScanResult {
    const sev: string = severity ?? 'WARNING';
    const verdict: Verdict = sev === 'CRITICAL' ? Verdict.CRITICAL : Verdict.DANGEROUS;
    return { verdict, category: category ?? 'scam', confidence: 1, signals: [], severity: sev };
  }

  /** React to a verdict (DESIGN.md §10: local notification via the sink). */
  private handle(request: ScanRequest, result: ScanResult): void {
    const alert: boolean = result.severity !== undefined || result.verdict !== Verdict.SAFE;
    const action: string = alert ? 'ALERT' : 'none';
    const line: string =
      `trigger #${this.scanCount} via=${request.source} bundle=${request.bundleName} ` +
      `chars=${request.text.length} => ${result.verdict}/${result.category} sev=${result.severity ?? '-'} action=${action}`;
    if (alert) {
      hilog.warn(DOMAIN, TAG, line);
      this.alertSink.alert(result, request.text, request.source);
    } else {
      hilog.info(DOMAIN, TAG, line);
    }
  }
}
