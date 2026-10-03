import { DecisionAnswer, MessageAnalysis, Verdict } from '../../domain/model/Decision';

function verdictColor(verdict: string): string {
  if (verdict === Verdict.CRITICAL) {
    return '#FF453A';
  }
  if (verdict === Verdict.DANGEROUS) {
    return '#FF9F0A';
  }
  if (verdict === Verdict.SAFE) {
    return '#30D158';
  }
  return '#8E8E93';
}

/**
 * AnswerPopup — the modal shown when the user taps the question.
 *
 * It is presentation-only: it receives an already-computed `MessageAnalysis`
 * (produced by `AnalyseMessageUseCase`) and renders the verdict plus every
 * typed answer and its probability breakdown. No model or network logic here.
 */
@Component
export struct AnswerPopup {
  /** The question the user tapped. */
  question: string = '';
  /** Result from the domain use case. */
  analysis: MessageAnalysis = new MessageAnalysis();
  /** Human-readable note about where inference ran (cloud / on-device, NPU / CPU). */
  sourceLabel: string = '';
  onDismiss: () => void = () => {
  };

  build() {
    Stack() {
      // Dimmed backdrop — tapping it dismisses.
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')
        .onClick(() => {
          this.onDismiss();
        })

      // Card.
      Column() {
        Row() {
          Text('🛡')
            .fontSize(20)
          Text('Guardian')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .margin({ left: 8 })
            .layoutWeight(1)
          Text('✕')
            .fontSize(16)
            .fontColor('#8E8E93')
            .padding(4)
            .onClick(() => {
              this.onDismiss();
            })
        }
        .width('100%')

        Text(this.question)
          .fontSize(14)
          .fontColor('#C7C7CC')
          .width('100%')
          .margin({ top: 6 })

        Text(this.analysis.verdict)
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(verdictColor(this.analysis.verdict))
          .width('100%')
          .margin({ top: 14 })

        Text(this.analysis.summary)
          .fontSize(14)
          .fontColor('#EBEBF5')
          .lineHeight(20)
          .width('100%')
          .margin({ top: 6 })

        // Typed answers from Laya.
        ForEach(this.analysis.answers, (answer: DecisionAnswer) => {
          Column() {
            Row() {
              Text(answer.label)
                .fontSize(14)
                .fontColor('#C7C7CC')
                .layoutWeight(1)
              Text(answer.value)
                .fontSize(14)
                .fontWeight(FontWeight.Medium)
                .fontColor(Color.White)
            }
            .width('100%')

            if (answer.breakdown.length > 0) {
              Text(answer.breakdown)
                .fontSize(11)
                .fontColor('#8E8E93')
                .width('100%')
                .margin({ top: 2 })
            }
          }
          .width('100%')
          .padding({ top: 9, bottom: 9 })
          .border({ width: { bottom: 1 }, color: '#2C2C2E' })
        }, (answer: DecisionAnswer) => answer.label)

        Text(`model ${this.analysis.model} · ${this.analysis.latencyMs.toFixed(0)} ms · ${this.sourceLabel}`)
          .fontSize(11)
          .fontColor('#8E8E93')
          .width('100%')
          .margin({ top: 12 })

        Button('Done')
          .fontSize(15)
          .fontColor('#1C1C1E')
          .backgroundColor(Color.White)
          .width('100%')
          .height(42)
          .margin({ top: 16 })
          .onClick(() => {
            this.onDismiss();
          })
      }
      .width('88%')
      .padding(20)
      .backgroundColor('rgba(28, 28, 30, 0.98)')
      .borderRadius(20)
      .shadow({ radius: 30, color: '#66000000', offsetX: 0, offsetY: 10 })
    }
    .width('100%')
    .height('100%')
    .alignContent(Alignment.Center)
  }
}
