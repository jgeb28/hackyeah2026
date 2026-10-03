import { DynamicIslandAlert } from '../components/DynamicIslandAlert';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  @State showIsland: boolean = false;

  build() {
    Stack({ alignContent: Alignment.Top }) {
      RelativeContainer() {
        Text(this.message)
          .id('HelloWorld')
          .fontSize($r('app.float.page_text_font_size'))
          .fontWeight(FontWeight.Bold)
          .alignRules({
            center: { anchor: '__container__', align: VerticalAlign.Center },
            middle: { anchor: '__container__', align: HorizontalAlign.Center }
          })
          .onClick(() => {
            // Tapping the app shows the "Dynamic Island" at the top
            // instead of the "Welcome" screen.
            this.showIsland = true;
          })
      }
      .height('100%')
      .width('100%')

      // Dynamic Island: slides in from the top and renders above the content.
      if (this.showIsland) {
        Column() {
          DynamicIslandAlert({
            // Collapsed state: keep it short and general.
            shortText: 'Suspicious message',
            // Expanded state: pass your own text here to override the default.
            title: 'Suspicious message',
            detail: 'This message may be a phishing attempt. For your safety, do not open any links and never share passwords or verification codes.',
            onDismiss: () => {
              this.showIsland = false;
            }
          })
        }
        .width('100%')
        .padding({ top: 8 })
        .transition(TransitionEffect.move(TransitionEdge.TOP).animation({ duration: 420, curve: Curve.Friction }))
      }
    }
    .height('100%')
    .width('100%')
  }
}
