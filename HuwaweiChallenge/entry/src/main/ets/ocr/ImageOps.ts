// Image preprocessing for PP-OCRv4 det/rec (platform-free, unit-testable).
// Channel order is BGR to match PaddleOCR; MindSpore Lite expects NHWC float32.

import { OcrPoint } from './OcrTypes';

export const DET_SIZE: number = 960;
export const REC_HEIGHT: number = 48;
export const REC_WIDTH: number = 960;

const DET_MEAN: number[] = [0.485, 0.456, 0.406];
const DET_STD: number[] = [0.229, 0.224, 0.225];

const SCRATCH = new Float32Array(3);

/** Bilinear sample of a packed BGR byte buffer. Returns a shared 3-float scratch. */
function sampleBgr(src: Uint8Array, w: number, h: number, fx: number, fy: number): Float32Array {
  let x0 = Math.floor(fx);
  let y0 = Math.floor(fy);
  const dx = fx - x0;
  const dy = fy - y0;
  let x1 = x0 + 1;
  let y1 = y0 + 1;
  if (x0 < 0) { x0 = 0; }
  if (y0 < 0) { y0 = 0; }
  if (x1 > w - 1) { x1 = w - 1; }
  if (y1 > h - 1) { y1 = h - 1; }
  if (x0 > w - 1) { x0 = w - 1; }
  if (y0 > h - 1) { y0 = h - 1; }
  const i00 = (y0 * w + x0) * 3;
  const i01 = (y0 * w + x1) * 3;
  const i10 = (y1 * w + x0) * 3;
  const i11 = (y1 * w + x1) * 3;
  for (let k = 0; k < 3; k++) {
    const v00 = src[i00 + k];
    const v01 = src[i01 + k];
    const v10 = src[i10 + k];
    const v11 = src[i11 + k];
    const top = v00 + (v01 - v00) * dx;
    const bot = v10 + (v11 - v10) * dx;
    SCRATCH[k] = top + (bot - top) * dy;
  }
  return SCRATCH;
}

/** Convert an RGBA_8888 buffer to packed BGR bytes. */
export function rgbaToBgr(rgba: Uint8Array, w: number, h: number): Uint8Array {
  const n = w * h;
  const out = new Uint8Array(n * 3);
  for (let i = 0; i < n; i++) {
    const s = i * 4;
    const d = i * 3;
    out[d] = rgba[s + 2];
    out[d + 1] = rgba[s + 1];
    out[d + 2] = rgba[s];
  }
  return out;
}

export interface DetInput {
  data: Float32Array;
  scale: number;
  width: number;
  height: number;
}

/** Aspect-fit to 960x960, top-left aligned, ImageNet-normalized, NHWC [1,960,960,3]. */
export function detPreprocess(bgr: Uint8Array, w: number, h: number): DetInput {
  const scale = DET_SIZE / Math.max(w, h);
  const nw = Math.max(1, Math.round(w * scale));
  const nh = Math.max(1, Math.round(h * scale));
  const out = new Float32Array(DET_SIZE * DET_SIZE * 3);
  for (let y = 0; y < nh; y++) {
    const fy = (y + 0.5) / scale - 0.5;
    for (let x = 0; x < nw; x++) {
      const fx = (x + 0.5) / scale - 0.5;
      const c = sampleBgr(bgr, w, h, fx, fy);
      const o = (y * DET_SIZE + x) * 3;
      out[o] = (c[0] / 255 - DET_MEAN[0]) / DET_STD[0];
      out[o + 1] = (c[1] / 255 - DET_MEAN[1]) / DET_STD[1];
      out[o + 2] = (c[2] / 255 - DET_MEAN[2]) / DET_STD[2];
    }
  }
  return { data: out, scale, width: nw, height: nh };
}

export interface Crop {
  data: Uint8Array;
  width: number;
  height: number;
}

/** Affine (rotation-aware) crop of a detected quad to an upright BGR image. */
export function affineCrop(bgr: Uint8Array, w: number, h: number, pts: OcrPoint[]): Crop {
  const p = orderPointsClockwise(pts);
  const tl = p[0];
  const tr = p[1];
  const bl = p[3];
  const outW = Math.max(1, Math.round(Math.max(dist(tl, tr), dist(p[2], p[3]))));
  const outH = Math.max(1, Math.round(Math.max(dist(tl, bl), dist(tr, p[2]))));
  const m00 = (tr.x - tl.x) / outW;
  const m10 = (tr.y - tl.y) / outW;
  const m01 = (bl.x - tl.x) / outH;
  const m11 = (bl.y - tl.y) / outH;
  const out = new Uint8Array(outW * outH * 3);
  for (let y = 0; y < outH; y++) {
    for (let x = 0; x < outW; x++) {
      const sx = m00 * x + m01 * y + tl.x;
      const sy = m10 * x + m11 * y + tl.y;
      const c = sampleBgr(bgr, w, h, sx, sy);
      const o = (y * outW + x) * 3;
      out[o] = c[0];
      out[o + 1] = c[1];
      out[o + 2] = c[2];
    }
  }
  return { data: out, width: outW, height: outH };
}

/** Resize a BGR crop to height 48, left-pad to 960, mean/std 0.5, NHWC [1,48,960,3]. */
export function recPreprocess(crop: Crop): Float32Array {
  const ratio = crop.width / Math.max(crop.height, 1);
  const nw = Math.min(Math.max(Math.round(REC_HEIGHT * ratio), 1), REC_WIDTH);
  const out = new Float32Array(REC_WIDTH * REC_HEIGHT * 3);
  for (let y = 0; y < REC_HEIGHT; y++) {
    const fy = ((y + 0.5) * crop.height) / REC_HEIGHT - 0.5;
    for (let x = 0; x < nw; x++) {
      const fx = ((x + 0.5) * crop.width) / nw - 0.5;
      const c = sampleBgr(crop.data, crop.width, crop.height, fx, fy);
      const o = (y * REC_WIDTH + x) * 3;
      out[o] = (c[0] / 255 - 0.5) / 0.5;
      out[o + 1] = (c[1] / 255 - 0.5) / 0.5;
      out[o + 2] = (c[2] / 255 - 0.5) / 0.5;
    }
  }
  return out;
}

/** Order four points as top-left, top-right, bottom-right, bottom-left. */
export function orderPointsClockwise(pts: OcrPoint[]): OcrPoint[] {
  const sorted = pts.slice().sort((a, b) => a.x - b.x);
  const left = sorted.slice(0, 2).sort((a, b) => a.y - b.y);
  const right = sorted.slice(2, 4).sort((a, b) => a.y - b.y);
  return [left[0], right[0], right[1], left[1]];
}

function dist(a: OcrPoint, b: OcrPoint): number {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}
