/**
 * Domain model — Laya typed decisions (pure data + policy, no UI, no transport).
 *
 * Laya (https://huggingface.co/convaiinnovations/laya) is a non-autoregressive
 * "System 1" decision model: you give it a **state** (text/JSON) and a set of
 * **typed questions**, and it returns typed answers with calibrated
 * probabilities in one forward pass. The three primitives are:
 *
 *   choice -> "which of these options?"      (exactly one option)
 *   score  -> "where on this rubric?"        (a position along ordered levels)
 *   noul   -> "is this statement true?"      (probability in [0,1])
 *
 * Everything below is deliberately free of any knowledge about *how* the model
 * is reached (HTTP Space, on-device MindSpore Lite, a mock) — that is the job of
 * the data layer. The presentation layer only ever sees `MessageAnalysis`.
 */

/** Laya question primitives. Kept as strings so they serialise 1:1 to the API. */
export class QuestionType {
  static readonly CHOICE: string = 'choice';
  static readonly SCORE: string = 'score';
  static readonly NOUL: string = 'noul';
}

/** "Pick one of these options", e.g. the message category. */
export interface ChoiceQuestion {
  type: string;
  instructions: string;
  criteria: Record<string, string>;
}

/** "Where on this ordered rubric?", e.g. urgency. */
export interface ScoreQuestion {
  type: string;
  instructions: string;
  criteria: string[];
}

/** "Is this true?", answered as a probability in [0,1]. */
export interface NoulQuestion {
  type: string;
  instructions: string;
}

export type LayaQuestion = ChoiceQuestion | ScoreQuestion | NoulQuestion;

/** A single decision request: one state, many questions, one forward pass. */
export interface LayaRequest {
  state: string;
  questions: Record<string, LayaQuestion>;
}

/** One typed answer as returned by Laya (transport-independent domain shape). */
export class LayaAnswer {
  /** QuestionType.* — which primitive produced this answer. */
  kind: string = QuestionType.NOUL;
  /** Set for `choice` answers. */
  choice: string = '';
  /** Set for `score` answers. */
  score: number = 0;
  /** Set for `noul` answers: probability the statement is true. */
  noul: number = 0;
  /** Model confidence in the chosen answer, [0,1]. */
  confidence: number = 0;
  /** Probability mass per option / rubric level / label. */
  probabilities: Record<string, number> = {};
}

/** The full model response for one `LayaRequest`. */
export class LayaResponse {
  model: string = 'laya';
  answers: Record<string, LayaAnswer> = {};
  latencyMs: number = 0;
}

/** Guardian verdict levels (see DESIGN.md §2). */
export class Verdict {
  static readonly SAFE: string = 'SAFE';
  static readonly DANGEROUS: string = 'DANGEROUS';
  static readonly CRITICAL: string = 'CRITICAL';
  static readonly UNKNOWN: string = 'UNKNOWN';
}

/** One rendered answer line for the UI. */
export class DecisionAnswer {
  label: string = '';
  value: string = '';
  confidence: number = 0;
  /** Human-readable probability breakdown, e.g. "scam 95%  marketing 3%". */
  breakdown: string = '';
}

/** The user-facing result of analysing one message. */
export class MessageAnalysis {
  verdict: string = Verdict.UNKNOWN;
  category: string = '';
  summary: string = '';
  confidence: number = 0;
  latencyMs: number = 0;
  model: string = 'laya';
  answers: DecisionAnswer[] = [];
}
