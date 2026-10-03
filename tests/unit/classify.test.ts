import { test } from 'node:test';
import assert from 'node:assert/strict';
import { classifyText } from '../../HuwaweiChallenge/entry/src/main/ets/trigger/Classify';
import { Verdict } from '../../HuwaweiChallenge/entry/src/main/ets/trigger/TriggerTypes';

test('benign text is SAFE with no signals', () => {
  const r = classifyText('hey, are we still on for lunch tomorrow?');
  assert.equal(r.verdict, Verdict.SAFE);
  assert.equal(r.category, 'none');
  assert.equal(r.signals.length, 0);
});

test('a single signal is DANGEROUS', () => {
  const r = classifyText('please send me the file when you can');
  assert.equal(r.verdict, Verdict.DANGEROUS);
  assert.equal(r.signals.length, 1);
});

test('the family-emergency scam thread is CRITICAL', () => {
  const r = classifyText("it's me, don't call, send \u20AC4800 urgently");
  assert.equal(r.verdict, Verdict.CRITICAL);
  assert.equal(r.category, 'scam');
  assert.ok(r.signals.length >= 2);
  assert.ok(r.signals.includes('claims to be someone you know'));
  assert.ok(r.signals.includes('unusual payment request'));
  assert.ok(r.signals.includes('urgent / pressure to act'));
});

test('classification is case-insensitive', () => {
  const r = classifyText("IT'S ME. SEND MONEY NOW, DON'T TELL ANYONE");
  assert.equal(r.verdict, Verdict.CRITICAL);
});
