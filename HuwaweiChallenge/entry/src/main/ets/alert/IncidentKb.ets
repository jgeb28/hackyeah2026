// Incident knowledge base lookup (rawfile/kb/en/incidents.json, DESIGN §18).
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianKb';

export interface Incident {
  id: string;
  category: string;
  severity: string;
  title: string;
  description: string;
  explanation: string;
  remediation: string[];
}

interface KbRoot {
  incidents?: Incident[];
}

function rank(severity: string): number {
  if (severity === 'CRITICAL') {
    return 3;
  }
  if (severity === 'WARNING') {
    return 2;
  }
  return 1;
}

export class IncidentKb {
  private static incidents: Incident[] = [];
  private static loaded: boolean = false;

  /** Read the incident KB once (best effort). */
  static load(context: common.Context): void {
    if (IncidentKb.loaded) {
      return;
    }
    try {
      const bytes: Uint8Array = context.resourceManager.getRawFileContentSync('kb/en/incidents.json');
      const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
      const root: KbRoot = JSON.parse(text) as KbRoot;
      IncidentKb.incidents = root.incidents !== undefined ? root.incidents : [];
      IncidentKb.loaded = true;
      hilog.info(DOMAIN, TAG, 'incidents loaded: %{public}d', IncidentKb.incidents.length);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'kb load failed: %{public}s', JSON.stringify(err));
    }
  }

  /** The most severe incident for a Laya category, or null when none matches. */
  static forCategory(category: string): Incident | null {
    let best: Incident | null = null;
    for (let i = 0; i < IncidentKb.incidents.length; i++) {
      const incident: Incident = IncidentKb.incidents[i];
      if (incident.category !== category) {
        continue;
      }
      if (best === null || rank(incident.severity) > rank(best.severity)) {
        best = incident;
      }
    }
    return best;
  }
}
