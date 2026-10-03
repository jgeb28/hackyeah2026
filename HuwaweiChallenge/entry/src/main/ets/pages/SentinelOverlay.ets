// Content of the floating alert window; colors/title come from AlertOverlay.
import { AlertOverlay } from '../alert/AlertOverlay';

@Entry
@Component
struct SentinelOverlay {
  @StorageLink('guardianTitle') title: string = 'Suspicious message';
  @StorageLink('guardianBody') body: string = '';
  @StorageLink('guardianColor') color: string = '#E84026';

  build() {
    Column({ space: 8 }) {
      Row({ space: 8 }) {
        Text('⚠')
          .fontSize(20)
          .fontColor(Color.White)
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .width('100%')

      Text(this.body)
        .fontSize(13)
        .fontColor('#E6FFFFFF')
        .lineHeight(18)
        .maxLines(4)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Button('Dismiss')
        .fontSize(13)
        .fontColor(this.color)
        .backgroundColor(Color.White)
        .width('100%')
        .height(32)
        .onClick(() => {
          AlertOverlay.close();
        })
    }
    .width('100%')
    .height('100%')
    .padding(14)
    .backgroundColor(this.color)
    .borderRadius(20)
  }
}
