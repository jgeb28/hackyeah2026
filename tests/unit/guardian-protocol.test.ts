import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  encodeReport,
  decodeReport,
  GUARDIAN_MESSAGE_EVENT
} from '../../HuwaweiChallenge/guardian_sdk/src/main/ets/GuardianProtocol';

test('the event name is a stable contract', () => {
  assert.equal(GUARDIAN_MESSAGE_EVENT, 'com.hackyeah.guardian.MESSAGE_RENDERED');
});

test('round-trips a full report', () => {
  const encoded = encodeReport({
    bundleName: 'com.hackyeah.mockchat',
    text: 'send \u20AC4800 now',
    messageId: '5',
    timestampMs: 1700000000000
  });
  const decoded = decodeReport(encoded);
  assert.deepEqual(decoded, {
    bundleName: 'com.hackyeah.mockchat',
    text: 'send \u20AC4800 now',
    messageId: '5',
    timestampMs: 1700000000000
  });
});

test('round-trips a minimal report (no id / timestamp)', () => {
  const decoded = decodeReport(encodeReport({ bundleName: 'a.b', text: 'hi' }));
  assert.ok(decoded !== null);
  assert.equal(decoded.text, 'hi');
  assert.equal(decoded.bundleName, 'a.b');
  assert.equal(decoded.messageId, undefined);
});

test('falls back to plain text for legacy publishers', () => {
  const decoded = decodeReport('just a rendered message');
  assert.ok(decoded !== null);
  assert.equal(decoded.text, 'just a rendered message');
  assert.equal(decoded.bundleName, '');
});

test('rejects empty / whitespace-only payloads', () => {
  assert.equal(decodeReport(''), null);
  assert.equal(decodeReport('   '), null);
});

test('rejects JSON without usable text', () => {
  assert.equal(decodeReport('{"bundleName":"a.b"}'), null);
});

test('rejects malformed JSON gracefully', () => {
  assert.equal(decodeReport('{not valid json'), null);
});
