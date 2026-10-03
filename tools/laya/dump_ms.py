#!/usr/bin/env python3
"""Dump raw .ms logits for one message. Usage: python dump_ms.py <model.ms>"""
import json
import sys

import numpy as np
from transformers import AutoTokenizer
import mindspore_lite as mslite

meta = json.load(open("out/laya_guardian_meta.json"))
P, MAX = meta["prefixes"], meta["max_len"]
SEP, PAD = meta["sep_id"], meta["pad_id"]
tok = AutoTokenizer.from_pretrained("laya_model/tokenizer")
msg = "Congratulations! You have won a $1000 gift card. Click here to claim now."
state = tok(msg, add_special_tokens=False)["input_ids"]
ids, mask = [], []
for p in P:
    room = MAX - len(p) - 1
    row = p + state[:room] + [SEP]
    m = [1] * len(row)
    row += [PAD] * (MAX - len(row))
    m += [0] * (MAX - len(m))
    ids.append(row)
    mask.append(m)
ids = np.array(ids, dtype=np.int32)
mask = np.array(mask, dtype=np.int32)

ctx = mslite.Context()
ctx.target = ["cpu"]
ctx.cpu.thread_num = 4
model = mslite.Model()
model.build_from_file(sys.argv[1], mslite.ModelType.MINDIR_LITE, ctx)
ins = {t.name: t for t in model.get_inputs()}
ins["input_ids"].set_data_from_numpy(ids)
ins["attention_mask"].set_data_from_numpy(mask)
o = model.predict(list(ins.values()))[0].get_data_to_numpy()
print(sys.argv[1], "dtype", o.dtype)
print(o.reshape(3, 5))
