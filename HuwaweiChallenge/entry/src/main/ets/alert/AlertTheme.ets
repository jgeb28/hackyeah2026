// Severity styling for the alert overlay; colors mirror rawfile/kb/en/incidents.json.
import { common } from '@kit.AbilityKit';
import { util } from '@kit.ArkTS';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { Verdict } from '../trigger/TriggerTypes';

const DOMAIN = 0x0A11;
const TAG = 'GuardianTheme';

interface SeverityColors {
  CRITICAL?: string;
  WARNING?: string;
  INFO?: string;
}

interface KbRoot {
  severityColors?: SeverityColors;
}

let criticalColor: string = '#E84026';
let warningColor: string = '#ED6F21';
let infoColor: string = '#0A59F7';

export class AlertTheme {
  /** Read severity colors from the incident knowledge base (best effort). */
  static load(context: common.Context): void {
    try {
      const bytes: Uint8Array = context.resourceManager.getRawFileContentSync('kb/en/incidents.json');
      const text: string = util.TextDecoder.create('utf-8').decodeToString(bytes);
      const root: KbRoot = JSON.parse(text) as KbRoot;
      const colors: SeverityColors | undefined = root.severityColors;
      if (colors !== undefined) {
        if (colors.CRITICAL !== undefined) {
          criticalColor = colors.CRITICAL;
        }
        if (colors.WARNING !== undefined) {
          warningColor = colors.WARNING;
        }
        if (colors.INFO !== undefined) {
          infoColor = colors.INFO;
        }
      }
      hilog.info(DOMAIN, TAG, 'severity colors loaded');
    } catch (err) {
      hilog.warn(DOMAIN, TAG, 'theme load failed: %{public}s', JSON.stringify(err));
    }
  }

  static colorFor(verdict: Verdict): string {
    if (verdict === Verdict.CRITICAL) {
      return criticalColor;
    }
    if (verdict === Verdict.DANGEROUS) {
      return warningColor;
    }
    return infoColor;
  }

  static colorForSeverity(severity: string): string {
    if (severity === 'CRITICAL') {
      return criticalColor;
    }
    if (severity === 'WARNING') {
      return warningColor;
    }
    return infoColor;
  }

  static titleForCategory(category: string): string {
    if (category === 'scam') {
      return 'Possible scam';
    }
    if (category === 'misinformation') {
      return 'Unverified information';
    }
    if (category === 'harassment') {
      return 'Possible harassment';
    }
    if (category === 'notice') {
      return 'Heads-up';
    }
    return 'Suspicious message';
  }

  static titleFor(verdict: Verdict): string {
    if (verdict === Verdict.CRITICAL) {
      return 'Possible scam detected';
    }
    if (verdict === Verdict.DANGEROUS) {
      return 'Suspicious message';
    }
    return 'Heads-up';
  }
}
