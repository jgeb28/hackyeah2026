import { test } from 'node:test';
import assert from 'node:assert/strict';
import { ScanPolicy } from '../../HuaweiChallenge/entry/src/main/ets/trigger/ScanPolicy';

interface Clock {
  now: () => number;
  set: (t: number) => void;
}

function fixedClock(): Clock {
  let t = 0;
  return { now: () => t, set: (v: number) => { t = v; } };
}

test('first scan runs; immediate duplicate is deduped', () => {
  const c = fixedClock();
  const p = new ScanPolicy({ dedupeWindowMs: 1500, maxScansPerMinute: 60 }, c.now);
  assert.equal(p.decide('hello'), true);
  assert.equal(p.decide('hello'), false);
});

test('same text re-scans after the dedupe window', () => {
  const c = fixedClock();
  const p = new ScanPolicy({ dedupeWindowMs: 1500, maxScansPerMinute: 60 }, c.now);
  assert.equal(p.decide('hello'), true);
  c.set(2000);
  assert.equal(p.decide('hello'), true);
});

test('different text always scans', () => {
  const c = fixedClock();
  const p = new ScanPolicy({ dedupeWindowMs: 1500, maxScansPerMinute: 60 }, c.now);
  assert.equal(p.decide('a'), true);
  assert.equal(p.decide('b'), true);
});

test('per-minute budget is enforced and rolls over', () => {
  const c = fixedClock();
  const p = new ScanPolicy({ dedupeWindowMs: 0, maxScansPerMinute: 3 }, c.now);
  assert.equal(p.decide('m1'), true);
  assert.equal(p.decide('m2'), true);
  assert.equal(p.decide('m3'), true);
  assert.equal(p.decide('m4'), false); // over budget
  c.set(61000);
  assert.equal(p.decide('m5'), true); // window rolled over
});

test('reset clears dedupe state', () => {
  const c = fixedClock();
  const p = new ScanPolicy({ dedupeWindowMs: 1500, maxScansPerMinute: 60 }, c.now);
  assert.equal(p.decide('hello'), true);
  p.reset();
  assert.equal(p.decide('hello'), true);
});
