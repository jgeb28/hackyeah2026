// OcrDemo — runs the PP-OCRv4 pipeline on a bundled sample image so the OCR
// path can be demonstrated on the emulator (AVScreenCapture is device-only).
import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { extractTextFromImage } from '../ocr/OcrEngine';
import { OcrResult } from '../ocr/OcrTypes';

const DOMAIN: number = 0x0A11;
const TAG: string = 'GuardianOcrDemo';

@Entry
@Component
struct OcrDemo {
  @State status: string = 'idle';
  @State lines: string[] = [];
  @State elapsedMs: number = 0;

  aboutToAppear(): void {
    this.run();
  }

  private async run(): Promise<void> {
    this.status = 'loading models + decoding image...';
    this.lines = [];
    try {
      const mgr = getContext(this).resourceManager;
      const bytes: Uint8Array = await mgr.getRawFileContent('ocr/sample.png');
      const src = image.createImageSource(bytes.buffer);
      const pixelMap = await src.createPixelMap();

      const t0 = Date.now();
      const result: OcrResult = await extractTextFromImage(pixelMap, mgr);
      this.elapsedMs = Date.now() - t0;

      const out: string[] = [];
      for (const line of result.lines) {
        out.push(`${line.text}  (${line.confidence.toFixed(2)})`);
      }
      this.lines = out;
      this.status = `done: ${result.lines.length} lines in ${this.elapsedMs} ms`;
      hilog.info(DOMAIN, TAG, `ocr done in ${this.elapsedMs} ms, ${result.lines.length} lines`);
    } catch (err) {
      this.status = `error: ${err}`;
      hilog.error(DOMAIN, TAG, `ocr failed: ${err}`);
    }
  }

  build() {
    Column({ space: 12 }) {
      Text('Guardian OCR (PP-OCRv4)')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
      Text(this.status)
        .fontSize(14)
      Button('Run OCR on sample')
        .onClick(() => {
          this.run();
        })
      Scroll() {
        Column({ space: 6 }) {
          ForEach(this.lines, (line: string) => {
            Text(line).fontSize(14).width('100%')
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
    }
    .padding(20)
    .width('100%')
    .height('100%')
  }
}
