import { LayaRequest, LayaResponse } from '../model/Decision';

/**
 * Domain port for the Laya decision model.
 *
 * The presentation layer depends only on this interface (via the use case); the
 * concrete implementation (remote Space today, on-device MindSpore Lite later)
 * lives in the data layer. Swapping backends never touches the UI.
 */
export interface DecisionRepository {
  predict(request: LayaRequest): Promise<LayaResponse>;
}
