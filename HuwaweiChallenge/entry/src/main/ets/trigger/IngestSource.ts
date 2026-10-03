/**
 * IngestSource — the seam between "how text arrives" and the detection engine
 * (DESIGN.md §7). Shipping implementations: `InAppSdkSource` (Phase 1) and,
 * later, `ScreenOcrSource` (Phase 2) / system-access sources (§16).
 */
import { ScanResult, TriggerSource } from './TriggerTypes';

/** A unit of ingested text ready for scanning. */
export interface ScanJob {
  bundleName: string;
  text: string;
  messageId?: string;
  timestampMs: number;
}

/** An ingestion strategy. */
export interface IngestSource {
  /** Stable identifier, e.g. 'sdk'. */
  name: string;
  /** Whether this source can currently run (permission + user toggle). */
  enabled(): boolean;
  /** Begin emitting jobs. Safe to call repeatedly. */
  start(emit: (job: ScanJob) => void): void;
  /** Stop emitting and release resources. */
  stop(): void;
}

/** Sink for non-SAFE verdicts (DESIGN.md §10). Injectable for tests. */
export interface TriggerAlertSink {
  alert(result: ScanResult, sourceText: string, source: TriggerSource): void;
}
