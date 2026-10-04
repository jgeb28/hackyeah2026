import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseIncident, SAMPLE_INCIDENT_JSON } from '../../HuaweiChallenge/entry/src/main/ets/detail/DetailTypes';

test('parseIncident reads the KB incident shape', () => {
  const doc = parseIncident(SAMPLE_INCIDENT_JSON);
  assert.ok(doc);
  assert.equal(doc.id, 'bank-authority-impersonation');
  assert.equal(doc.category, 'scam');
  assert.equal(doc.severity, 'CRITICAL');
  assert.equal(doc.title, 'Possible impersonation');
  assert.ok(doc.description.length > 0);
  assert.ok(doc.explanation.length > 0);
  assert.ok(doc.remediation.length >= 2);
  assert.deepEqual(doc.sources, ['Bank security guidance']);
});

test('parseIncident tolerates missing fields and defaults severity', () => {
  const doc = parseIncident('{"title":"Only a title"}');
  assert.ok(doc);
  assert.equal(doc.title, 'Only a title');
  assert.equal(doc.severity, 'INFO');
  assert.equal(doc.id, '');
  assert.equal(doc.category, '');
  assert.equal(doc.description, '');
  assert.equal(doc.explanation, '');
  assert.deepEqual(doc.remediation, []);
  assert.deepEqual(doc.sources, []);
});

test('parseIncident returns null for malformed or non-object JSON', () => {
  assert.equal(parseIncident('{not json'), null);
  assert.equal(parseIncident('42'), null);
  assert.equal(parseIncident('"a string"'), null);
  assert.equal(parseIncident('null'), null);
  assert.equal(parseIncident('[1,2,3]'), null);
});

test('parseIncident filters non-string and blank list entries', () => {
  const doc = parseIncident('{"remediation":["a","","b"],"sources":[1,"s",""]}');
  assert.ok(doc);
  assert.deepEqual(doc.remediation, ['a', 'b']);
  assert.deepEqual(doc.sources, ['s']);
});
