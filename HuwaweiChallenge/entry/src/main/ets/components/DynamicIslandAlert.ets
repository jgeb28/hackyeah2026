/**
 * DynamicIslandAlert
 * ---------------------------------------------------------------------------
 * iPhone-style "Dynamic Island" alert pinned to the top of the screen.
 *
 * Behaviour:
 *   - collapsed   -> a short, general note in a dark pill,
 *   - tap         -> smoothly expands into a card with more detail,
 *   - "Dismiss"/✕ -> closes the alert.
 *
 * The text is fully customizable at the call site. Pass your own `detail`
 * (and optionally `shortText` / `title`) to override the defaults below.
 */
@Component
export struct DynamicIslandAlert {
  /** Short, general text shown in the collapsed pill. */
  @Prop shortText: string = 'Suspicious message';
  /** Title shown in the expanded card. */
  @Prop title: string = 'Suspicious message';
  /** Detailed description shown in the expanded card (override at the call site). */
  @Prop detail: string = 'This message looks suspicious. Do not click any links or share personal information.';
  /** Called when the alert is dismissed. */
  onDismiss: () => void = () => {};

  @State expanded: boolean = false;

  build() {
    Column() {
      if (this.expanded) {
        // ------------------- expanded: more detail -------------------
        Row() {
          Text('⚠')
            .fontSize(22)
            .fontColor('#FF453A')

          Text(this.title)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .layoutWeight(1)
            .margin({ left: 10 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('✕')
            .fontSize(16)
            .fontColor('#8E8E93')
            .padding(4)
            .onClick(() => {
              this.onDismiss();
            })
        }
        .width('100%')

        Text(this.detail)
          .fontSize(14)
          .fontColor('#C7C7CC')
          .lineHeight(20)
          .margin({ top: 10 })
          .maxLines(4)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Button('Dismiss')
          .fontSize(14)
          .fontColor('#1C1C1E')
          .backgroundColor(Color.White)
          .width('100%')
          .height(36)
          .margin({ top: 14 })
          .onClick(() => {
            this.onDismiss();
          })
      } else {
        // ------------------- collapsed: short general note -------------------
        Row() {
          Text('⚠')
            .fontSize(18)
            .fontColor('#FF453A')

          Text(this.shortText)
            .fontSize(14)
            .fontColor(Color.White)
            .layoutWeight(1)
            .margin({ left: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text('›')
            .fontSize(18)
            .fontColor('#8E8E93')
            .margin({ left: 6 })
        }
        .width('100%')
      }
    }
    .width(this.expanded ? '92%' : 300)
    .padding({
      left: 14,
      right: 14,
      top: this.expanded ? 16 : 12,
      bottom: this.expanded ? 16 : 12
    })
    .backgroundColor('rgba(28, 28, 30, 0.96)')
    .borderRadius(this.expanded ? 28 : 24)
    .clip(true)
    .shadow({ radius: 24, color: '#66000000', offsetX: 0, offsetY: 8 })
    .animation({ duration: 340, curve: Curve.Friction })
    .onClick(() => {
      // Tapping the whole island expands or collapses it (buttons dismiss).
      this.expanded = !this.expanded;
    })
  }
}
