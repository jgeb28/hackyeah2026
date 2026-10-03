// Shared trigger types (platform-free, unit-testable).

/** Verdict levels (DESIGN.md §2). */
export enum Verdict {
  SAFE = 'SAFE',
  DANGEROUS = 'DANGEROUS',
  CRITICAL = 'CRITICAL'
}

/** Where a rendered-text trigger came from. */
export enum TriggerSource {
  PAGE_ACTIVE = 'pageActive',
  TEXT_UPDATE = 'textUpdate',
  WINDOW_UPDATE = 'windowUpdate',
  SCROLL = 'scroll',
  NOTIFICATION = 'notificationChange',
  /** Host app reported text through the Guardian SDK. */
  SDK = 'sdk',
  COMMON_EVENT = 'commonEvent',
  DEMO = 'demo',
  UNKNOWN = 'unknown'
}

/** Result of a single scan (DESIGN.md §9: `signals` are the "why"). */
export interface ScanResult {
  verdict: Verdict;
  /** scam | phishing | misinformation | harassment | none. */
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
