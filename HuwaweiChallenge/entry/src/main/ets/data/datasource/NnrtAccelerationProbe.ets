import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'Accel';

/** Result of probing the OS for AI acceleration hardware. */
export class AccelerationInfo {
  available: boolean = false;
  backend: string = 'CPU';
  devices: string = '';
}

/**
 * Asks the OS whether an AI accelerator (NNRt → Kirin NPU) is present.
 *
 * On the Oniro/OpenHarmony emulator this reports none (CPU-only, per DESIGN.md
 * §4); on a Kirin phone it reports the accelerator. This is real use of the
 * platform capability and lets the UI state the actual backend.
 */
export class NnrtAccelerationProbe {
  probe(): AccelerationInfo {
    const info = new AccelerationInfo();
    try {
      const devices = mindSporeLite.getAllNNRTDeviceDescriptions();
      if (devices !== null && devices.length > 0) {
        const names: string[] = [];
        for (let i = 0; i < devices.length; i++) {
          names.push(`${devices[i].deviceName()} (type ${devices[i].deviceType()})`);
        }
        info.available = true;
        info.backend = 'NNRt accelerator (NPU)';
        info.devices = names.join(', ');
      }
    } catch (error) {
      hilog.warn(DOMAIN, TAG, 'NNRt probe failed: %{public}s', JSON.stringify(error));
    }
    return info;
  }
}
