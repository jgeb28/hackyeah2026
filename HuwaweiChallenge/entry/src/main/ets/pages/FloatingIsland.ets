// Content of the floating smart-island window (transparent; the island is the only visible part).
import { IslandOverlay } from '../alert/IslandOverlay';
import { SmartIsland } from '../components/SmartIsland';

@Entry
@Component
struct FloatingIsland {
  build() {
    Column() {
      SmartIsland({
        onClose: () => {
          IslandOverlay.close();
        },
        onResize: (expanded: boolean) => {
          IslandOverlay.resize(expanded);
        }
      })
    }
    .width('100%')
    .height('100%')
    .padding({ top: 8, left: 12, right: 12 })
    .alignItems(HorizontalAlign.Center)
  }
}
