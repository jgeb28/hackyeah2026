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
 * Verdict policy. Laya's base checkpoint has an unreliable `noul` (risk) head
 * (see model card / our validation), so the verdict keys off the **category**
 * distribution: P(scam) + P(harassment), with misinformation as a secondary.
 */
const HARM_CRITICAL: number = 0.60;
const HARM_DANGEROUS: number = 0.40;
const MISINFO_DANGEROUS: number = 0.50;

/**
 * Analyse a message with Laya and turn its typed answers into a Guardian verdict.
 *
 * The questions come from `GuardianSchema` so the request and the on-device
 * graph share one definition. This is the only place where "model output"
 * becomes a product decision.
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
    for (const schema of GuardianSchema.QUESTIONS) {
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

    const risk: LayaAnswer | undefined = response.answers[GuardianSchema.RISK.key];
    const category: LayaAnswer | undefined = response.answers[GuardianSchema.CATEGORY.key];
    const urgency: LayaAnswer | undefined = response.answers[GuardianSchema.URGENCY.key];

    analysis.answers = [
      this.render('Risk', risk),
      this.render('Category', category),
      this.render('Urgency', urgency)
    ];

    const categoryName: string = category !== undefined ? category.choice : '';
    analysis.category = categoryName;
    analysis.confidence = category !== undefined ? category.confidence : 0;

    const probs: Record<string, number> = category !== undefined ? category.probabilities : {};
    const pScam: number = probs['scam'] !== undefined ? probs['scam'] : 0;
    const pHarassment: number = probs['harassment'] !== undefined ? probs['harassment'] : 0;
    const pMisinformation: number = probs['misinformation'] !== undefined ? probs['misinformation'] : 0;
    const harm: number = pScam + pHarassment;

    if (harm >= HARM_CRITICAL) {
      analysis.verdict = Verdict.CRITICAL;
      analysis.summary = 'High-confidence scam. Do not reply, click links or send money.';
    } else if (harm >= HARM_DANGEROUS || pMisinformation >= MISINFO_DANGEROUS) {
      analysis.verdict = Verdict.DANGEROUS;
      analysis.summary = 'This looks suspicious. Verify the sender through a channel you trust.';
    } else {
      analysis.verdict = Verdict.SAFE;
      analysis.summary = 'No strong scam signals, but stay cautious with links and payments.';
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
