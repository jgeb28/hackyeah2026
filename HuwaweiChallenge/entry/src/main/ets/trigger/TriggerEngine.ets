/**
 * TriggerEngine — the "when do we scan" + "what is the verdict" core.
 *
 * Implements the ingestion trigger from DESIGN.md §6 in its first, deliberately
 * minimal form: **every time text is rendered in the observed (messaging) app we
 * run a scan.** Dedup/debounce, per-app gating and the CPU budget are already
 * modelled here so later stages (deterministic rules, then LAYA) drop in without
 * touching the accessibility layer.
 *
 * Pipeline:  rendered text -> onTextRendered() -> classify() -> handle()
 *            classify() is model-agnostic; today it returns SAFE (stub).
 */
import { hilog } from '@kit.PerformanceAnalysisKit';
import { ScanResult, ScanRequest, TriggerSource, Verdict } from './TriggerTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianTrigger';

/** Only the messaging app is observed for now (per-app gate, design §6). */
export const TARGET_BUNDLE: string = 'com.hackyeah.mockchat';

/** Tunables for the trigger/budget stage (design §6). */
export interface TriggerConfig {
  /** Ignore a scan if the same text was scanned within this window. */
  dedupeWindowMs: number;
  /** Hard cap on scans per minute (CPU/battery budget). */
  maxScansPerMinute: number;
}

export const TRIGGER_CONFIG: TriggerConfig = {
  dedupeWindowMs: 1500,
  maxScansPerMinute: 60
};

export class TriggerEngine {
  private static instance: TriggerEngine | null = null;

  private scanCount: number = 0;
  private lastText: string = '';
  private lastScanMs: number = 0;
  private windowStartMs: number = 0;
  private windowCount: number = 0;

  static get(): TriggerEngine {
    if (TriggerEngine.instance === null) {
      TriggerEngine.instance = new TriggerEngine();
    }
    return TriggerEngine.instance;
  }

  /**
   * THE TRIGGER. Called by the accessibility extension whenever text is
   * rendered in the observed app. Runs the scan synchronously (cheap stub today;
   * once LAYA is wired it moves off the event thread).
   */
  onTextRendered(bundleName: string, text: string, source: TriggerSource): ScanResult | null {
    const now: number = Date.now();

    // --- unchanged-skip + dedupe (design §6) -------------------------------
    const unchanged: boolean = text === this.lastText && (now - this.lastScanMs) < TRIGGER_CONFIG.dedupeWindowMs;
    if (unchanged) {
      return null;
    }

    // --- rolling rate budget ----------------------------------------------
    if (now - this.windowStartMs > 60000) {
      this.windowStartMs = now;
      this.windowCount = 0;
    }
    if (this.windowCount >= TRIGGER_CONFIG.maxScansPerMinute) {
      hilog.warn(DOMAIN, TAG, 'scan budget reached; skipping');
      return null;
    }
    this.windowCount++;

    this.lastText = text;
    this.lastScanMs = now;
    this.scanCount++;

    const request: ScanRequest = { bundleName, source, text, timestampMs: now };
    const result: ScanResult = this.classify(request);
    this.handle(request, result);
    return result;
  }

  /**
   * Model-agnostic classifier (design §7):
   *   step 1 (later): deterministic scam/misinformation rules -> filter off.
   *   step 2 (later): LAYA `.ms` via MindSpore Lite over the label space.
   * Today: stub that always returns SAFE, so the trigger plumbing can be proven.
   */
  classify(_request: ScanRequest): ScanResult {
    // TODO(rules): impersonation / urgency / payment rails / isolation / lure.
    // TODO(laya):  run the .ms model via @ohos.ai.mindSporeLite and map to Verdict.
    return { verdict: Verdict.SAFE, category: 'none', confidence: 0, signals: [] };
  }

  /** React to a verdict. Today: log. Later: AlertService (design §9). */
  private handle(request: ScanRequest, result: ScanResult): void {
    // `via` makes the ingestion path obvious; `action` distinguishes a trigger
    // that ran from one that actually raised an alert.
    const action: string = result.verdict === Verdict.SAFE ? 'none' : 'ALERT';
    const line: string =
      `trigger #${this.scanCount} via=${request.source} bundle=${request.bundleName} ` +
      `chars=${request.text.length} => ${result.verdict}/${result.category} action=${action}`;
    if (action === 'ALERT') {
      hilog.warn(DOMAIN, TAG, line);
    } else {
      hilog.info(DOMAIN, TAG, line);
    }
    // TODO(alert): if result.verdict !== Verdict.SAFE -> notification / overlay.
  }
}
