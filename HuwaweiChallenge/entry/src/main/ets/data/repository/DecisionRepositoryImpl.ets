import { LayaRequest, LayaResponse } from '../../domain/model/Decision';
import { DecisionRepository } from '../../domain/repository/DecisionRepository';
import { AssetLoader } from '../assets/AssetLoader';
import { InferenceConfig } from '../config/InferenceConfig';
import { MindSporeLiteEngine } from '../datasource/MindSporeLiteEngine';

/**
 * On-device implementation of the `DecisionRepository` port.
 *
 * The only path is the local MindSpore Lite engine — there is no network backend
 * and **no heuristic fallback**. If the model is not bundled or fails to load,
 * the error propagates so the UI can say the model is unavailable, rather than
 * risking a false positive from a rule-based guess.
 */
export class DecisionRepositoryImpl implements DecisionRepository {
  private readonly engine: MindSporeLiteEngine;

  constructor(config: InferenceConfig, assets: AssetLoader, filesDir: string) {
    this.engine = new MindSporeLiteEngine(config, assets, filesDir);
  }

  async predict(request: LayaRequest): Promise<LayaResponse> {
    return this.engine.infer(request);
  }
}
