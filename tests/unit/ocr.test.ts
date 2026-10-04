import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadChars, ctcDecode } from '../../HuaweiChallenge/entry/src/main/ets/ocr/CtcDecode';
import { findDetBoxes, sortBoxes } from '../../HuaweiChallenge/entry/src/main/ets/ocr/DbPostprocess';
import { orderPointsClockwise } from '../../HuaweiChallenge/entry/src/main/ets/ocr/ImageOps';

test('loadChars matches PaddleOCR CTC layout (blank + keys + space)', () => {
  const chars = loadChars('a\nb\nc');
  assert.deepEqual(chars, ['blank', 'a', 'b', 'c', ' ']);
});

test('ctcDecode collapses repeats and drops blanks', () => {
  const chars = ['blank', 'A', 'B'];
  // T=5, C=3: blank, A, A, B, blank -> "AB"
  const probs = new Float32Array([
    0.9, 0.05, 0.05,
    0.1, 0.8, 0.1,
    0.1, 0.7, 0.2,
    0.1, 0.2, 0.7,
    0.9, 0.05, 0.05
  ]);
  const out = ctcDecode(probs, 5, 3, chars);
  assert.equal(out.text, 'AB');
  assert.ok(out.confidence > 0.7);
});

test('findDetBoxes finds one quad for a solid rectangle', () => {
  const w = 64;
  const h = 64;
  const prob = new Float32Array(w * h);
  for (let y = 20; y < 28; y++) {
    for (let x = 10; x < 30; x++) {
      prob[y * w + x] = 0.9;
    }
  }
  const boxes = findDetBoxes(prob, w, h, 1.0);
  assert.equal(boxes.length, 1);
  let cx = 0;
  let cy = 0;
  for (const p of boxes[0].points) {
    cx += p.x;
    cy += p.y;
  }
  cx /= 4;
  cy /= 4;
  assert.ok(cx > 16 && cx < 24, `cx=${cx}`);
  assert.ok(cy > 20 && cy < 28, `cy=${cy}`);
});

test('findDetBoxes ignores low-confidence blobs', () => {
  const w = 64;
  const h = 64;
  const prob = new Float32Array(w * h);
  for (let y = 20; y < 28; y++) {
    for (let x = 10; x < 30; x++) {
      prob[y * w + x] = 0.4; // above threshold, below box threshold
    }
  }
  assert.equal(findDetBoxes(prob, w, h, 1.0).length, 0);
});

test('sortBoxes orders rows top-to-bottom then left-to-right', () => {
  const box = (x: number, y: number) => ({ points: [{ x, y }, { x: x + 2, y }, { x: x + 2, y: y + 2 }, { x, y: y + 2 }] });
  const sorted = sortBoxes([box(100, 50), box(10, 12), box(60, 50)]);
  assert.deepEqual(sorted.map((b) => b.points[0].x), [10, 60, 100]);
});

test('orderPointsClockwise returns tl,tr,br,bl', () => {
  const pts = [{ x: 10, y: 20 }, { x: 0, y: 0 }, { x: 10, y: 0 }, { x: 0, y: 20 }];
  const ordered = orderPointsClockwise(pts);
  assert.deepEqual(ordered, [{ x: 0, y: 0 }, { x: 10, y: 0 }, { x: 10, y: 20 }, { x: 0, y: 20 }]);
});
