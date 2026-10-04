import {
  ChoiceQuestion,
  DecisionAnswer,
  LayaAnswer,
  LayaQuestion,
  LayaRequest,
  LayaResponse,
  MessageAnalysis,
  NoulQuestion,
  QuestionType,
  ScoreQuestion,
  Verdict
} from '../model/Decision';
import { GuardianSchema, SchemaQuestion } from '../model/GuardianSchema';
import { DecisionRepository } from '../repository/DecisionRepository';

/**
 * Verdict policy: the gate is the `deception` choice (P(deceptive)). The `incident`
 * answer only selects which KB case is shown (its head is noisy, so it never decides
 * the verdict).
 *
 * Thresholds are calibrated against the fine-tuned LAY A head (DIFrauD + UI
 * augmentation; 5-fold cross-validation, temperature scaling baked into the `.ms`).
 * At the DANGEROUS point: FNR ~7% / FPR ~27% on the held-out test set; CRITICAL is
 * the high-confidence tier. See `DATA_SCIENCE.md`.
 */
const DECEPTIVE_DANGEROUS: number = 0.25;
const DECEPTIVE_CRITICAL: number = 0.55;

/**
 * Analyse on-screen text with Laya and turn its typed answers into a Guardian
 * verdict. The questions come from `GuardianSchema` so the request and the
 * on-device graph share one definition.
 */
export class AnalyseMessageUseCase {
  private readonly repository: DecisionRepository;

  constructor(repository: DecisionRepository) {
    this.repository = repository;
  }

  async run(message: string): Promise<MessageAnalysis> {
    const request: LayaRequest = {
      state: message,
      questions: this.buildQuestions()
    };
    const response: LayaResponse = await this.repository.predict(request);
    return this.toAnalysis(response);
  }

  private buildQuestions(): Record<string, LayaQuestion> {
    const questions: Record<string, LayaQuestion> = {};
    for (const schema of GuardianSchema.questions()) {
      questions[schema.key] = this.toQuestion(schema);
    }
    return questions;
  }

  private toQuestion(schema: SchemaQuestion): LayaQuestion {
    if (schema.kind === QuestionType.CHOICE) {
      const criteria: Record<string, string> = {};
      for (let i = 0; i < schema.labels.length; i++) {
        const description: string = i < schema.descriptions.length ? schema.descriptions[i] : '';
        criteria[schema.labels[i]] = description;
      }
      const choice: ChoiceQuestion = {
        type: QuestionType.CHOICE,
        instructions: schema.instructions,
        criteria: criteria
      };
      return choice;
    }
    if (schema.kind === QuestionType.SCORE) {
      const score: ScoreQuestion = {
        type: QuestionType.SCORE,
        instructions: schema.instructions,
        criteria: schema.labels
      };
      return score;
    }
    const noul: NoulQuestion = {
      type: QuestionType.NOUL,
      instructions: schema.instructions
    };
    return noul;
  }

  private toAnalysis(response: LayaResponse): MessageAnalysis {
    const analysis = new MessageAnalysis();
    analysis.model = response.model;
    analysis.latencyMs = response.latencyMs;

    const deception: LayaAnswer | undefined = response.answers[GuardianSchema.DECEPTION.key];
    const incident: LayaAnswer | undefined = response.answers[GuardianSchema.INCIDENT_KEY];

    analysis.answers = [
      this.render('Deception', deception),
      this.render('Incident', incident)
    ];
    analysis.incidentId = incident !== undefined ? incident.choice : '';
    analysis.category = '';

    const probs: Record<string, number> = deception !== undefined ? deception.probabilities : {};
    const pDeceptive: number = probs['deceptive'] !== undefined ? probs['deceptive'] : 0;
    analysis.confidence = deception !== undefined ? deception.confidence : 0;

    if (pDeceptive >= DECEPTIVE_CRITICAL) {
      analysis.verdict = Verdict.CRITICAL;
      analysis.summary = 'High-confidence deception. Do not reply, click links or send money.';
    } else if (pDeceptive >= DECEPTIVE_DANGEROUS) {
      analysis.verdict = Verdict.DANGEROUS;
      analysis.summary = 'This text looks deceptive. Verify through a channel you trust.';
    } else {
      analysis.verdict = Verdict.SAFE;
      analysis.summary = 'No deception detected, but stay cautious with links and payments.';
    }

    return analysis;
  }

  private render(label: string, answer: LayaAnswer | undefined): DecisionAnswer {
    const line = new DecisionAnswer();
    line.label = label;
    if (answer === undefined) {
      line.value = 'no answer';
      return line;
    }

    line.confidence = answer.confidence;
    if (answer.kind === QuestionType.NOUL) {
      line.value = `${(answer.noul * 100).toFixed(0)}% likely`;
    } else if (answer.kind === QuestionType.SCORE) {
      line.value = answer.score.toFixed(2);
    } else {
      line.value = answer.choice;
    }
    line.breakdown = this.formatBreakdown(answer.probabilities);
    return line;
  }

  private formatBreakdown(probabilities: Record<string, number>): string {
    const keys: string[] = Object.keys(probabilities);
    const parts: string[] = [];
    for (const key of keys) {
      parts.push(`${key} ${(probabilities[key] * 100).toFixed(0)}%`);
    }
    return parts.join('   ');
  }
}
