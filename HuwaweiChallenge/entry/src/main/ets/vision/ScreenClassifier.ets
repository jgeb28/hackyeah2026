// Length-based placeholder classifier until the validation model is added.
import { ScanResult, Verdict } from '../trigger/TriggerTypes';

const SHORT_MAX: number = 50;
const MEDIUM_MAX: number = 100;

function rank(severity: string | undefined): number {
  if (severity === 'CRITICAL') {
    return 3;
  }
  if (severity === 'WARNING') {
    return 2;
  }
  return 1;
}

export class ScreenClassifier {
  /** Severity from the message length (placeholder for the on-device model). */
  static classifyOne(text: string): ScanResult {
    const length: number = text.trim().length;
    if (length >= MEDIUM_MAX) {
      return { verdict: Verdict.CRITICAL, category: 'scam', confidence: 0.9, signals: [], severity: 'CRITICAL' };
    }
    if (length >= SHORT_MAX) {
      return { verdict: Verdict.DANGEROUS, category: 'misinformation', confidence: 0.6, signals: [], severity: 'WARNING' };
    }
    return { verdict: Verdict.SAFE, category: 'none', confidence: 0.2, signals: [], severity: 'INFO' };
  }

  /** Classify each message and keep the most severe assessment. */
  static strongest(text: string): ScanResult | null {
    const lines: string[] = text.split('\n');
    let best: ScanResult | null = null;
    for (const raw of lines) {
      const line: string = raw.trim();
      if (line.length === 0) {
        continue;
      }
      const result: ScanResult = ScreenClassifier.classifyOne(line);
      if (best === null || rank(result.severity) > rank(best.severity)) {
        best = result;
      }
    }
    return best;
  }
}
