// Smart island: a small pill that expands; "Screenshot" scans the real screen for scams.
import { IncidentKb, Incident } from '../alert/IncidentKb';
import { ScreenScanner, ScanOutcome } from '../vision/ScreenScanner';
import { AlertTheme } from '../alert/AlertTheme';
import { ScanResult, Verdict } from '../trigger/TriggerTypes';

const IDLE_COLOR: string = '#1C1C1E';
const SAFE_COLOR: string = '#1E9E5B';
const PILL_WIDTH_VP: number = 156;

@Component
export struct SmartIsland {
  @State expanded: boolean = false;
  @State phase: string = 'idle'; // idle | scanning | safe | scam | error | empty
  @State title: string = 'Guardian';
  @State detail: string = '';
  @State scanText: string = '';
  @State color: string = IDLE_COLOR;
  /** Called when the user closes the island for good (the small x). */
  onClose: () => void = () => {};
  /** Called on expand/collapse so the floating window can resize itself. */
  onResize: (expanded: boolean) => void = () => {};

  private scanner: ScreenScanner = new ScreenScanner();
  private scanToken: number = 0;

  private setExpanded(value: boolean): void {
    this.expanded = value;
    this.onResize(value);
  }

  /** Close: minimise back to the plain pill (no status colour). */
  private minimize(): void {
    this.scanToken++;
    this.phase = 'idle';
    this.title = 'Guardian';
    this.detail = '';
    this.scanText = '';
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
    this.scanText = '';
    this.color = IDLE_COLOR;
    const token: number = ++this.scanToken;

    const outcome: ScanOutcome = await this.scanner.scanOnce();
    if (token !== this.scanToken) {
      // The user closed the island while scanning; drop the result.
      return;
    }

    this.scanText = outcome.text;
    if (outcome.error.length > 0) {
      this.phase = 'error';
      this.color = IDLE_COLOR;
      this.title = 'Could not read the screen';
      this.detail = outcome.error;
      return;
    }

    if (outcome.text.length === 0) {
      this.phase = 'empty';
      this.color = SAFE_COLOR;
      this.title = 'No text found';
      this.detail = 'The captured screen contained no readable text.';
      return;
    }

    const result: ScanResult | null = outcome.result;
    if (result === null || result.verdict === Verdict.SAFE) {
      this.phase = 'safe';
      this.color = SAFE_COLOR;
      this.title = 'Looks safe';
      this.detail = 'No scam signs found on this screen.';
    } else {
      this.phase = 'scam';
      this.color = AlertTheme.colorForSeverity(result.severity ?? 'WARNING');
      const incident: Incident | null = IncidentKb.forCategory(result.category);
      if (incident !== null) {
        this.title = incident.title;
        this.detail = `${incident.explanation} ${incident.remediation.join(' ')}`;
      } else {
        this.title = AlertTheme.titleForCategory(result.category);
        this.detail = '';
      }
    }
  }

  @Builder
  pill() {
    Row({ space: 6 }) {
      Text('\u26A0')
        .fontSize(14)
        .fontColor(Color.White)
      Text('Guardian')
        .fontSize(13)
        .fontColor(Color.White)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      Text('\u2715')
        .fontSize(12)
        .fontColor('#CCFFFFFF')
        .padding({ left: 4 })
        .onClick(() => {
          this.onClose();
        })
    }
    .width(PILL_WIDTH_VP)
    .padding({ left: 12, right: 8, top: 7, bottom: 7 })
    .backgroundColor(IDLE_COLOR)
    .borderRadius(18)
    .shadow({ radius: 14, color: '#55000000', offsetX: 0, offsetY: 5 })
    .onClick(() => {
      this.setExpanded(true);
    })
  }

  @Builder
  card() {
    Column({ space: 10 }) {
      Row({ space: 8 }) {
        Text(this.phase === 'safe' ? '\u2713' : '\u26A0')
          .fontSize(15)
          .fontColor(Color.White)
        Text(this.title)
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text('\u2715')
          .fontSize(13)
          .fontColor('#CCFFFFFF')
          .padding(4)
          .onClick(() => {
            this.onClose();
          })
      }
      .width('100%')

      if (this.detail.length > 0) {
        Text(this.detail)
          .fontSize(12)
          .fontColor('#E6FFFFFF')
          .lineHeight(17)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }

      if (this.scanText.length > 0) {
        Column({ space: 4 }) {
          Text(this.phase === 'safe' ? 'Scanned text' : 'Detected text')
            .fontSize(10)
            .fontColor('#B3FFFFFF')
            .width('100%')
          Scroll() {
            Text(this.scanText)
              .fontSize(11)
              .fontColor('#F2FFFFFF')
              .lineHeight(15)
              .width('100%')
          }
          .height(92)
          .width('100%')
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#22000000')
        .borderRadius(8)
      }

      Row({ space: 8 }) {
        Button('Screenshot')
          .fontSize(12)
          .height(32)
          .layoutWeight(1)
          .backgroundColor(Color.White)
          .fontColor(this.phase === 'idle' ? IDLE_COLOR : this.color)
          .enabled(this.phase !== 'scanning')
          .onClick(() => {
            this.scan();
          })
        Button('Close')
          .fontSize(12)
          .height(32)
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
    .padding(14)
    .backgroundColor(this.color)
    .borderRadius(22)
    .shadow({ radius: 18, color: '#55000000', offsetX: 0, offsetY: 6 })
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
