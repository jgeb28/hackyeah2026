// Laya-backed classifier: OCR text -> island ScanResult (DESIGN §6/§8).
import { common } from '@kit.AbilityKit';
import { MessageAnalysis, Verdict as LayaVerdict } from '../domain/model/Decision';
import { AppContainer } from '../di/AppContainer';
import { BackendSettings } from '../dev/BackendSettings';
import { ScanResult, Verdict } from '../trigger/TriggerTypes';

export class LayaClassifier {
  private container: AppContainer | null = null;
  private mode: string = '';

  private ensure(): AppContainer {
    const mode: string = BackendSettings.mode;
    if (this.container === null || this.mode !== mode) {
      const ctx: common.UIAbilityContext = getContext() as common.UIAbilityContext;
      this.container = new AppContainer(ctx);
      this.mode = mode;
    }
    return this.container;
  }

  /** Run Laya on the recognised text and map its verdict to a ScanResult. */
  async classify(text: string): Promise<ScanResult> {
    const analysis: MessageAnalysis = await this.ensure().analyseMessage.run(text);
    return {
      verdict: LayaClassifier.verdictOf(analysis.verdict),
      category: analysis.category.length > 0 ? analysis.category : 'scam',
      confidence: analysis.confidence,
      signals: [],
      severity: LayaClassifier.severityOf(analysis.verdict)
    };
  }

  private static verdictOf(verdict: string): Verdict {
    if (verdict === LayaVerdict.CRITICAL) {
      return Verdict.CRITICAL;
    }
    if (verdict === LayaVerdict.DANGEROUS) {
      return Verdict.DANGEROUS;
    }
    return Verdict.SAFE;
  }

  private static severityOf(verdict: string): string {
    if (verdict === LayaVerdict.CRITICAL) {
      return 'CRITICAL';
    }
    if (verdict === LayaVerdict.DANGEROUS) {
      return 'WARNING';
    }
    return 'INFO';
  }
}
