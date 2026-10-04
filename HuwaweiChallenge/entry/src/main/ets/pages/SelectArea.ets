// Region selector: press and drag to draw a box around the text to scan.
// Lives in the full-screen SelectorOverlay window; hands the vp rect back on confirm.
import { display } from '@kit.ArkUI';
import { SelectorOverlay } from '../alert/SelectorOverlay';

@Entry
@Component
struct SelectArea {
  @State started: boolean = false;
  @State dragging: boolean = false;
  @State x1: number = 0;
  @State y1: number = 0;
  @State x2: number = 0;
  @State y2: number = 0;
  private screenH: number = 800;

  aboutToAppear(): void {
    const d: display.Display = display.getDefaultDisplaySync();
    this.screenH = d.height / d.densityPixels;
  }

  private left(): number {
    return Math.min(this.x1, this.x2);
  }

  private top(): number {
    return Math.min(this.y1, this.y2);
  }

  private boxW(): number {
    return Math.abs(this.x2 - this.x1);
  }

  private boxH(): number {
    return Math.abs(this.y2 - this.y1);
  }

  private complete(): boolean {
    return this.started && !this.dragging && this.boxW() > 10 && this.boxH() > 10;
  }

  private onTouchEvent(event: TouchEvent): void {
    const t: TouchObject | null = event.touches.length > 0
      ? event.touches[0]
      : (event.changedTouches.length > 0 ? event.changedTouches[0] : null);
    if (t === null) {
      return;
    }
    if (event.type === TouchType.Down) {
      this.started = true;
      this.dragging = true;
      this.x1 = t.x;
      this.y1 = t.y;
      this.x2 = t.x;
      this.y2 = t.y;
    } else if (event.type === TouchType.Move) {
      if (this.dragging) {
        this.x2 = t.x;
        this.y2 = t.y;
      }
    } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
      this.dragging = false;
    }
  }

  private hint(): string {
    if (this.dragging) {
      return 'Drag to box the text you want to scan';
    }
    if (this.complete()) {
      return 'Adjust if needed, then scan this area';
    }
    return 'Drag to select the area to scan';
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // Dim layer + touch surface (bottom of the stack).
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0,0,0,0.45)')
        .onTouch((e: TouchEvent) => {
          this.onTouchEvent(e);
        })

      // Selection rectangle.
      if (this.started && this.boxW() > 1 && this.boxH() > 1) {
        Column()
          .position({ x: this.left(), y: this.top() })
          .width(this.boxW())
          .height(this.boxH())
          .border({ width: 2, color: '#2E77FF' })
          .backgroundColor('rgba(46,119,255,0.12)')
          .hitTestBehavior(HitTestMode.None)
      }

      // Top hint.
      Column() {
        Text(this.hint())
          .fontSize(15)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .padding({ top: 150, left: 32, right: 32 })
      .alignItems(HorizontalAlign.Center)
      .hitTestBehavior(HitTestMode.None)

      // Bottom actions.
      if (this.complete()) {
        Row({ space: 12 }) {
          Button('Scan this area')
            .fontSize(15)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#2E77FF')
            .fontColor(Color.White)
            .onClick(() => {
              SelectorOverlay.finish(this.left(), this.top(), this.boxW(), this.boxH());
            })
          Button('Cancel')
            .fontSize(15)
            .height(44)
            .layoutWeight(1)
            .backgroundColor('#33FFFFFF')
            .fontColor(Color.White)
            .onClick(() => {
              SelectorOverlay.cancel();
            })
        }
        .width('100%')
        .padding({ left: 24, right: 24 })
        .position({ x: 0, y: this.screenH - 120 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
