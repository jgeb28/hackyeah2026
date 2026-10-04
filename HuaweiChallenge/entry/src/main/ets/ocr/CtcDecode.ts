// CTC greedy decode for PP-OCRv4 recognition (platform-free, unit-testable).

export interface DecodeResult {
  text: string;
  confidence: number;
}

/**
 * Build the CTC class table from the PaddleOCR dictionary file.
 * Layout matches PaddleOCR: index 0 = blank, then the file's characters,
 * then a trailing space (use_space_char).
 */
export function loadChars(dictText: string): string[] {
  const lines: string[] = dictText.split('\n');
  while (lines.length > 0 && lines[lines.length - 1] === '') {
    lines.pop();
  }
  const chars: string[] = ['blank'];
  for (const line of lines) {
    chars.push(line.replace('\r', ''));
  }
  chars.push(' ');
  return chars;
}

/**
 * Greedy CTC decode of a [T, C] probability matrix (row-major).
 * Collapses repeats and drops the blank class.
 */
export function ctcDecode(probs: Float32Array, t: number, c: number, chars: string[]): DecodeResult {
  const out: string[] = [];
  let sum = 0;
  let count = 0;
  let prev = -1;

  for (let i = 0; i < t; i++) {
    const base = i * c;
    let best = 0;
    let bestVal = probs[base];
    for (let j = 1; j < c; j++) {
      const v = probs[base + j];
      if (v > bestVal) {
        bestVal = v;
        best = j;
      }
    }
    if (best !== 0 && best !== prev) {
      const ch = chars[best];
      if (ch !== undefined && ch !== 'blank') {
        out.push(ch);
        sum += bestVal;
        count++;
      }
    }
    prev = best;
  }

  return {
    text: out.join(''),
    confidence: count > 0 ? sum / count : 0
  };
}
