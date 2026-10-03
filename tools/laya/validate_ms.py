#!/usr/bin/env python3
"""Acceptance test: run the converted .ms and compare to the original RLAgent.

Builds the full per-question sequence from meta.json (prefixes + state + [SEP] + pad),
exactly like Laya's build_sequence.
"""
import json
import sys

import numpy as np
from transformers import AutoTokenizer
import mindspore_lite as mslite

from rl_agent_api import RLAgent
from try_laya import SAMPLES, QUESTIONS

meta = json.load(open("out/laya_guardian_meta.json"))
MAX_LEN = int(meta["max_len"])
PREFIXES = meta["prefixes"]
SEP = int(meta["sep_id"])
PAD = int(meta["pad_id"])
CATEGORY = meta["labels"]["category"]


def build_inputs(tok, msg):
    state = tok(msg, add_special_tokens=False)["input_ids"]
    ids, mask = [], []
    for p in PREFIXES:
        room = MAX_LEN - len(p) - 1
        row = p + state[:room] + [SEP]
        m = [1] * len(row)
        row = row + [PAD] * (MAX_LEN - len(row))
        m = m + [0] * (MAX_LEN - len(m))
        ids.append(row)
        mask.append(m)
    return np.array(ids, dtype=np.int32), np.array(mask, dtype=np.int32)


def softmax(x, k):
    z = x[:k] - np.max(x[:k])
    e = np.exp(z)
    return e / e.sum()


def main():
    tok = AutoTokenizer.from_pretrained("laya_model/tokenizer")
    ctx = mslite.Context()
    ctx.target = ["cpu"]
    ctx.cpu.thread_num = 4
    model = mslite.Model()
    model.build_from_file(sys.argv[1] if len(sys.argv) > 1 else "out/laya_guardian.ms",
                          mslite.ModelType.MINDIR_LITE, ctx)
    inputs = model.get_inputs()
    print("ms inputs:", [(t.name, list(t.shape), t.dtype) for t in inputs])
    by_name = {t.name: t for t in inputs}

    agent = RLAgent("laya_model", device="cpu")
    maxdiff = 0.0
    for name, msg in SAMPLES.items():
        ids, mask = build_inputs(tok, msg)
        by_name["input_ids"].set_data_from_numpy(ids)
        by_name["attention_mask"].set_data_from_numpy(mask)
        out = model.predict(inputs)[0].get_data_to_numpy().reshape(3, 5)

        risk = float(softmax(out[0], 2)[1])
        catp = softmax(out[1], 5)
        cat = CATEGORY[int(catp.argmax())]
        urg = float((np.arange(3) * softmax(out[2], 3)).sum())

        ref = agent.system_one(msg, QUESTIONS)["answers"]
        maxdiff = max(maxdiff, abs(risk - ref["risk"]["noul"]),
                      abs(urg - ref["urgency"]["score"]))
        print(f"{name:18s} .ms risk={risk:.3f} cat={cat:14s} urg={urg:.2f} | "
              f"ref risk={ref['risk']['noul']:.3f} cat={ref['category']['choice']:14s} "
              f"urg={ref['urgency']['score']:.2f}")
    print("max prob diff (.ms vs RLAgent):", maxdiff)


if __name__ == "__main__":
    main()
