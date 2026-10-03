import { AssetLoader } from '../assets/AssetLoader';

/**
 * ByteLevel BPE tokenizer for Laya, running fully on-device.
 *
 * Laya's tokenizer (`tokenizer/tokenizer.json`, HuggingFace fast tokenizer) is a
 * GPT-2 style **ByteLevel BPE** with an NFC normalizer and a `[CLS] … [SEP]`
 * post-processor — not WordPiece. This class reads that same file from rawfile
 * and reproduces the encoding in ArkTS so no text ever leaves the device.
 *
 * NOTE: this port is written against the tokenizer definition but has **not yet
 * been diffed against the Python tokenizer on device** (see LAYA_INTEGRATION.md).
 * `MindSporeLiteEngine` validates ids against the vocabulary it loaded.
 */

/**
 * GPT-2 pre-tokenization pattern (ByteLevel pre_tokenizer with use_regex).
 *
 * ArkTS rejects regex literals (`arkts-no-regexp-literals`), so this MUST be
 * built with `RegExp()`. Some ArkTS engines also lack Unicode property escapes
 * (`\p{L}`/`\p{N}`); if so we fall back to ASCII classes, which is identical for
 * English input (the demo/model domain). Non-ASCII letters then tokenize as
 * "other", a documented deviation.
 */
function buildPreTokenizer(): RegExp {
  try {
    return new RegExp(
      "'s|'t|'re|'ve|'m|'ll|'d| ?\\p{L}+| ?\\p{N}+| ?[^\\s\\p{L}\\p{N}]+|\\s+(?!\\S)|\\s+",
      'gu');
  } catch (error) {
    return new RegExp(
      "'s|'t|'re|'ve|'m|'ll|'d| ?[A-Za-z]+| ?[0-9]+| ?[^\\sA-Za-z0-9]+|\\s+(?!\\S)|\\s+",
      'g');
  }
}

const PRE_TOKENIZER: RegExp = buildPreTokenizer();

interface TokenizerModelDto {
  vocab?: Record<string, number>;
  merges?: string[][];
}

interface AddedTokenDto {
  id?: number;
  content?: string;
}

interface TokenizerDto {
  model?: TokenizerModelDto;
  added_tokens?: AddedTokenDto[];
}

export class SpecialTokens {
  cls: number = 0;
  sep: number = 0;
  pad: number = 0;
  mask: number = 0;
  unk: number = 0;
}

export class BpeTokenizer {
  private vocab: Map<string, number> = new Map();
  private ranks: Map<string, number> = new Map();
  private byteToChar: string[] = [];
  private ready: boolean = false;
  specials: SpecialTokens = new SpecialTokens();

  async load(assets: AssetLoader, path: string): Promise<void> {
    const json: string = await assets.readText(path);
    this.loadFromJson(json);
  }

  /** Build the tokenizer from the Hugging Face `tokenizer.json` text. */
  loadFromJson(json: string): void {
    const dto: TokenizerDto = JSON.parse(json) as TokenizerDto;

    const model: TokenizerModelDto | undefined = dto.model;
    if (model !== undefined && model.vocab !== undefined) {
      const tokens: string[] = Object.keys(model.vocab);
      for (const token of tokens) {
        this.vocab.set(token, model.vocab[token]);
      }
    }
    if (model !== undefined && model.merges !== undefined) {
      for (let i = 0; i < model.merges.length; i++) {
        const pair: string[] = model.merges[i];
        if (pair.length === 2) {
          this.ranks.set(`${pair[0]}\u0000${pair[1]}`, i);
        }
      }
    }

    const added: AddedTokenDto[] | undefined = dto.added_tokens;
    if (added !== undefined) {
      for (const token of added) {
        if (token.content === undefined || token.id === undefined) {
          continue;
        }
        if (token.content === '[CLS]') {
          this.specials.cls = token.id;
        } else if (token.content === '[SEP]') {
          this.specials.sep = token.id;
        } else if (token.content === '[PAD]') {
          this.specials.pad = token.id;
        } else if (token.content === '[MASK]') {
          this.specials.mask = token.id;
        } else if (token.content === '[UNK]') {
          this.specials.unk = token.id;
        }
      }
    }

    this.byteToChar = buildByteToChar();
    this.ready = true;
  }

  isReady(): boolean {
    return this.ready;
  }

