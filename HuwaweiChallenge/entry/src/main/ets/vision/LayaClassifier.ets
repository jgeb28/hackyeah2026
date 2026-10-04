// Laya-backed classifier: OCR text -> island ScanResult (DESIGN §6/§8).
// The deception gate decides the verdict; the chosen incident supplies the display.
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { MessageAnalysis, Verdict as LayaVerdict } from '../domain/model/Decision';
import { AppContainer } from '../di/AppContainer';
import { BackendSettings } from '../dev/BackendSettings';
import { ScanResult, Verdict } from '../trigger/TriggerTypes';
import { IncidentKb, Incident } from '../alert/IncidentKb';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianLaya';

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

  /** Run Laya on the recognised text and map its answers to a ScanResult. */
  async classify(text: string): Promise<ScanResult> {
    const analysis: MessageAnalysis = await this.ensure().analyseMessage.run(text);
    // Only a *threat* incident is used for display; a benign (`INFO`) match is dropped.
    let category: string = '';
    let severity: string = LayaClassifier.severityOf(analysis.verdict);
    let incidentId: string = '';
    const incident: Incident | null = analysis.incidentId.length > 0
      ? IncidentKb.forId(analysis.incidentId)
      : null;
    if (incident !== null && incident.severity !== 'INFO') {
      category = incident.category;
      severity = incident.severity;
      incidentId = incident.id;
    }
    const result: ScanResult = {
      verdict: LayaClassifier.verdictOf(analysis.verdict),
      category: category,
      confidence: analysis.confidence,
      signals: [],
      severity: severity,
      incidentId: incidentId
    };
    hilog.info(DOMAIN, TAG, 'classify: chars=%{public}d verdict=%{public}s category=%{public}s incident=%{public}s conf=%{public}d',
      text.length, result.verdict, result.category, result.incidentId, Math.round(result.confidence * 100));
    return result;
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
