// PP-OCRv4 DB detection post-processing (platform-free, unit-testable).
// Connected-component labelling + min-area rectangle + a rect-expansion
// approximation of PaddleOCR's polygon unclip (no OpenCV/pyclipper on device).

import { DetRect, OcrBox, OcrPoint } from './OcrTypes';

export interface DetConfig {
  thresh: number;
  boxThresh: number;
  unclipRatio: number;
  minSize: number;
}

export const DEFAULT_DET_CONFIG: DetConfig = {
  thresh: 0.3,
  boxThresh: 0.6,
  unclipRatio: 1.5,
  minSize: 3
};

interface Component {
  members: number[];
}

/** 8-connected components of the pixels where prob > thresh. */
function labelComponents(prob: Float32Array, w: number, h: number, thresh: number): Component[] {
  const visited = new Uint8Array(w * h);
  const stack = new Int32Array(w * h);
  const comps: Component[] = [];
  const n = w * h;

  for (let seed = 0; seed < n; seed++) {
    if (visited[seed] === 1 || prob[seed] <= thresh) {
      continue;
    }
    let sp = 0;
    stack[sp++] = seed;
    visited[seed] = 1;
    const members: number[] = [];
    while (sp > 0) {
      const idx = stack[--sp];
      members.push(idx);
      const x = idx % w;
      const y = (idx - x) / w;
      for (let dy = -1; dy <= 1; dy++) {
        const ny = y + dy;
        if (ny < 0 || ny >= h) {
          continue;
        }
        for (let dx = -1; dx <= 1; dx++) {
          const nx = x + dx;
          if (nx < 0 || nx >= w || (dx === 0 && dy === 0)) {
            continue;
          }
          const ni = ny * w + nx;
          if (visited[ni] === 0 && prob[ni] > thresh) {
            visited[ni] = 1;
            stack[sp++] = ni;
          }
        }
      }
    }
    comps.push({ members });
  }
  return comps;
}

function cross(o: OcrPoint, a: OcrPoint, b: OcrPoint): number {
  return (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x);
}

/** Andrew monotone chain convex hull. */
export function convexHull(pts: OcrPoint[]): OcrPoint[] {
  if (pts.length < 3) {
    return pts.slice();
  }
  const p = pts.slice().sort((a, b) => (a.x - b.x) || (a.y - b.y));
  const lower: OcrPoint[] = [];
  for (const pt of p) {
    while (lower.length >= 2 && cross(lower[lower.length - 2], lower[lower.length - 1], pt) <= 0) {
      lower.pop();
    }
    lower.push(pt);
  }
  const upper: OcrPoint[] = [];
  for (let i = p.length - 1; i >= 0; i--) {
    const pt = p[i];
    while (upper.length >= 2 && cross(upper[upper.length - 2], upper[upper.length - 1], pt) <= 0) {
      upper.pop();
    }
    upper.push(pt);
  }
  lower.pop();
  upper.pop();
  return lower.concat(upper);
}

function axisAligned(pts: OcrPoint[]): DetRect {
  let minX = Infinity;
  let maxX = -Infinity;
  let minY = Infinity;
  let maxY = -Infinity;
  for (const p of pts) {
    if (p.x < minX) { minX = p.x; }
    if (p.x > maxX) { maxX = p.x; }
    if (p.y < minY) { minY = p.y; }
    if (p.y > maxY) { maxY = p.y; }
  }
  return {
    center: { x: (minX + maxX) / 2, y: (minY + maxY) / 2 },
    width: maxX - minX,
    height: maxY - minY,
    angle: 0
  };
}

