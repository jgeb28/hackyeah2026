import { QuestionType } from './Decision';

/**
 * Guardian's fixed label space, expressed once and shared by:
 *   - `AnalyseMessageUseCase`   (builds the Laya questions)
 *   - `MindSporeLiteEngine`     (decodes the on-device graph output)
 *
 * The on-device `.ms` graph is exported with exactly this question order and
 * option layout, so the two sides can never drift. `MAX_OPTIONS` is the padding
 * width of the graph's probability output.
 */
export interface SchemaQuestion {
  key: string;
  kind: string;
  instructions: string;
  /** Option labels in scoring order. `noul` is always ['false', 'true']. */
  labels: string[];
  /** Optional human descriptions for `choice` options (parallel to labels). */
  descriptions: string[];
}

export class GuardianSchema {
  static readonly RISK: SchemaQuestion = {
    key: 'risk',
    kind: QuestionType.NOUL,
    instructions: 'Does this message try to obtain money, credentials or personal ' +
      'data, or pressure the reader into an unsafe action?',
    labels: ['false', 'true'],
    descriptions: []
  };

  static readonly CATEGORY: SchemaQuestion = {
    key: 'category',
    kind: QuestionType.CHOICE,
    instructions: 'What kind of message is this?',
    labels: ['scam', 'misinformation', 'harassment', 'marketing', 'legitimate'],
    descriptions: [
      'fraud, phishing, or a request for money/credentials',
      'a false or unverified alarming claim',
      'abuse, threats or coercion',
      'an advertisement or promotion',
      'a normal personal or business message'
    ]
  };

  static readonly URGENCY: SchemaQuestion = {
    key: 'urgency',
    kind: QuestionType.SCORE,
    instructions: 'How much time pressure does the message apply?',
    labels: ['none', 'some pressure', 'critical deadline or threat'],
    descriptions: []
  };

  /** Order is part of the model contract — do not reorder without re-exporting. */
  static readonly QUESTIONS: SchemaQuestion[] = [
    GuardianSchema.RISK,
    GuardianSchema.CATEGORY,
    GuardianSchema.URGENCY
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
