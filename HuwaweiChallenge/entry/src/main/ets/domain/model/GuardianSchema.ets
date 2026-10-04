import { QuestionType } from './Decision';

/**
 * Guardian's label space, shared by:
 *   - `AnalyseMessageUseCase`   (builds the Laya questions)
 *   - `MindSporeLiteEngine`     (decodes the on-device graph output)
 *   - the converter (`tools/laya/convert_laya.py`) bakes the same questions in.
 *
 * Two questions:
 *   1. `deception` — a binary gate: is the text trying to deceive the reader?
 *   2. `incident`  — which known incident does it best match? Its options are the
 *      incident **ids** from `rawfile/kb/en/incidents.json`, in file order, with the
 *      option text = the incident `description`. Populated at runtime by
 *      `IncidentKb.load` via `setIncidentChoices` (the converter reads the same JSON).
 *
 * NOTE: the question order, option order and option count are baked into the
 * on-device `.ms`. Changing them requires re-exporting the model (root AGENTS §11).
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

  static readonly INCIDENT_KEY: string = 'incident';
  static readonly INCIDENT_INSTRUCTIONS: string =
    'Which of these known incidents best matches the text? Pick the closest match.';

  private static incidentLabels: string[] = [];
  private static incidentDescriptions: string[] = [];

  /** Called by `IncidentKb.load` once the incident JSON is parsed. Order = file order. */
  static setIncidentChoices(labels: string[], descriptions: string[]): void {
    GuardianSchema.incidentLabels = labels;
    GuardianSchema.incidentDescriptions = descriptions;
  }

  /** The current question set (order is part of the model contract). */
  static questions(): SchemaQuestion[] {
    const incident: SchemaQuestion = {
      key: GuardianSchema.INCIDENT_KEY,
      kind: QuestionType.CHOICE,
      instructions: GuardianSchema.INCIDENT_INSTRUCTIONS,
      labels: GuardianSchema.incidentLabels,
      descriptions: GuardianSchema.incidentDescriptions
    };
    return [GuardianSchema.DECEPTION, incident];
  }

  /** Padded option width the on-device graph uses (= max options across questions). */
  static maxOptions(): number {
    const a: number = GuardianSchema.DECEPTION.labels.length;
    const b: number = GuardianSchema.incidentLabels.length;
    return a > b ? a : b;
  }

  static indexOf(key: string): number {
    const qs: SchemaQuestion[] = GuardianSchema.questions();
    for (let i = 0; i < qs.length; i++) {
      if (qs[i].key === key) {
        return i;
      }
    }
    return -1;
  }
}
