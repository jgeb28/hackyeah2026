/**
 * GuardianProtocol — the wire contract between a host app (via GuardianClient)
 * and the Guardian engine. Platform-free so it is unit-testable on Node.
 */

/** Common-event name a host app publishes when it renders message text. */
export const GUARDIAN_MESSAGE_EVENT: string = 'com.hackyeah.guardian.MESSAGE_RENDERED';

/** Protocol version, embedded in every report for forward compatibility. */
export const GUARDIAN_SDK_VERSION: number = 1;

/** Payload a host app reports to Guardian. */
export interface GuardianReport {
  /** Publishing app's bundle name (provenance). */
  bundleName: string;
  /** The rendered text to scan. */
  text: string;
  /** Optional stable id for the message (dedupe / inspection). */
  messageId?: string;
  /** Optional epoch millis; the receiver fills `Date.now()` when absent. */
  timestampMs?: number;
}

/** JSON shape actually put on the wire. */
interface WireReport {
  v?: number;
  bundleName?: string;
  text?: string;
  messageId?: string;
  timestampMs?: number;
}

/** Serialize a report for the common event `data` field. */
export function encodeReport(report: GuardianReport): string {
  const wire: WireReport = {
    v: GUARDIAN_SDK_VERSION,
    bundleName: report.bundleName,
    text: report.text
  };
  if (report.messageId !== undefined) {
    wire.messageId = report.messageId;
  }
  if (report.timestampMs !== undefined) {
    wire.timestampMs = report.timestampMs;
  }
  return JSON.stringify(wire);
}

/**
 * Parse a report. Returns `null` when there is no usable text.
 * A non-JSON payload is treated as plain text (legacy publishers).
 */
export function decodeReport(raw: string): GuardianReport | null {
  if (raw === undefined || raw === null) {
    return null;
  }
  const trimmed: string = raw.trim();
  if (trimmed.length === 0) {
    return null;
  }
  if (trimmed.charAt(0) !== '{') {
    return { bundleName: '', text: raw };
  }
  try {
    const wire: WireReport = JSON.parse(trimmed) as WireReport;
    const text: string = wire.text ?? '';
    if (text.length === 0) {
      return null;
    }
    const report: GuardianReport = { bundleName: wire.bundleName ?? '', text };
    if (wire.messageId !== undefined) {
      report.messageId = wire.messageId;
    }
    if (wire.timestampMs !== undefined) {
      report.timestampMs = wire.timestampMs;
    }
    return report;
  } catch (e) {
    return null;
  }
}
