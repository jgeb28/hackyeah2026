import { QuestionType } from './Decision';

/**
 * Guardian's fixed label space, expressed once and shared by:
 *   - `AnalyseMessageUseCase`   (builds the Laya questions)
 *   - `MindSporeLiteEngine`     (decodes the on-device graph output)
 *
 * The text is treated as **any on-screen content**, not necessarily a message.
 * Two questions only:
 *   1. `deception` — a binary gate: is the text trying to deceive the reader?
 *   2. `category`  — if it is, which kind of deceptive content is it?
 *
 * NOTE: the number/order/labels are baked into the on-device `.ms` by
 * `tools/laya/convert_laya.py`. Changing this file requires re-exporting the
 * on-device model before a push (see root AGENTS.md "dev remote parity" rule).
 */
export interface SchemaQuestion {
  key: string;
  kind: string;
  instructions: string;
  /** Option labels in scoring order. */
  labels: string[];
  /** Optional human descriptions for `choice` options (parallel to labels). */
  descriptions: string[];
}

export class GuardianSchema {
  /** Primary gate: is this text trying to deceive the reader? (choice) */
  static readonly DECEPTION: SchemaQuestion = {
    key: 'deception',
    kind: QuestionType.CHOICE,
    instructions: 'Does this text try to deceive the reader — for example by impersonating ' +
      'someone, inventing urgency or a threat, or asking for money, credentials or personal data?',
    labels: ['safe', 'deceptive'],
    descriptions: [
      'the text is not trying to deceive the reader',
      'the text tries to deceive the reader'
    ]
  };

  /** Which kind of deceptive text it is (only meaningful when DECEPTION = deceptive). */
  static readonly CATEGORY: SchemaQuestion = {
    key: 'category',
    kind: QuestionType.CHOICE,
    instructions: 'What kind of deceptive text is this?',
    labels: ['scam', 'misinformation', 'harassment'],
    descriptions: [
      'fraud, phishing, or a request for money or credentials',
      'a false or unverified alarming claim meant to mislead',
      'abuse, threats or coercion'
    ]
  };

  /** Order is part of the model contract — do not reorder without re-exporting. */
  static readonly QUESTIONS: SchemaQuestion[] = [
    GuardianSchema.DECEPTION,
    GuardianSchema.CATEGORY
  ];

  /** Width of the padded option axis in the on-device graph output. */
  static readonly MAX_OPTIONS: number = 5;

  static indexOf(key: string): number {
    for (let i = 0; i < GuardianSchema.QUESTIONS.length; i++) {
      if (GuardianSchema.QUESTIONS[i].key === key) {
        return i;
      }
    }
    return -1;
  }
}
