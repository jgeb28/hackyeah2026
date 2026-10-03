import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { AccelerationInfo } from '../data/datasource/NnrtAccelerationProbe';
import { AppContainer } from '../di/AppContainer';
import { MessageAnalysis, Verdict } from '../domain/model/Decision';
import { AnswerPopup } from '../presentation/components/AnswerPopup';

const DOMAIN: number = 0x0000;
const TAG: string = 'Guardian';

/** A suspicious message used as the demo state for Laya. */
const SAMPLE_MESSAGE: string =
  'URGENT: This is your bank. Your account has been locked. Verify immediately at ' +
  'http://secure-verify-bank.tj49.com and confirm your card number and PIN, or your ' +
  'funds will be frozen today.';

/**
 * Guardian ÔÇö main page.
 *
 * Shows the **question** (instead of "Hello World"). Tapping it runs Laya
 * on-device through `AnalyseMessageUseCase` and opens `AnswerPopup`. All model
 * access goes through the domain use case; this page never touches MindSpore or
 * any transport directly. There is no network path.
 */
@Entry
@Component
struct LayaDemo {
  private container: AppContainer | null = null;

  @State message: string = 'Is this message a scam?';
  @State running: boolean = false;
  @State showPopup: boolean = false;
  @State analysis: MessageAnalysis = new MessageAnalysis();
  @State sourceLabel: string = 'on-device';

  aboutToAppear(): void {
    const context = getContext(this) as common.UIAbilityContext;
    const container = new AppContainer(context);
    this.container = container;
    hilog.info(DOMAIN, TAG, 'filesDir (push the model here): %{public}s', context.filesDir);

    const acceleration: AccelerationInfo = container.acceleration();
    const hardware: string = acceleration.available ? acceleration.backend : 'CPU (no NPU)';
    this.sourceLabel = `on-device MindSpore Lite ┬Ě ${hardware}`;
    hilog.info(DOMAIN, TAG, 'On-device backend. accelerator=%{public}s %{public}s',
      acceleration.available ? 'yes' : 'no', acceleration.devices);
  }

  private async analyse(): Promise<void> {
    if (this.running || this.container === null) {
      return;
    }
    this.running = true;
    try {
      this.analysis = await this.container.analyseMessage.run(SAMPLE_MESSAGE);
    } catch (error) {
      const err = error as Error;
      hilog.error(DOMAIN, TAG, 'On-device analysis failed: %{public}s | %{public}s',
        err.message !== undefined ? err.message : String(error),
        err.stack !== undefined ? err.stack : '');
      const failed = new MessageAnalysis();
      failed.verdict = Verdict.UNKNOWN;
      failed.summary = 'The on-device model is unavailable. Check the bundled model assets.';
      failed.model = 'n/a';
      this.analysis = failed;
    } finally {
      this.running = false;
      this.showPopup = true;
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        Text(this.message)
          .id('GuardianQuestion')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor('#182431')
          .textAlign(TextAlign.Center)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            this.analyse();
          })

        Text('Tap the question to ask Laya (on-device).')
          .fontSize(13)
          .fontColor('#8A8F99')
          .margin({ top: 10 })

        Text(SAMPLE_MESSAGE)
          .fontSize(14)
          .fontColor('#5A6069')
          .lineHeight(20)
          .padding(14)
          .margin({ top: 22, left: 20, right: 20 })
          .backgroundColor(Color.White)
          .borderRadius(14)
          .textAlign(TextAlign.Start)

        if (this.running) {
          LoadingProgress()
            .width(42)
            .height(42)
            .color('#0A59F7')
            .margin({ top: 22 })
          Text('Running Laya on-deviceÔÇŽ')
            .fontSize(13)
            .fontColor('#8A8F99')
            .margin({ top: 8 })
        }

        Text(`offline ┬Ě ${this.sourceLabel}`)
          .fontSize(11)
          .fontColor('#99A0A6')
          .margin({ top: 22 })
          .padding({ left: 16, right: 16 })
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)

      if (this.showPopup) {
        AnswerPopup({
          question: this.message,
          analysis: this.analysis,
          sourceLabel: this.sourceLabel,
          onDismiss: () => {
            this.showPopup = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F1F3F5')
  }
}