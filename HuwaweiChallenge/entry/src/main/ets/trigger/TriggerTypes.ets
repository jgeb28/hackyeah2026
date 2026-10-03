/**
 * Trigger types — shared by the accessibility extension and the classifier.
 *
 * Keep this file free of platform imports so it stays unit-testable and so the
 * rules engine / LAYA adapter can be swapped without touching call sites.
 */

/** Verdict levels from DESIGN.md §2 (scenario classification). */
export enum Verdict {
  SAFE = 'SAFE',
  DANGEROUS = 'DANGEROUS',
  CRITICAL = 'CRITICAL'
}

/** Where a rendered-text trigger came from (accessibility event type). */
export enum TriggerSource {
  PAGE_ACTIVE = 'pageActive',
  TEXT_UPDATE = 'textUpdate',
  WINDOW_UPDATE = 'windowUpdate',
  SCROLL = 'scroll',
  NOTIFICATION = 'notificationChange',
  /** Fallback path when accessibility cannot be enabled (e.g. this emulator):
   *  the messaging app publishes a common event as it renders text. */
  COMMON_EVENT = 'commonEvent',
  UNKNOWN = 'unknown'
}

/** Result of a single scan. `signals` are the human-readable "why" (design §9). */
export interface ScanResult {
  verdict: Verdict;
  /** scam | phishing | misinformation | harassment | none (design §7). */
  category: string;
  confidence: number;
  signals: string[];
}

/** A trigger that fired: the rendered text plus its origin. */
export interface ScanRequest {
  bundleName: string;
  source: TriggerSource;
  text: string;
  timestampMs: number;
}
