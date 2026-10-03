/**
 * DemoAbility — hosts the in-app TriggerDemo page so the trigger can be
 * validated locally (including on emulators where the accessibility service
 * cannot be enabled). Start it directly:
 *
 *   hdc shell "aa start -a DemoAbility -b com.example.huwaweichallenge"
 */
import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0A11;

export default class DemoAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'GuardianDemo', 'DemoAbility onCreate');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/TriggerDemo', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'GuardianDemo', 'loadContent failed: %{public}s', JSON.stringify(err));
      }
    });
  }
}