  /** Token ids for `text`, excluding the [CLS]/[SEP] wrapper. */
  encode(text: string): number[] {
    let normalized: string = text;
    try {
      normalized = text.normalize('NFC');
    } catch (error) {
      // NFC unavailable on this engine — use the raw text.
    }

    const ids: number[] = [];
    const pieces: RegExpMatchArray | null = normalized.match(PRE_TOKENIZER);
    if (pieces === null) {
      return ids;
    }
    for (const piece of pieces) {
      const mapped: string = this.toByteChars(piece);
      const symbols: string[] = toCodePoints(mapped);
      const merged: string[] = this.merge(symbols);
      for (const symbol of merged) {
        const id: number | undefined = this.vocab.get(symbol);
        ids.push(id !== undefined ? id : this.specials.unk);
      }
    }
    return ids;
  }

  /** Token ids for `text`, truncated/padded to `stateLen` (the graph's state window). */
  encodeState(text: string, stateLen: number): number[] {
    const tokens: number[] = this.encode(text);
    const out: number[] = new Array<number>(stateLen);
    for (let i = 0; i < stateLen; i++) {
      out[i] = i < tokens.length ? tokens[i] : this.specials.pad;
    }
    return out;
  }

  private toByteChars(piece: string): string {
    const bytes: number[] = utf8Bytes(piece);
    let out: string = '';
    for (const b of bytes) {
      out += this.byteToChar[b];
    }
    return out;
  }

  private merge(symbols: string[]): string[] {
    let word: string[] = symbols;
    while (word.length > 1) {
      let bestRank: number = Number.MAX_SAFE_INTEGER;
      let bestIndex: number = -1;
      for (let i = 0; i < word.length - 1; i++) {
        const rank: number | undefined = this.ranks.get(`${word[i]}\u0000${word[i + 1]}`);
        if (rank !== undefined && rank < bestRank) {
          bestRank = rank;
          bestIndex = i;
        }
      }
      if (bestIndex < 0) {
        break;
      }
      const merged: string[] = [];
      let i = 0;
      while (i < word.length) {
        if (i === bestIndex) {
          merged.push(word[i] + word[i + 1]);
          i += 2;
        } else {
          merged.push(word[i]);
          i += 1;
        }
      }
      word = merged;
    }
    return word;
  }
}

/** GPT-2 bytes_to_unicode(): map each byte value to a printable code point. */
function buildByteToChar(): string[] {
  const table: string[] = new Array<string>(256);
  const direct: number[] = [];
  for (let b = 33; b <= 126; b++) {
    direct.push(b);
  }
  for (let b = 161; b <= 172; b++) {
    direct.push(b);
  }
  for (let b = 174; b <= 255; b++) {
    direct.push(b);
  }
  const isDirect = new Array<boolean>(256).fill(false);
  for (const b of direct) {
    isDirect[b] = true;
  }
  let extra: number = 0;
  for (let b = 0; b < 256; b++) {
    if (isDirect[b]) {
      table[b] = String.fromCodePoint(b);
    } else {
      table[b] = String.fromCodePoint(256 + extra);
      extra += 1;
    }
  }
  return table;
}

/** Split a string into code points (surrogate-pair safe). */
function toCodePoints(text: string): string[] {
  const out: string[] = [];
  let i: number = 0;
  while (i < text.length) {
    const code: number = text.codePointAt(i) as number;
    out.push(String.fromCodePoint(code));
    i += code > 0xFFFF ? 2 : 1;
  }
  return out;
}

/** UTF-8 encode a string into raw bytes. */
function utf8Bytes(text: string): number[] {
  const bytes: number[] = [];
  for (const ch of toCodePoints(text)) {
    const code: number = ch.codePointAt(0) as number;
    if (code < 0x80) {
      bytes.push(code);
    } else if (code < 0x800) {
      bytes.push(0xC0 | (code >> 6));
      bytes.push(0x80 | (code & 0x3F));
    } else if (code < 0x10000) {
      bytes.push(0xE0 | (code >> 12));
      bytes.push(0x80 | ((code >> 6) & 0x3F));
      bytes.push(0x80 | (code & 0x3F));
    } else {
      bytes.push(0xF0 | (code >> 18));
      bytes.push(0x80 | ((code >> 12) & 0x3F));
      bytes.push(0x80 | ((code >> 6) & 0x3F));
      bytes.push(0x80 | (code & 0x3F));
    }
  }
  return bytes;
}
