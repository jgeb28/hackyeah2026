// Incident knowledge base loaded from rawfile/kb/en/incidents.json (no network).
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianKb';

interface Level0 {
  title: string;
  text: string;
}

interface Messages {
  level0: Level0;
}

interface Incident {
  id: string;
  category: string;
  severity: string;
  keywords: string[];
  messages: Messages;
}

interface KbRoot {
  incidents?: Incident[];
}

export interface KbIncident {
  id: string;
  category: string;
  severity: string;
  text: string;
}

let incidents: KbIncident[] = [];

export class IncidentKnowledge {
  /** Load and cache the KB (best effort). */
  static load(context: common.Context): void {
    if (incidents.length > 0) {
      return;
    }
    try {
      const bytes: Uint8Array = context.resourceManager.getRawFileContentSync('kb/en/incidents.json');
      const root: KbRoot = JSON.parse(util.TextDecoder.create('utf-8').decodeToString(bytes)) as KbRoot;
      const raw: Incident[] = root.incidents ?? [];
      const loaded: KbIncident[] = [];
      for (const inc of raw) {
        const level0: Level0 | undefined = inc.messages?.level0;
        loaded.push({
          id: inc.id,
          category: inc.category,
          severity: inc.severity,
          text: level0 !== undefined ? level0.text : inc.keywords.join(', ')
        });
      }
      incidents = loaded;
      hilog.info(DOMAIN, TAG, `incidents loaded: ${incidents.length}`);
    } catch (err) {
      hilog.warn(DOMAIN, TAG, `kb load failed: ${JSON.stringify(err)}`);
    }
  }

  static all(): KbIncident[] {
    return incidents;
  }

  static count(): number {
    return incidents.length;
  }

  static at(index: number): KbIncident | undefined {
    return incidents[index];
  }
}
