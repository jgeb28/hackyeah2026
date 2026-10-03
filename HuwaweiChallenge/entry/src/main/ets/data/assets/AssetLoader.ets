import { util } from '@kit.ArkTS';
import { resourceManager } from '@kit.LocalizationKit';

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
}
