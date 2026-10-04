// IncidentDetail — hosts IncidentDetailView. An optional cloud "Describe" action
// (DeepSeek, the user's own key, no server) is offered on incidents above the
// lowest escalation level `L0`, and only when a key is set.
import { hilog } from '@kit.PerformanceAnalysisKit';
import { IncidentDetailView } from '../components/IncidentDetailView';
import { IncidentDoc, parseIncident } from '../detail/DetailTypes';
import { DeepSeekSettings } from '../dev/DeepSeekSettings';
import { DeepSeekClient } from '../dev/DeepSeekClient';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianDetail';

interface DetailParams {
  json?: string;
  text?: string;
}

/** Single test incident (KB shape). Edit this to test other content. */
const INCIDENT_JSON: string = JSON.stringify({
  id: 'bank-authority-impersonation',
  category: 'scam',
  severity: 'CRITICAL',
  escalation: 'L0',
  title: 'Possible impersonation',
  description: 'A fake bank, police or tax office pressures you to verify or pay now.',
  explanation: 'Real banks and authorities never ask you to verify or pay through a link in a message.',
  remediation: [
    'Contact your bank using the number on your card or the official app.',
    "Don't tap the link or enter your details.",
    'Report the message.'
  ],
  sources: ['Bank security guidance']
});

@Entry
@Component
struct IncidentDetail {
  @State json: string = INCIDENT_JSON;
  @State canDescribe: boolean = false;
  @State describeStatus: string = 'idle'; // idle | loading | done | error
  @State describeText: string = '';
  /** The scanned text that raised this incident; sent to DeepSeek with the incident. */
  @State scannedText: string = '';

  aboutToAppear(): void {
    const params: DetailParams = this.getUIContext().getRouter().getParams() as DetailParams;
    if (params !== undefined && params !== null && typeof params.json === 'string' && params.json.length > 0) {
      this.json = params.json;
    }
    if (params !== undefined && params !== null && typeof params.text === 'string') {
      this.scannedText = params.text;
    }
    const doc: IncidentDoc | null = parseIncident(this.json);
    const escalation: string = doc !== null ? doc.escalation : '';
    // Above L0, and only when the user has provided their own DeepSeek key.
    this.canDescribe = escalation.length > 0 && escalation !== 'L0' && DeepSeekSettings.hasKey;
  }

  private async describe(): Promise<void> {
    const doc: IncidentDoc | null = parseIncident(this.json);
    if (doc === null) {
      return;
    }
    this.describeStatus = 'loading';
    this.describeText = '';
    try {
      const body: string = `${doc.description}\n\n${doc.explanation}`;
      this.describeText = await DeepSeekClient.describe(doc.title, body, this.scannedText);
      this.describeStatus = 'done';
    } catch (err) {
      const code: number | undefined = (err as BusinessError).code;
      const message: string = (err as Error).message !== undefined ? (err as Error).message : '';
      if (code !== undefined) {
        this.describeText = 'Could not reach DeepSeek. Check your connection and try again.';
      } else if (message.indexOf('key') >= 0) {
        this.describeText = 'Add your DeepSeek API key in Settings to use this.';
      } else {
        this.describeText = message.length > 0 ? message : 'Could not reach DeepSeek. Try again.';
      }
      this.describeStatus = 'error';
      hilog.warn(DOMAIN, TAG, 'describe failed: %{public}s', message);
    }
  }

  build() {
    Column() {
      Row() {
        Text('‹ Back')
          .fontSize(16)
          .fontColor('#0A59F7')
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
        Blank()
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 4 })

      IncidentDetailView({
        json: this.json,
        canDescribe: this.canDescribe,
        describeStatus: this.describeStatus,
        describeText: this.describeText,
        onDescribe: () => {
          this.describe();
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .borderRadius(18)
    .clip(true)
    .border({ width: 1, color: '#2A2F3A' })
  }
}
