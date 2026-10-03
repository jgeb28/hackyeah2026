/**
 * TriggerDemo — local, in-app validation of the Guardian trigger.
 *
 * It replays the same "family emergency" scam thread and calls
 * TriggerEngine.onTextRendered() for every message as it is rendered, exactly
 * like the cross-app paths (accessibility / common-event bridge) would. The
 * header shows how many scans ran and the last verdict, so the ingestion trigger
 * and the classify() seam can be validated on any device — including an emulator
 * where a third-party accessibility service cannot be enabled.
 *
 * Tap anywhere to render the next message.
 */
import { TriggerEngine, TARGET_BUNDLE } from '../trigger/TriggerEngine';
import { ScanResult, TriggerSource, Verdict } from '../trigger/TriggerTypes';

interface DemoMessage {
  outgoing: boolean;
  text: string;
}

@Entry
@Component
struct TriggerDemo {
  @State shown: number = 0;
  @State scans: number = 0;
  @State lastVerdict: string = '—';
  @State lastChars: number = 0;

  private script: DemoMessage[] = [
    { outgoing: false, text: "Hi sweetie, it's me 😭 I had an accident. My phone is broken, I'm using a friend's number." },
    { outgoing: true, text: 'Which one? Is this really you?' },
    { outgoing: false, text: "Yes it's me! Don't call, I can't talk right now. The other driver is threatening to sue me." },
    { outgoing: false, text: "Their lawyer says they'll press charges unless I pay for the damage today. I could lose my license." },
    { outgoing: false, text: 'Please send €4,800 now, I\'ll pay you back. Account details below. I\'m scared.' },
    { outgoing: false, text: "Don't tell mom and dad yet — just send it before 6pm." }
  ];

  private renderNext(): void {
    if (this.shown >= this.script.length) {
      return;
    }
    const m: DemoMessage = this.script[this.shown];
    this.shown++;
    // This is the trigger: fires as text is rendered.
    const result: ScanResult | null =
      TriggerEngine.get().onTextRendered(TARGET_BUNDLE, m.text, TriggerSource.PAGE_ACTIVE);
    if (result === null) {
      this.lastVerdict = 'skipped (dedupe/budget)';
      return;
    }
    this.scans++;
    this.lastVerdict = result.verdict;
    this.lastChars = m.text.length;
  }

  @Builder
  header() {
    Column() {
      Text('Guardian — trigger demo')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#F5F5F5')
      Text(`scans: ${this.scans}    last verdict: ${this.lastVerdict}    chars: ${this.lastChars}`)
        .fontSize(13)
        .fontColor('#9CC4FF')
        .margin({ top: 4 })
      Text('tap anywhere to render the next message')
        .fontSize(12)
        .fontColor('#8A8F99')
        .margin({ top: 2 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#101418')
  }

  @Builder
  bubble(m: DemoMessage) {
    Column() {
      Text(m.text)
        .fontSize(16)
        .lineHeight(22)
        .fontColor(m.outgoing ? '#FFFFFF' : '#182431')
    }
    .constraintSize({ maxWidth: '78%' })
    .padding({ left: 14, right: 14, top: 10, bottom: 10 })
    .backgroundColor(m.outgoing ? '#0A59F7' : '#FFFFFF')
    .borderRadius(18)
  }

  build() {
    Column() {
      this.header()
      List() {
        ForEach(this.script.slice(0, this.shown), (m: DemoMessage, i: number) => {
          ListItem() {
            Row() {
              this.bubble(m)
            }
            .width('100%')
            .justifyContent(m.outgoing ? FlexAlign.End : FlexAlign.Start)
            .padding({ left: 16, right: 16, top: 4, bottom: 4 })
          }
        }, (m: DemoMessage, i: number) => `${i}-${m.text}`)
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor('#F1F3F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .onClick(() => {
      this.renderNext();
    })
  }
}
