import { UIAbility } from '@kit.AbilityKit';
import { ConfigurationConstant } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN: number = 0x4141;

export default class EntryAbility extends UIAbility {
  onForeground(): void {
    AppStorage.setOrCreate('almanacForegroundTick', Date.now());
  }

  onCreate(): void {
    try {
      this.context.getApplicationContext()
        .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
    } catch (error) {
      hilog.warn(DOMAIN, 'AcademicAlmanac', 'Unable to lock light color mode: %{public}s',
        JSON.stringify(error));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        hilog.error(DOMAIN, 'AcademicAlmanac', 'Load page failed: %{public}s', JSON.stringify(error));
      }
    });
  }
}
