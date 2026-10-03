// Incident detail model — the KB incident shape that LAYA supplies and that
// IncidentDetailView renders. Pure TS (no ArkUI) so it stays unit-testable.

export interface IncidentDoc {
  id: string;
  category: string;
  severity: string;
  title: string;
  description: string;
  explanation: string;
  remediation: string[];
  sources: string[];
}

/** Raw JSON shape (all fields optional/tolerant). */
interface RawIncident {
  id?: string;
  category?: string;
  severity?: string;
  title?: string;
  description?: string;
  explanation?: string;
  remediation?: string[];
  sources?: string[];
}

function asString(value: string | undefined): string {
  return typeof value === 'string' ? value : '';
}

function asStringArray(value: string[] | undefined): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  const out: string[] = [];
  for (const item of value) {
    if (typeof item === 'string' && item.trim().length > 0) {
      out.push(item);
    }
  }
  return out;
}

/**
 * Parse a KB-shape incident JSON string into a normalized IncidentDoc.
 * Returns null when the input is malformed or not a JSON object.
 * Missing fields are defaulted; `severity` defaults to INFO.
 */
export function parseIncident(json: string): IncidentDoc | null {
  let raw: RawIncident;
  try {
    raw = JSON.parse(json) as RawIncident;
  } catch (err) {
    return null;
  }
  if (raw === null || raw === undefined || typeof raw !== 'object' || Array.isArray(raw)) {
    return null;
  }
  const severity: string = asString(raw.severity);
  return {
    id: asString(raw.id),
    category: asString(raw.category),
    severity: severity.length > 0 ? severity : 'INFO',
    title: asString(raw.title),
    description: asString(raw.description),
    explanation: asString(raw.explanation),
    remediation: asStringArray(raw.remediation),
    sources: asStringArray(raw.sources)
  };
}

/** Sample incident used by the demo page until LAYA supplies a real one. */
export const SAMPLE_INCIDENT_JSON: string = JSON.stringify({
  id: 'bank-authority-impersonation',
  category: 'scam',
  severity: 'CRITICAL',
  title: 'Possible impersonation',
  description: 'Someone claims to be your bank, police, or tax office and pushes you to verify or pay immediately.',
  explanation: 'Real banks and authorities never ask you to verify or pay through a link in a message.',
  remediation: [
    'Contact your bank using the number on your card or the official app.',
    "Don't tap the link or enter your details.",
    'Report the message.'
  ],
  sources: ['Bank security guidance']
});
