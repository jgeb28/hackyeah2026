// Guardian control screen: shield logo + the primary Guard action + a Dev-mode switch.
import { hilog } from '@kit.PerformanceAnalysisKit';
import { common } from '@kit.AbilityKit';
import { IslandOverlay } from '../alert/IslandOverlay';
import { Backend, BackendSettings } from '../dev/BackendSettings';

const DOMAIN: number = 0x0A11;

@Entry
@Component
struct Index {
  @State floating: boolean = false;
  @State remote: boolean = false;

  aboutToAppear(): void {
    this.remote = BackendSettings.isRemote;
  }

  onPageShow(): void {
    this.floating = IslandOverlay.isShown();
    this.remote = BackendSettings.isRemote;
  }

  private async toggleGuard(): Promise<void> {
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

  /** Dev mode: flip the on-device <-> remote-GPU backend. */
  private setDevMode(on: boolean): void {
    this.remote = on;
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    BackendSettings.setBackend(ctx, on ? Backend.REMOTE : Backend.DEVICE);
  }

  build() {
    Column() {
      Column({ space: 16 }) {
        Image($r('app.media.shield'))
          .width(150)
          .height(150)
          .objectFit(ImageFit.Contain)
          .backgroundColor(Color.Transparent)
        Text('Guardian')
          .fontSize(36)
          .fontWeight(FontWeight.Bold)
          .fontColor('#F4F7FB')
        Text('On-device scam protection')
          .fontSize(15)
          .fontColor('#8A93A3')
      }
      .margin({ top: 72 })

      Blank()

      Column({ space: 16 }) {
        Button(this.floating ? 'Stop guarding' : 'Guard')
          .fontSize(21)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(288)
          .height(64)
          .borderRadius(32)
          .backgroundColor(this.floating ? '#E84026' : '#2E77FF')
          .shadow({
            radius: 26,
            color: this.floating ? '#66E84026' : '#662E77FF',
            offsetX: 0,
            offsetY: 12
          })
          .onClick(() => {
            this.toggleGuard();
          })

        Text(this.floating ? 'Shield is active on screen' : 'Tap Guard to start protecting')
          .fontSize(13)
          .fontColor('#7E8798')

        Row({ space: 7 }) {
          Circle({ width: 8, height: 8 })
            .fill(this.floating ? '#37C871' : '#3A4250')
          Text(this.floating ? 'Active' : 'Idle')
            .fontSize(13)
            .fontColor('#9AA3B2')
        }
      }

      Blank()

      Column({ space: 14 }) {
        Divider()
          .color('#232A34')
        Row() {
          Text('Dev mode')
            .fontSize(15)
            .fontColor('#CBD3DE')
            .layoutWeight(1)
          Toggle({ type: ToggleType.Switch, isOn: this.remote })
            .selectedColor('#2E77FF')
            .switchPointColor('#0E1116')
            .onChange((on: boolean) => {
              this.setDevMode(on);
            })
        }
        .width('100%')
      }
      .width('100%')
      .padding({ bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 28, right: 28, top: 48, bottom: 24 })
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#0E1116')
  }
}
