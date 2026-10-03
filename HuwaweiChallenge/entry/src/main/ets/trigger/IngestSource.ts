// IngestSource / ScanJob / TriggerAlertSink — text-in, alerts-out seams (§7).
import { ScanResult, TriggerSource } from './TriggerTypes';

/** A unit of ingested text ready for scanning. */
export interface ScanJob {
  bundleName: string;
  text: string;
  messageId?: string;
  timestampMs: number;
  /** Incident category/severity supplied by the report, when present. */
  category?: string;
  severity?: string;
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
