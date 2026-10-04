// Shared OCR types (platform-free, unit-testable).

export interface OcrPoint {
  x: number;
  y: number;
}

/** A detection quad, ordered clockwise from the top-left corner. */
export interface OcrBox {
  points: OcrPoint[];
}

export interface OcrLine {
  text: string;
  confidence: number;
  box: OcrBox;
}

export interface OcrResult {
  /** Recognized lines joined with '\n'. */
  text: string;
  lines: OcrLine[];
}

export interface DetRect {
  center: OcrPoint;
  width: number;
  height: number;
  /** Radians, rotation of the rectangle. */
  angle: number;
}

/** A rectangle in source-image pixels, used to exclude system/app chrome regions. */
export interface RectPx {
  left: number;
  top: number;
  width: number;
  height: number;
}
