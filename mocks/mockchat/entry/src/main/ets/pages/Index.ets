import { commonEventManager } from '@kit.BasicServicesKit';

/** Common event consumed by the Guardian main app's trigger bridge. */
const MESSAGE_RENDERED_EVENT: string = 'com.hackyeah.mockchat.MESSAGE_RENDERED';

interface ChatMessage {
  id: number;
  outgoing: boolean;
  text: string;
  time: string;
}

@Entry
@Component
struct Index {
  @State messages: ChatMessage[] = [];
  private scroller: Scroller = new Scroller();
  private cursor: number = 0;

  // Scenario A — "family emergency" money scam. Tap anywhere to reveal the next line.
  private script: ChatMessage[] = [
    { id: 1, outgoing: false, time: '14:02', text: "Hi sweetie, it's me \u{1F62D} I had an accident. My phone is broken, I'm using a friend's number." },
    { id: 2, outgoing: true, time: '14:03', text: "Which one? Is this really you?" },
    { id: 3, outgoing: false, time: '14:03', text: "Yes it's me! Don't call, I can't talk right now. The other driver is threatening to sue me." },
    { id: 4, outgoing: false, time: '14:04', text: "Their lawyer says they'll press charges unless I pay for the damage today. I could lose my license." },
    { id: 5, outgoing: false, time: '14:04', text: "Please send \u20AC4,800 now, I'll pay you back. Account details below. I'm scared." },
    { id: 6, outgoing: false, time: '14:05', text: "Don't tell mom and dad yet \u2014 just send it before 6pm." }
  ];

  private advance(): void {
    if (this.cursor >= this.script.length) {
      return;
    }
    this.messages = this.messages.concat([this.script[this.cursor]]);
    this.cursor++;
    this.announceRendered(this.script[this.cursor - 1]);
    setTimeout(() => {
      this.scroller.scrollEdge(Edge.Bottom);
    }, 60);
  }

  /**
   * Tell the Guardian main app that a message was rendered. This is the
   * emulator-friendly fallback for the accessibility trigger; on device the
   * accessibility service reads the same text directly.
   */
  private announceRendered(m: ChatMessage): void {
    const options: commonEventManager.CommonEventPublishData = {
      bundleName: 'com.hackyeah.mockchat',
      code: m.id,
      data: m.text
    };
    commonEventManager.publish(MESSAGE_RENDERED_EVENT, options, (err) => {
      if (err) {
        console.error(`Guardian: failed to announce rendered message: ${JSON.stringify(err)}`);
      }
    });
  }

  @Builder
  topBar() {
    Row() {
      Text('\u2039')
        .fontSize(30)
        .fontColor('#0A59F7')
        .width(40)
        .textAlign(TextAlign.Start)
      Text('Unknown number')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#182431')
        .layoutWeight(1)
        .textAlign(TextAlign.Center)
      Text('\u24D8')
        .fontSize(20)
        .fontColor('#0A59F7')
        .width(40)
        .textAlign(TextAlign.End)
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .backgroundColor(Color.White)
  }

  @Builder
  bubble(m: ChatMessage) {
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

  @Builder
  messageRow(m: ChatMessage) {
    Row() {
      this.bubble(m)
    }
    .width('100%')
    .justifyContent(m.outgoing ? FlexAlign.End : FlexAlign.Start)
    .padding({ left: 16, right: 16, top: 4, bottom: 4 })
  }

  build() {
    Column() {
      this.topBar()

      List({ scroller: this.scroller }) {
        ListItem() {
          Text('Today 14:02')
            .fontSize(12)
            .fontColor('#8A8F99')
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding({ top: 12, bottom: 6 })
        }

        ForEach(this.messages, (m: ChatMessage) => {
          ListItem() {
            this.messageRow(m)
          }
        }, (m: ChatMessage) => m.id.toString())
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
      .backgroundColor('#F1F3F5')

      Row() {
        Row() {
          Text('Message')
            .fontSize(16)
            .fontColor('#99A0A6')
            .layoutWeight(1)
            .padding({ left: 4 })
          Stack() {
            Text('\u2191')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
          }
          .width(34)
          .height(34)
          .backgroundColor('#0A59F7')
          .borderRadius(17)
        }
        .width('100%')
        .padding({ left: 14, right: 6, top: 6, bottom: 6 })
        .backgroundColor(Color.White)
        .borderRadius(22)
      }
      .width('100%')
      .padding({ left: 12, right: 12, top: 8, bottom: 16 })
      .backgroundColor('#F1F3F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
    .onClick(() => {
      this.advance();
    })
  }
}
