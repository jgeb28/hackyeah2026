import { resourceManager } from '@kit.LocalizationKit';
import { RawfileAssetLoader } from '../data/assets/AssetLoader';
import { InferenceConfig } from '../data/config/InferenceConfig';
import { AccelerationInfo, NnrtAccelerationProbe } from '../data/datasource/NnrtAccelerationProbe';
import { DecisionRepositoryImpl } from '../data/repository/DecisionRepositoryImpl';
import { DecisionRepository } from '../domain/repository/DecisionRepository';
import { AnalyseMessageUseCase } from '../domain/usecase/AnalyseMessageUseCase';

/**
 * Composition root — the only place concrete data-layer classes are chosen.
 *
 * Everything here is local: the repository runs the MindSpore Lite `.ms` graph on
 * the device. There is no network adapter and no heuristic fallback.
 */
export class AppContainer {
  readonly config: InferenceConfig;
  readonly analyseMessage: AnalyseMessageUseCase;
  readonly accelerationProbe: NnrtAccelerationProbe;

  constructor(manager: resourceManager.ResourceManager) {
    this.config = new InferenceConfig();
    this.accelerationProbe = new NnrtAccelerationProbe();

    const assets = new RawfileAssetLoader(manager);
    const repository: DecisionRepository = new DecisionRepositoryImpl(this.config, assets);
    this.analyseMessage = new AnalyseMessageUseCase(repository);
  }

  acceleration(): AccelerationInfo {
    return this.accelerationProbe.probe();
  }
}