/** Minimum-area enclosing rectangle via rotating calipers over the convex hull. */
export function minAreaRect(pts: OcrPoint[]): DetRect {
  const hull = convexHull(pts);
  if (hull.length < 3) {
    return axisAligned(hull.length > 0 ? hull : pts);
  }
  let bestArea = Infinity;
  let best: DetRect = axisAligned(hull);
  const n = hull.length;
  for (let i = 0; i < n; i++) {
    const a = hull[i];
    const b = hull[(i + 1) % n];
    const ang = Math.atan2(b.y - a.y, b.x - a.x);
    const ca = Math.cos(ang);
    const sa = Math.sin(ang);
    let minX = Infinity;
    let maxX = -Infinity;
    let minY = Infinity;
    let maxY = -Infinity;
    for (const p of hull) {
      const rx = p.x * ca + p.y * sa;
      const ry = -p.x * sa + p.y * ca;
      if (rx < minX) { minX = rx; }
      if (rx > maxX) { maxX = rx; }
      if (ry < minY) { minY = ry; }
      if (ry > maxY) { maxY = ry; }
    }
    const w = maxX - minX;
    const h = maxY - minY;
    const area = w * h;
    if (area < bestArea) {
      bestArea = area;
      const cx = (minX + maxX) / 2;
      const cy = (minY + maxY) / 2;
      best = {
        center: { x: cx * ca - cy * sa, y: cx * sa + cy * ca },
        width: w,
        height: h,
        angle: ang
      };
    }
  }
  return best;
}

/** Four corners of a (possibly rotated) rectangle, clockwise from top-left-ish. */
export function rectCorners(rect: DetRect): OcrPoint[] {
  const ca = Math.cos(rect.angle);
  const sa = Math.sin(rect.angle);
  const hw = rect.width / 2;
  const hh = rect.height / 2;
  const ux = ca * hw;
  const uy = sa * hw;
  const vx = -sa * hh;
  const vy = ca * hh;
  const c = rect.center;
  return [
    { x: c.x - ux - vx, y: c.y - uy - vy },
    { x: c.x + ux - vx, y: c.y + uy - vy },
    { x: c.x + ux + vx, y: c.y + uy + vy },
    { x: c.x - ux + vx, y: c.y - uy + vy }
  ];
}

/**
 * Detect text quads. `prob` is the raw [h,w] probability map of the 960x960
 * detection input; `scale` maps that input back to the source image.
 */
export function findDetBoxes(
  prob: Float32Array,
  w: number,
  h: number,
  scale: number,
  cfg: DetConfig = DEFAULT_DET_CONFIG
): OcrBox[] {
  const comps = labelComponents(prob, w, h, cfg.thresh);
  const boxes: OcrBox[] = [];
  for (const comp of comps) {
    if (comp.members.length < 4) {
      continue;
    }
    const pts: OcrPoint[] = [];
    let score = 0;
    for (const idx of comp.members) {
      const x = idx % w;
      pts.push({ x, y: (idx - x) / w });
      score += prob[idx];
    }
    score /= comp.members.length;
    if (score < cfg.boxThresh) {
      continue;
    }
    const rect = minAreaRect(pts);
    if (Math.min(rect.width, rect.height) < cfg.minSize) {
      continue;
    }
    const delta = (rect.width * rect.height * cfg.unclipRatio) / (2 * (rect.width + rect.height));
    const ew = rect.width + 2 * delta;
    const eh = rect.height + 2 * delta;
    if (Math.min(ew, eh) < cfg.minSize + 2) {
      continue;
    }
    const corners = rectCorners({ center: rect.center, width: ew, height: eh, angle: rect.angle });
    const mapped: OcrPoint[] = [];
    for (const p of corners) {
      mapped.push({ x: p.x / scale, y: p.y / scale });
    }
    boxes.push({ points: mapped });
  }
  return boxes;
}

/** Sort top-to-bottom, then left-to-right (rows bucketed to 10 px). */
export function sortBoxes(boxes: OcrBox[]): OcrBox[] {
  const decorated = boxes.map((b) => {
    let minX = Infinity;
    let minY = Infinity;
    for (const p of b.points) {
      if (p.x < minX) { minX = p.x; }
      if (p.y < minY) { minY = p.y; }
    }
    return { b, minX, minY };
  });
  decorated.sort((a, b) => (Math.round(a.minY / 10) - Math.round(b.minY / 10)) || (a.minX - b.minX));
  return decorated.map((d) => d.b);
}
