// Content of the floating smart-island window (transparent; the island is the only visible part).
// A scam result's "Details" opens the incident page *inside this window* — a
// background app may not start an ability, so we never leave the floating window.
import { router } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { IslandOverlay } from '../alert/IslandOverlay';
import { SmartIsland } from '../components/SmartIsland';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianIsland';

interface DetailParams {
  json: string;
  text: string;
}

@Entry
@Component
struct FloatingIsland {
  private openDetails(json: string, text: string): void {
    const params: DetailParams = { json: json, text: text };
    IslandOverlay.setDetailMode(true);
    this.getUIContext().getRouter()
      .pushUrl({ url: 'pages/IncidentDetail', params: params })
      .catch((e: Object) => {
        hilog.warn(DOMAIN, TAG, 'detail nav failed: %{public}s', JSON.stringify(e));
      });
  }

  /** Back from the detail page: shrink the window to the island again. */
  onPageShow(): void {
    IslandOverlay.setDetailMode(false);
  }

  build() {
    Column() {
      SmartIsland({
        onClose: () => {
          IslandOverlay.close();
        },
        onResize: (expanded: boolean) => {
          IslandOverlay.resize(expanded);
        },
        onDetails: (json: string, text: string) => {
          this.openDetails(json, text);
        }
      })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 8, left: 12, right: 12 })
    .alignItems(HorizontalAlign.Center)
  }
}
