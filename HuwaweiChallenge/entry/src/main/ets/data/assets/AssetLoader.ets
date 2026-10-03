import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';
import { fileIo as fs, ReadOptions, WriteOptions } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0x0000;
const TAG: string = 'AssetLoader';

/**
 * Reads bundled rawfile assets (the `.ms` graph, the tokenizer). Kept behind an
 * interface so the data layer can be unit-tested with a fake loader and does not
 * depend on the UI context.
 */
export interface AssetLoader {
  /** Read a text asset (e.g. tokenizer.json) fully into a string. */
  readText(name: string): Promise<string>;
  /** Open a binary asset and return its file descriptor (for loadModelFromFd). */
  openFd(name: string): number;
  /** True if a real file exists at `path`. */
  fileExists(path: string): boolean;
  /**
   * Copy a bundled rawfile into a real sandbox file.
   *
   * The descriptor from `getRawFdSync` points at the **whole HAP**: `fd` is the
   * HAP, and the asset lives at `[offset, offset + length)`. MindSpore Lite's
   * `loadModelFromFd` reads from position 0, so it must not receive this fd for
   * a non-zero offset — we copy the exact region to a real file instead.
   *
   * @returns number of bytes copied.
   */
  copyRawfileTo(name: string, destPath: string): Promise<number>;
}

export class RawfileAssetLoader implements AssetLoader {
  private readonly manager: resourceManager.ResourceManager;

  constructor(manager: resourceManager.ResourceManager) {
    this.manager = manager;
  }

  async readText(name: string): Promise<string> {
    const bytes: Uint8Array = await this.manager.getRawFileContent(name);
    const decoder = util.TextDecoder.create('utf-8');
    return decoder.decodeToString(bytes);
  }

  openFd(name: string): number {
    const descriptor: resourceManager.RawFileDescriptor = this.manager.getRawFdSync(name);
    return descriptor.fd;
  }

  fileExists(path: string): boolean {
    try {
      return fs.accessSync(path);
    } catch (error) {
      return false;
    }
  }

  async copyRawfileTo(name: string, destPath: string): Promise<number> {
    const descriptor: resourceManager.RawFileDescriptor = this.manager.getRawFdSync(name);
    const src: number = descriptor.fd;
    const start: number = descriptor.offset;
    const total: number = descriptor.length;
    const chunk: number = 8 * 1024 * 1024;

    // The fd points at the whole HAP; the asset starts at `offset`. Seek there
    // by reading sequentially (avoids `offset` interpretation differences) and
    // then stream the remaining bytes; the first chunk is validated as a
    // MINDIR_LITE flatbuffer (a 4-byte length then ASCII "MSL2").
    const skipBuffer: ArrayBuffer = new ArrayBuffer(chunk);
    let skipped: number = 0;
    while (skipped < start) {
      const skipOpts: ReadOptions = { length: Math.min(chunk, start - skipped) };
      const n: number = await fs.read(src, skipBuffer, skipOpts);
      if (n <= 0) {
        break;
      }
      skipped += n;
    }
    if (skipped !== start) {
      throw new Error(`rawfile ${name}: seek to offset ${start} failed (reached ${skipped})`);
    }

    const tmpPath: string = `${destPath}.part`;
    const file: fs.File = await fs.open(tmpPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
    const dst: number = file.fd;
    const buffer: ArrayBuffer = new ArrayBuffer(chunk);
    let done: number = 0;
    let hex: string = '';
    try {
      while (done < total) {
        const readOpts: ReadOptions = { length: Math.min(chunk, total - done) };
        const read: number = await fs.read(src, buffer, readOpts);
        if (read <= 0) {
          break;
        }
        if (done === 0) {
          const head: Uint8Array = new Uint8Array(buffer, 0, Math.min(8, read));
          for (let i = 0; i < head.length; i++) {
            hex += head[i].toString(16).padStart(2, '0');
          }
        }
        const writeOpts: WriteOptions = { length: read };
        await fs.write(dst, buffer, writeOpts);
        done += read;
      }
    } finally {
      await fs.close(dst);
    }

    hilog.info(DOMAIN, TAG, 'rawfile %{public}s offset=%{public}d length=%{public}d magic=%{public}s',
      name, start, total, hex);
    if (!hex.startsWith('280000004d534c32')) {
      throw new Error(`rawfile ${name} is not a MINDIR_LITE model (magic=${hex})`);
    }
    if (done !== total) {
      throw new Error(`rawfile ${name} copy incomplete: ${done}/${total} bytes`);
    }

    // Atomic publish: a partial copy can never be mistaken for a valid model.
    await fs.rename(tmpPath, destPath);
    hilog.info(DOMAIN, TAG, 'copied %{public}d bytes to %{public}s', done, destPath);
    return done;
  }
}
