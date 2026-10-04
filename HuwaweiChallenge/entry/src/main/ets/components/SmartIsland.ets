// Smart island: a small pill that expands; "Screenshot" scans the real screen for scams.
import { IncidentKb, Incident } from '../alert/IncidentKb';
import { ScreenScanner, ScanOutcome } from '../vision/ScreenScanner';
import { AlertTheme } from '../alert/AlertTheme';
import { ScanResult, Verdict } from '../trigger/TriggerTypes';

const IDLE_COLOR: string = '#1C1C1E';
const SAFE_COLOR: string = '#1E9E5B';
const PILL_WIDTH_VP: number = 140;

@Component
export struct SmartIsland {
  @State expanded: boolean = false;
  @State phase: string = 'idle'; // idle | scanning | safe | scam | error | empty
  @State title: string = 'Guardian';
  @State detail: string = '';
  @State color: string = IDLE_COLOR;
  /** KB incident JSON for the Details page; set when a scam is detected. */
  @State incidentJson: string = '';
  /** Called when the user closes the island for good (the small x). */
  onClose: () => void = () => {};
  /** Called when the user taps Details on a scam result. */
  onDetails: (json: string) => void = () => {};
  /** Called on expand/collapse so the floating window can resize itself. */
  onResize: (expanded: boolean) => void = () => {};

  private scanner: ScreenScanner = new ScreenScanner();
  private scanToken: number = 0;

  private setExpanded(value: boolean): void {
    this.expanded = value;
    this.onResize(value);
  }

  /** Leading icon for the current phase (shield = neutral default). */
  private static iconFor(phase: string): string {
    if (phase === 'safe' || phase === 'empty') {
      return '\u2713';
    }
    if (phase === 'scam' || phase === 'error') {
      return '\u26A0';
    }
    return '🛡';
  }

  /** True once a scan has settled on a result (so the pill keeps its status colour). */
  private static isResult(phase: string): boolean {
    return phase === 'safe' || phase === 'scam' || phase === 'empty' || phase === 'error';
  }

  /** Close: back to the plain, neutral pill (the result is acknowledged). */
  private minimize(): void {
    this.scanToken++;
    this.phase = 'idle';
    this.title = 'Guardian';
    this.detail = '';
    this.incidentJson = '';
    this.color = IDLE_COLOR;
    this.setExpanded(false);
  }

  private async scan(): Promise<void> {
    if (this.phase === 'scanning') {
      return;
    }
    this.setExpanded(true);
    this.phase = 'scanning';
    this.title = 'Scanning the screen...';
    this.detail = '';
    this.incidentJson = '';
    this.color = IDLE_COLOR;
    const token: number = ++this.scanToken;

    const outcome: ScanOutcome = await this.scanner.scanOnce();
    if (token !== this.scanToken) {
      // The user closed the island while scanning; drop the result.
      return;
    }

    if (outcome.error.length > 0) {
      this.phase = 'error';
      this.color = IDLE_COLOR;
      this.title = 'Could not read the screen';
      this.detail = outcome.error;
    } else if (outcome.text.length === 0) {
      this.phase = 'empty';
      this.color = SAFE_COLOR;
      this.title = 'No text found';
      this.detail = 'The captured screen contained no readable text.';
    } else {
      const result: ScanResult | null = outcome.result;
      if (result === null || result.verdict === Verdict.SAFE) {
        this.phase = 'safe';
        this.color = SAFE_COLOR;
        this.title = 'Looks safe';
        this.detail = '';
      } else {
        this.phase = 'scam';
        const incident: Incident | null = IncidentKb.forText(outcome.text, result.category);
        if (incident !== null) {
          // UI severity comes from the incident (DESIGN §18), not the raw verdict.
          this.color = AlertTheme.colorForSeverity(incident.severity);
          this.title = incident.title;
          this.detail = `${incident.explanation} ${incident.remediation.join(' ')}`;
          this.incidentJson = JSON.stringify(incident);
        } else {
          this.color = AlertTheme.colorForSeverity(result.severity ?? 'WARNING');
          this.title = AlertTheme.titleForCategory(result.category);
          this.detail = '';
          this.incidentJson = '';
        }
      }
    }
    // Show the result as a coloured pill; the user taps it to expand the card.
    this.setExpanded(false);
  }

  @Builder
  pill() {
    Row({ space: 6 }) {
      Text('🛡')
        .fontSize(13)
        .fontColor(Color.White)
      Text(SmartIsland.isResult(this.phase) ? this.title : 'Guardian')
        .fontSize(12)
        .fontColor(Color.White)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('\u2715')
        .fontSize(11)
        .fontColor('#CCFFFFFF')
        .padding({ left: 4 })
        .onClick(() => {
          this.onClose();
        })
    }
    .width(PILL_WIDTH_VP)
    .padding({ left: 10, right: 7, top: 6, bottom: 6 })
    .backgroundColor(SmartIsland.isResult(this.phase) ? this.color : IDLE_COLOR)
    .borderRadius(16)
    .border({ width: 1, color: '#3A4250' })
    .onClick(() => {
      this.setExpanded(true);
    })
  }

  @Builder
  card() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text(SmartIsland.iconFor(this.phase))
          .fontSize(14)
          .fontColor(Color.White)
        Text(this.title)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('\u2715')
          .fontSize(12)
          .fontColor('#CCFFFFFF')
          .padding(4)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')

      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(11)
          .fontColor('#E6FFFFFF')
          .lineHeight(16)
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      Row({ space: 8 }) {
        if (this.phase === 'scam') {
          Button('Details')
            .fontSize(11)
            .height(30)
            .layoutWeight(1)
            .backgroundColor(Color.White)
            .fontColor(this.color)
            .onClick(() => {
              this.onDetails(this.incidentJson);
            })
        } else {
          Button('Screenshot')
            .fontSize(11)
            .height(30)
            .layoutWeight(1)
            .backgroundColor(Color.White)
            .fontColor(this.phase === 'idle' ? IDLE_COLOR : this.color)
            .enabled(this.phase !== 'scanning')
            .onClick(() => {
              this.scan();
            })
        }
        Button('Close')
          .fontSize(11)
          .height(30)
          .layoutWeight(1)
          .backgroundColor('#33FFFFFF')
          .fontColor(Color.White)
          .onClick(() => {
            this.minimize();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.color)
    .borderRadius(20)
    .border({ width: 1, color: '#40FFFFFF' })
  }

  build() {
    Column() {
      if (this.expanded) {
        this.card()
      } else {
        this.pill()
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
