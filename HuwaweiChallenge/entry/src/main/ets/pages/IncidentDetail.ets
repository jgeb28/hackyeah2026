// IncidentDetail — normal app screen that hosts IncidentDetailView.
// Hardcoded single incident for testing. The route `json` param (the LAYA seam)
// overrides it with a supplied incident JSON when present.
import { IncidentDetailView } from '../components/IncidentDetailView';

interface DetailParams {
  json?: string;
}

/** Single test incident (KB shape). Edit this to test other content. */
const INCIDENT_JSON: string = JSON.stringify({
  id: 'bank-authority-impersonation',
  category: 'scam',
  severity: 'CRITICAL',
  title: 'Possible impersonation',
  description: 'Someone claims to be your bank, police, or tax office and pushes you to verify or pay immediately.',
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

  aboutToAppear(): void {
    const params: DetailParams = this.getUIContext().getRouter().getParams() as DetailParams;
    if (params !== undefined && params !== null && typeof params.json === 'string' && params.json.length > 0) {
      this.json = params.json;
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

      IncidentDetailView({ json: this.json })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .borderRadius(18)
    .clip(true)
    .border({ width: 1, color: '#2A2F3A' })
  }
}
