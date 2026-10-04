import { LayaAnswer, LayaRequest, LayaResponse, QuestionType } from '../../domain/model/Decision';
import { DecisionRepository } from '../../domain/repository/DecisionRepository';
import { BackendSettings } from '../../dev/BackendSettings';
import { RemoteClient } from '../../dev/RemoteClient';

interface AnswerDto {
  kind?: string;
  choice?: string;
  score?: number;
  noul?: number;
  confidence?: number;
  probabilities?: Record<string, number>;
}

interface PredictResponseDto {
  model?: string;
  latencyMs?: number;
  answers?: Record<string, AnswerDto>;
}

/** Dev-only LAY A adapter: POSTs the state to the host dev server. */
export class RemoteDecisionRepository implements DecisionRepository {
  async predict(request: LayaRequest): Promise<LayaResponse> {
    const body: string = JSON.stringify({ state: request.state });
    const text: string = await RemoteClient.post(`${BackendSettings.baseUrl}/predict`, body, 'application/json');
    const dto: PredictResponseDto = JSON.parse(text) as PredictResponseDto;

    const response = new LayaResponse();
    response.model = dto.model !== undefined ? dto.model : 'laya-remote';
    response.latencyMs = dto.latencyMs !== undefined ? dto.latencyMs : 0;

    const answers: Record<string, AnswerDto> = dto.answers !== undefined ? dto.answers : {};
    const keys: string[] = Object.keys(answers);
    for (const key of keys) {
      const src: AnswerDto = answers[key];
      const answer = new LayaAnswer();
      answer.kind = src.kind !== undefined ? src.kind : QuestionType.NOUL;
      answer.choice = src.choice !== undefined ? src.choice : '';
      answer.score = src.score !== undefined ? src.score : 0;
      answer.noul = src.noul !== undefined ? src.noul : 0;
      answer.confidence = src.confidence !== undefined ? src.confidence : 0;
      answer.probabilities = src.probabilities !== undefined ? src.probabilities : {};
      response.answers[key] = answer;
    }
    return response;
  }
}
