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
import { NotificationService } from '../alert/NotificationService';

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
   *   step 1 (now):  deterministic scam rules over the label space.
   *   step 2 (later): LAYA `.ms` via MindSpore Lite behind the same interface.
   */
  classify(request: ScanRequest): ScanResult {
    const t: string = request.text.toLowerCase();
    const signals: string[] = [];

    // Impersonation / claimed identity.
    if (t.includes("it's me") || t.includes('its me') || t.includes('this is your') ||
      t.includes("friend's number") || t.includes('new number')) {
      signals.push('claims to be someone you know');
    }
    // Urgency / pressure to act.
    if (t.includes('right now') || t.includes('today') || t.includes('urgent') ||
      t.includes('asap') || t.includes('immediately') || t.includes('before ') ||
      t.includes("don't call") || t.includes('do not call')) {
      signals.push('urgent / pressure to act');
    }
    // Unusual payment rails.
    if (t.includes('send') || t.includes('pay') || t.includes('transfer') ||
      t.includes('€') || t.includes('$') || t.includes('account details') ||
      t.includes('gift card') || t.includes('crypto')) {
      signals.push('unusual payment request');
    }
    // Isolation / secrecy.
    if (t.includes("don't tell") || t.includes('do not tell') || t.includes('keep this') ||
      t.includes('between us')) {
      signals.push('asks for secrecy / isolation');
    }

    // Tunable thresholds (design §7): 0 -> SAFE, 1 -> DANGEROUS, >=2 -> CRITICAL.
    if (signals.length >= 2) {
      return { verdict: Verdict.CRITICAL, category: 'scam', confidence: 0.9, signals };
    }
    if (signals.length === 1) {
      return { verdict: Verdict.DANGEROUS, category: 'phishing', confidence: 0.6, signals };
    }
    return { verdict: Verdict.SAFE, category: 'none', confidence: 0, signals };
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
      // Primary alert surface (design §9): local notification to the user.
      NotificationService.get().publish(result, request.text, request.source);
    } else {
      hilog.info(DOMAIN, TAG, line);
    }
  }
}
