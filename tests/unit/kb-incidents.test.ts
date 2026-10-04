import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';

interface Level0 { title: string; text: string; }
interface Level1 { instruction: string; maxTokens: number; fallback: string; }
interface Level2 { instruction: string; maxTokens: number; consentRequired: boolean; fallback: string; }
interface Incident {
  id: string; version: number; locale: string; category: string;
  severity: string; escalation: string; cta: string;
  title: string; description: string; keywords: string[];
  signals: { required?: string[]; anyOf?: string[] };
  explanation: string; remediation: string[]; actions: string[]; sources: string[];
  messages: { level0?: Level0; level1?: Level1; level2?: Level2 };
}
interface Kb {
  schemaVersion: number; locale: string;
  severityColors: Record<string, string>;
  prompts: { localSystem: string; cloudSystem: string };
  incidents: Incident[];
}

const KB_PATH = resolve(__dirname, '../../../HuwaweiChallenge/entry/src/main/resources/rawfile/kb/en/incidents.json');
const kb = JSON.parse(readFileSync(KB_PATH, 'utf8')) as Kb;
const SEVERITIES = ['CRITICAL', 'WARNING', 'INFO'];
const ESCALATIONS = ['L0', 'L1', 'L2'];

test('kb has the expected top-level shape', () => {
  assert.equal(kb.schemaVersion, 1);
  assert.equal(kb.locale, 'en');
  assert.equal(kb.incidents.length, 9);
  for (const s of SEVERITIES) assert.ok(typeof kb.severityColors[s] === 'string', `color ${s}`);
  assert.ok(kb.prompts.localSystem.length > 0);
  assert.ok(kb.prompts.cloudSystem.length > 0);
});

test('every incident has the required fields and valid enums', () => {
  const ids = new Set<string>();
  for (const inc of kb.incidents) {
    assert.ok(inc.id.length > 0, 'id');
    assert.ok(!ids.has(inc.id), `duplicate id ${inc.id}`);
    ids.add(inc.id);
    assert.equal(inc.locale, 'en', `${inc.id} locale`);
    assert.ok(SEVERITIES.includes(inc.severity), `${inc.id} severity`);
    assert.ok(ESCALATIONS.includes(inc.escalation), `${inc.id} escalation`);
    assert.ok(inc.cta.length > 0, `${inc.id} cta`);
    assert.ok(inc.title.length > 0, `${inc.id} title`);
    assert.ok(inc.description.length > 0, `${inc.id} description`);
    assert.ok(inc.keywords.length > 0, `${inc.id} keywords`);
    assert.ok(inc.remediation.length > 0, `${inc.id} remediation`);
    assert.ok(inc.messages.level0 !== undefined, `${inc.id} level0`);
    assert.ok(inc.messages.level0!.title.length > 0, `${inc.id} level0 title`);
    assert.ok(inc.messages.level0!.text.length > 0, `${inc.id} level0 text`);
  }
});

test('the escalation level matches the message layers present', () => {
  for (const inc of kb.incidents) {
    if (inc.escalation === 'L0') {
      assert.equal(inc.messages.level1, undefined, `${inc.id} has no level1`);
      assert.equal(inc.messages.level2, undefined, `${inc.id} has no level2`);
    } else if (inc.escalation === 'L1') {
      assert.ok(inc.messages.level1 !== undefined, `${inc.id} level1`);
      assert.equal(inc.messages.level1!.fallback, 'level0', `${inc.id} level1 fallback`);
      assert.equal(inc.messages.level2, undefined, `${inc.id} has no level2`);
    } else {
      assert.ok(inc.messages.level2 !== undefined, `${inc.id} level2`);
      assert.equal(inc.messages.level2!.fallback, 'level0', `${inc.id} level2 fallback`);
      assert.equal(inc.messages.level2!.consentRequired, true, `${inc.id} consent`);
    }
  }
});

test('the two design scenarios sit at their intended levels', () => {
  const byId = new Map<string, Incident>(kb.incidents.map((i): [string, Incident] => [i.id, i]));
  assert.equal(byId.get('family-emergency-money')?.escalation, 'L0');
  assert.equal(byId.get('misinfo-breaking-event')?.escalation, 'L2');
});

// The single LAY A "incident" question is generated from the KB: one option per
// incident (id = label), option text = the incident description, in file order.
// The app (IncidentKb.publishChoices) and the converter (build_incident_question)
// must produce the same list. Descriptions are kept short to fit the LAY A head
// budget (head_max_len = 192 across all options).
test('LAY A incident options derive from the incidents, in file order', () => {
  const labels = kb.incidents.map((i) => i.id);
  assert.equal(labels.length, 9, 'nine incident options');
  assert.equal(new Set(labels).size, labels.length, 'option ids are unique');
  for (const inc of kb.incidents) {
    assert.ok(inc.description.length > 0, `${inc.id} has an option description`);
    assert.ok(inc.description.split(/\s+/).length <= 16, `${inc.id} description is short`);
  }
});
