/**
 * classifyText — deterministic scam/misinformation rules over the label space
 * (DESIGN.md §7 step 1). Model-agnostic: LAYA (.ms) drops in behind the same
 * `classifyText(text) -> ScanResult` seam later.
 */
import { ScanResult, Verdict } from './TriggerTypes';

/** Pure classifier. No platform imports, so it is unit-testable on Node. */
export function classifyText(text: string): ScanResult {
  const t: string = text.toLowerCase();
  const signals: string[] = [];

  // Impersonation / claimed identity.
  if (t.includes("it's me") || t.includes('its me') || t.includes('this is your') ||
    t.includes("friend's number") || t.includes('new number')) {
    signals.push('claims to be someone you know');
  }
  // Urgency / pressure to act.
  if (t.includes('right now') || t.includes('today') || t.includes('urgent') ||
    t.includes('asap') || t.includes('immediately') || t.includes('before ') ||
    t.includes("don't call") || t.includes('do not call')) {
    signals.push('urgent / pressure to act');
  }
  // Unusual payment rails.
  if (t.includes('send') || t.includes('pay') || t.includes('transfer') ||
    t.includes('\u20AC') || t.includes('$') || t.includes('account details') ||
    t.includes('gift card') || t.includes('crypto')) {
    signals.push('unusual payment request');
  }
  // Isolation / secrecy.
  if (t.includes("don't tell") || t.includes('do not tell') || t.includes('keep this') ||
    t.includes('between us')) {
    signals.push('asks for secrecy / isolation');
  }

  // Tunable thresholds: 0 -> SAFE, 1 -> DANGEROUS, >=2 -> CRITICAL.
  if (signals.length >= 2) {
    return { verdict: Verdict.CRITICAL, category: 'scam', confidence: 0.9, signals };
  }
  if (signals.length === 1) {
    return { verdict: Verdict.DANGEROUS, category: 'phishing', confidence: 0.6, signals };
  }
  return { verdict: Verdict.SAFE, category: 'none', confidence: 0, signals };
}
