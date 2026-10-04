// Scan budget: unchanged-skip + dedupe window + per-minute cap (DESIGN §7.4).

export interface ScanPolicyConfig {
  /** Ignore a scan if the same text was scanned within this window. */
  dedupeWindowMs: number;
  /** Hard cap on scans per minute (CPU/battery budget). */
  maxScansPerMinute: number;
}

export const DEFAULT_SCAN_POLICY: ScanPolicyConfig = {
  dedupeWindowMs: 1500,
  maxScansPerMinute: 60
};

export class ScanPolicy {
  private dedupeWindowMs: number;
  private maxScansPerMinute: number;
  private now: () => number;
  private lastText: string = '';
  private lastScanMs: number = 0;
  private windowStartMs: number = 0;
  private windowCount: number = 0;

  constructor(config: ScanPolicyConfig, now?: () => number) {
    this.dedupeWindowMs = config.dedupeWindowMs;
    this.maxScansPerMinute = config.maxScansPerMinute;
    this.now = now ?? ((): number => Date.now());
  }

  /** true = run the scan; false = skip (unchanged/dedupe or over budget). */
  decide(text: string): boolean {
    const nowMs: number = this.now();

    const unchanged: boolean =
      text === this.lastText && (nowMs - this.lastScanMs) < this.dedupeWindowMs;
    if (unchanged) {
      return false;
    }

    if (nowMs - this.windowStartMs > 60000) {
      this.windowStartMs = nowMs;
      this.windowCount = 0;
    }
    if (this.windowCount >= this.maxScansPerMinute) {
      return false;
    }
    this.windowCount++;

    this.lastText = text;
    this.lastScanMs = nowMs;
    return true;
  }

  reset(): void {
    this.lastText = '';
    this.lastScanMs = 0;
    this.windowStartMs = 0;
    this.windowCount = 0;
  }
}
