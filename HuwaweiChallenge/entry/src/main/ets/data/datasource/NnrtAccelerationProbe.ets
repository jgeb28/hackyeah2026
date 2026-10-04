import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'Accel';

/** Result of probing the OS for AI acceleration hardware. */
export class AccelerationInfo {
  available: boolean = false;
  backend: string = 'CPU';
  devices: string = '';
  /** NNRt device id to target (-1 = none → use CPU). */
  deviceID: number = -1;
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
        let acceleratorId: number = -1;
        let fallbackId: number = -1;
        for (let i = 0; i < devices.length; i++) {
          const type: number = devices[i].deviceType();
          const id: number = Number(devices[i].deviceID());
          names.push(`${devices[i].deviceName()} (type ${type})`);
          if (type === mindSporeLite.NNRTDeviceType.NNRTDEVICE_ACCELERATOR && acceleratorId < 0) {
            acceleratorId = id;
          }
          if (fallbackId < 0 && type !== mindSporeLite.NNRTDeviceType.NNRTDEVICE_CPU) {
            fallbackId = id;
          }
        }
        info.available = true;
        info.backend = acceleratorId >= 0 ? 'NNRt accelerator (NPU)' : 'NNRt';
        info.devices = names.join(', ');
        info.deviceID = acceleratorId >= 0 ? acceleratorId : fallbackId;
        hilog.info(DOMAIN, TAG, 'NNRt devices: %{public}s', info.devices);
        hilog.info(DOMAIN, TAG, 'NNRt selected deviceID=%{public}d backend=%{public}s',
          info.deviceID, info.backend);
      }
    } catch (error) {
      const message: string = (error as Error).message !== undefined ? (error as Error).message : '';
      hilog.warn(DOMAIN, TAG, 'NNRt unavailable: %{public}s', message);
    }
    return info;
  }
}
