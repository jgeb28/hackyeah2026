import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { notificationManager } from '@kit.NotificationKit';
import { window } from '@kit.ArkUI';
import { AlertOverlay } from '../alert/AlertOverlay';
import { AlertTheme } from '../alert/AlertTheme';
import { IncidentKnowledge } from '../kb/IncidentKnowledge';
import { InAppSdkSource } from '../sdk/InAppSdkSource';
import { ScanJob } from '../trigger/IngestSource';
import { TriggerEngine } from '../trigger/TriggerEngine';
import { TriggerSource } from '../trigger/TriggerTypes';
import { MockTriggerController } from '../trigger/MockTriggerController';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private source: InAppSdkSource = new InAppSdkSource();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    // Interception pipeline: observe SDK reports, classify, alert (overlay + notification).
    AlertOverlay.setContext(this.context);
    AlertTheme.load(this.context);
    IncidentKnowledge.load(this.context);
    this.source.start((job: ScanJob) => {
      TriggerEngine.get().onReport(job.bundleName, job.text, job.category, job.severity, TriggerSource.SDK);
    });
    MockTriggerController.register();
    notificationManager.requestEnableNotification(this.context).catch((e: Object) => {
      hilog.warn(DOMAIN, 'testTag', 'requestEnableNotification: %{public}s', JSON.stringify(e));
    });
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    MockTriggerController.unregister();
    this.source.stop();
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
