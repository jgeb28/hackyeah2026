import { OcrEngine, ScreenOcrEngine } from '../vision/OcrEngine';
import { RemoteOcrEngine } from '../vision/RemoteOcrEngine';
import { DecisionRepository } from '../domain/repository/DecisionRepository';
import { DecisionRepositoryImpl } from '../data/repository/DecisionRepositoryImpl';
import { RemoteDecisionRepository } from '../data/datasource/RemoteDecisionRepository';
import { InferenceConfig } from '../data/config/InferenceConfig';
import { AssetLoader } from '../data/assets/AssetLoader';
import { BackendSettings } from './BackendSettings';

/** Dev switch: on-device (default) or the host dev server. */

export function createOcrEngine(): OcrEngine {
  return BackendSettings.isRemote ? new RemoteOcrEngine() : new ScreenOcrEngine();
}

export function createDecisionRepository(config: InferenceConfig, assets: AssetLoader,
  filesDir: string): DecisionRepository {
  return BackendSettings.isRemote
    ? new RemoteDecisionRepository()
    : new DecisionRepositoryImpl(config, assets, filesDir);
}
