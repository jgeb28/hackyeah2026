// IncidentDetailView — renders a KB-shape incident JSON as readable text:
// title, severity/category, description, explanation, remediation steps and sources.
// Text only: no buttons, links, or images. Data-in / UI-out; no OCR or LAYA calls.
import { IncidentDoc, parseIncident } from '../detail/DetailTypes';
import { AlertTheme } from '../alert/AlertTheme';

@Component
export struct IncidentDetailView {
  @Prop @Watch('reload') json: string = '';
  @State doc: IncidentDoc | null = null;
  /** Whether to offer the (optional, cloud) DeepSeek "Describe" action. */
  @Prop canDescribe: boolean = false;
  @Prop describeStatus: string = 'idle'; // idle | loading | done | error
  @Prop describeText: string = '';
  onDescribe: () => void = () => {};

  aboutToAppear(): void {
    this.reload();
  }

  private reload(): void {
    this.doc = parseIncident(this.json);
  }

  @Builder
  section(heading: string, body: string) {
    if (body.length > 0) {
      Column({ space: 4 }) {
        Text(heading)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A8F99')
          .width('100%')
        Text(body)
          .fontSize(15)
          .fontColor('#182431')
          .lineHeight(22)
          .width('100%')
      }
      .width('100%')
    }
  }

  @Builder
  steps(heading: string, items: string[]) {
    if (items.length > 0) {
      Column({ space: 8 }) {
        Text(heading)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor('#8A8F99')
          .width('100%')
        ForEach(items, (item: string, index: number) => {
          Row({ space: 8 }) {
            Text(`${index + 1}.`)
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#182431')
            Text(item)
              .fontSize(15)
              .fontColor('#182431')
              .lineHeight(22)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(VerticalAlign.Top)
        }, (item: string, index: number) => `${index}-${item}`)
      }
      .width('100%')
    }
  }

  @Builder
  content(doc: IncidentDoc) {
    Scroll() {
      Column({ space: 18 }) {
        Row({ space: 8 }) {
          Text(doc.severity)
            .fontSize(12)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .backgroundColor(AlertTheme.colorForSeverity(doc.severity))
            .borderRadius(12)
          if (doc.category.length > 0) {
            Text(doc.category)
              .fontSize(12)
              .fontColor('#8A8F99')
          }
        }
        .width('100%')

        Text(doc.title)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .width('100%')

        if (this.canDescribe) {
          Column({ space: 6 }) {
            if (this.describeStatus === 'loading') {
              Row({ space: 8 }) {
                LoadingProgress().width(18).height(18).color('#0A59F7')
                Text('Asking DeepSeek…').fontSize(14).fontColor('#8A8F99')
              }
              .width('100%')
            } else {
              Button('Describe with DeepSeek')
                .fontSize(14)
                .height(40)
                .width('100%')
                .backgroundColor('#0A59F7')
                .fontColor(Color.White)
                .onClick(() => {
                  this.onDescribe();
                })
              Text('Sends the scanned text and incident details to DeepSeek.')
                .fontSize(11)
                .fontColor('#8A8F99')
                .width('100%')
            }
            if (this.describeStatus === 'done' && this.describeText.length > 0) {
              Text(this.describeText)
                .fontSize(15)
                .lineHeight(22)
                .fontColor('#182431')
                .width('100%')
                .padding(12)
                .backgroundColor('#EAF2FF')
                .borderRadius(10)
            }
            if (this.describeStatus === 'error' && this.describeText.length > 0) {
              Text(this.describeText)
                .fontSize(13)
                .fontColor('#E84026')
                .width('100%')
            }
          }
          .width('100%')
        }

        this.section('What this is', doc.description)
        this.section('Why it matters', doc.explanation)
        this.steps('What to do', doc.remediation)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .padding(24)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .align(Alignment.Top)
  }

  build() {
    Column() {
      if (this.doc === null) {
        Column({ space: 8 }) {
          Text('Could not read this incident')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#E84026')
          Text('The supplied details were empty or not valid JSON.')
            .fontSize(13)
            .fontColor('#8A8F99')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        this.content(this.doc)
      }
    }
    .width('100%')
    .height('100%')
  }
}
