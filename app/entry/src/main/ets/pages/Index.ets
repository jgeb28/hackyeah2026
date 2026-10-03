import { mindSporeLite } from '@kit.MindSporeLiteKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

const TAG: string = 'AIProbe';
const DOMAIN: number = 0xFF00;

@Entry
@Component
struct Index {
  @State status: string = 'running inference...';
  @State detail: string = '';
  @State modelName: string = 'mobilenetv2.ms';

  aboutToAppear(): void {
    this.runProbe();
  }

  async runProbe(): Promise<void> {
    try {
      const ctx = getContext(this) as common.UIAbilityContext;
      const resMgr = ctx.resourceManager;
      const raw = await resMgr.getRawFileContent(this.modelName);
      const modelBuffer: ArrayBuffer = raw.buffer.slice(0);
      this.status = `model loaded (${(modelBuffer.byteLength / 1024 / 1024).toFixed(1)} MB)`;

      const context: mindSporeLite.Context = { target: ['cpu'] };
      context.cpu = {};
      context.cpu.threadNum = 2;
      context.cpu.threadAffinityMode = 1;
      context.cpu.precisionMode = 'enforce_fp32';

      const t0 = Date.now();
      const model: mindSporeLite.Model = await mindSporeLite.loadModelFromBuffer(modelBuffer, context);
      const inputs: mindSporeLite.MSTensor[] = model.getInputs();
      const inShape: number[] = inputs[0].shape as number[];
      const count: number = inShape.reduce((a: number, b: number) => a * b, 1);

      const inBuf = new ArrayBuffer(count * 4);
      const f32 = new Float32Array(inBuf);
      for (let i = 0; i < count; i++) {
        f32[i] = 0.5;
      }
      inputs[0].setData(inBuf);

      const outputs: mindSporeLite.MSTensor[] = await model.predict(inputs);
      const out = new Float32Array(outputs[0].getData());
      let maxV = -Infinity;
      let maxI = -1;
      for (let i = 0; i < out.length; i++) {
        if (out[i] > maxV) {
          maxV = out[i];
          maxI = i;
        }
      }
      const dt = Date.now() - t0;

      this.status = `INFERENCE OK (${dt} ms)`;
      this.detail = `in=${JSON.stringify(inShape)}  out=${out.length}\ntop1 idx=${maxI} val=${maxV.toFixed(5)}`;
      hilog.info(DOMAIN, TAG, 'predict success in %{public}d ms, outLen %{public}d, top1 %{public}d',
        dt, out.length, maxI);
    } catch (e) {
      const err = e as BusinessError;
      this.status = `ERROR ${err.code}`;
      this.detail = `${err.message}`;
      hilog.error(DOMAIN, TAG, 'error: %{public}s', JSON.stringify(e));
    }
  }

  build() {
    Column({ space: 14 }) {
      Text('On-device AI probe').fontSize(20).fontWeight(FontWeight.Medium)
      Text(this.status).fontSize(22).fontWeight(FontWeight.Bold).textAlign(TextAlign.Center)
      Text(this.detail).fontSize(14).textAlign(TextAlign.Center).fontColor('#666')
      Text('MindSpore Lite · CPU · emulator').fontSize(12).fontColor('#999')
    }
    .width('100%')
    .height('100%')
    .padding(24)
    .justifyContent(FlexAlign.Center)
  }
}
