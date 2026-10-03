// Guardian control screen: shows/hides the floating smart island.
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';
import { IslandOverlay } from '../alert/IslandOverlay';

const DOMAIN: number = 0x0A11;

@Entry
@Component
struct Index {
  @State floating: boolean = false;

  onPageShow(): void {
    this.floating = IslandOverlay.isShown();
  }

  private async toggleFloating(): Promise<void> {
    if (IslandOverlay.isShown()) {
      IslandOverlay.close();
      this.floating = false;
      return;
    }
    const shown: boolean = await IslandOverlay.show();
    this.floating = shown;
    if (!shown) {
      hilog.warn(DOMAIN, 'testTag', 'floating island not shown');
    }
  }

  build() {
    Column({ space: 18 }) {
      Text('Guardian')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor('#182431')

      Text('The island floats on top of other apps. Open a message or a web page and tap it, then press Screenshot to check it for scams.')
        .fontSize(14)
        .fontColor('#8A8F99')
        .textAlign(TextAlign.Center)
        .lineHeight(20)
        .padding({ left: 24, right: 24 })

      Button(this.floating ? 'Hide floating island' : 'Show floating island')
        .fontSize(15)
        .width(240)
        .height(44)
        .onClick(() => {
          this.toggleFloating();
        })

      Button('Open OCR demo (PP-OCRv4)')
        .fontSize(15)
        .width(240)
        .height(44)
        .onClick(() => {
          router.pushUrl({ url: 'pages/OcrDemo' });
        })

      Button('View incident details')
        .fontSize(15)
        .width(240)
        .height(44)
        .onClick(() => {
          router.pushUrl({ url: 'pages/IncidentDetail' });
        })

      Button('Open Laya demo')
        .fontSize(15)
        .width(240)
        .height(44)
        .onClick(() => {
          router.pushUrl({ url: 'pages/LayaDemo' });
        })
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F1F3F5')
  }
}
