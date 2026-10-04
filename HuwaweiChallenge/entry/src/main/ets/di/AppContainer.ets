import { common } from '@kit.AbilityKit';
import { RawfileAssetLoader } from '../data/assets/AssetLoader';
import { InferenceConfig } from '../data/config/InferenceConfig';
import { AccelerationInfo, NnrtAccelerationProbe } from '../data/datasource/NnrtAccelerationProbe';
import { DecisionRepository } from '../domain/repository/DecisionRepository';
import { createDecisionRepository } from '../dev/BackendFactory';
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
  private readonly accelerationInfo: AccelerationInfo;

  constructor(context: common.UIAbilityContext) {
    this.config = new InferenceConfig();
    this.accelerationProbe = new NnrtAccelerationProbe();

    // Probe once: on the emulator there is no NNRt device, so we must not ask
    // MindSpore Lite for the NNRt delegate (it fails at predict). Only request
    // the NPU backend when the OS actually reports an accelerator.
    this.accelerationInfo = this.accelerationProbe.probe();
    this.config.useNpu = this.accelerationInfo.available;

    const assets = new RawfileAssetLoader(context.resourceManager);
    const repository: DecisionRepository =
      createDecisionRepository(this.config, assets, context.filesDir);
    this.analyseMessage = new AnalyseMessageUseCase(repository);
  }

  acceleration(): AccelerationInfo {
    return this.accelerationInfo;
  }
}
