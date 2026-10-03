#!/usr/bin/env python3
"""Validate the ArkTS BpeTokenizer algorithm against Hugging Face's tokenizer.

Reimplements EXACTLY the logic in BpeTokenizer.ets (bytes_to_unicode, GPT-2
pre-tokenizer regex, greedy BPE by merge-rank, vocab lookup) in Python and
compares to AutoTokenizer on the sample messages.
"""
import json

import regex

from transformers import AutoTokenizer
from try_laya import SAMPLES

TOK_JSON = "laya_model/tokenizer/tokenizer.json"
PRE = regex.compile(r"'s|'t|'re|'ve|'m|'ll|'d| ?\p{L}+| ?\p{N}+| ?[^\s\p{L}\p{N}]+|\s+(?!\S)|\s+")

d = json.load(open(TOK_JSON))
vocab = d["model"]["vocab"]
merges = d["model"]["merges"]
ranks = {}
for i, m in enumerate(merges):
    a, b = m
    ranks[(a, b)] = i
added = {t["content"]: t["id"] for t in d["added_tokens"]}
UNK = added.get("[UNK]", 0)


def bytes_to_unicode():
    bs = list(range(33, 127)) + list(range(161, 173)) + list(range(174, 256))
    cs = bs[:]
    n = 0
    for b in range(256):
        if b not in bs:
            bs.append(b)
            cs.append(256 + n)
            n += 1
    return {b: chr(c) for b, c in zip(bs, cs)}


B2U = bytes_to_unicode()


def bpe(word):
    while len(word) > 1:
        best_rank, best_i = None, -1
        for i in range(len(word) - 1):
            r = ranks.get((word[i], word[i + 1]))
            if r is not None and (best_rank is None or r < best_rank):
                best_rank, best_i = r, i
        if best_i < 0:
            break
        word = word[:best_i] + [word[best_i] + word[best_i + 1]] + word[best_i + 2:]
    return word


def encode(text):
    text = text  # (ArkTS tries NFC; Python already gives NFC-ish for ASCII)
    ids = []
    for piece in PRE.findall(text):
        mapped = "".join(B2U[b] for b in piece.encode("utf-8"))
        for sym in bpe(list(mapped)):
            ids.append(vocab.get(sym, UNK))
    return ids


def main():
    hf = AutoTokenizer.from_pretrained("laya_model/tokenizer")
    all_ok = True
    for name, msg in SAMPLES.items():
        ours = encode(msg)
        ref = hf(msg, add_special_tokens=False)["input_ids"]
        ok = ours == ref
        all_ok = all_ok and ok
        print(f"{name:18s} match={ok}  ours[:8]={ours[:8]}  hf[:8]={ref[:8]}  len {len(ours)}/{len(ref)}")
    print("ALL MATCH:", all_ok)


if __name__ == "__main__":
    main()
