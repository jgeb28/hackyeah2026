#!/usr/bin/env python3
"""Torch-level equivalence: GuardianGraph (full-sequence input) vs original RLAgent."""
import json
from pathlib import Path

import numpy as np
import torch
from transformers import AutoTokenizer

import convert_laya as C
from rl_agent_api import RLAgent
from try_laya import SAMPLES, QUESTIONS

md = Path("laya_model")
cfg = json.loads((md / "rl_agent_config.json").read_text())
tok = AutoTokenizer.from_pretrained(str(md / "tokenizer"))
model = C.build_decision_model(md / "encoder", md / "model.safetensors", cfg)
model.eval()

prefixes, markers = [], []
for q in C.SCHEMA:
    p, m = C.build_head(tok, q, cfg["head_max_len"])
    prefixes.append(p)
    markers.append(m)
max_len = int(cfg["max_len"])
kmax = max(len(m) for m in markers)
temps = [C.temperature_for(cfg, q["type"], len(m)) for q, m in zip(C.SCHEMA, markers)]
qtypes = [C.QTYPES[q["type"]] for q in C.SCHEMA]
Q = len(C.SCHEMA)
pad_id, sep_id = tok.pad_token_id, tok.sep_token_id

graph = C.GuardianGraph(model, markers, qtypes, temps, max_len, kmax, 64)
graph.eval()
agent = RLAgent("laya_model", device="cpu")
CAT = list(C.SCHEMA[1]["criteria"].keys())


def build_inputs(msg):
    state = tok(msg, add_special_tokens=False)["input_ids"]
    ids, mask = [], []
    for p in prefixes:
        room = max_len - len(p) - 1
        s = state[:room]
        row = p + s + [sep_id]
        m = [1] * len(row)
        row = row + [pad_id] * (max_len - len(row))
        m = m + [0] * (max_len - len(m))
        ids.append(row)
        mask.append(m)
    return (torch.tensor(ids, dtype=torch.int32), torch.tensor(mask, dtype=torch.int32))


def softmax(x, k):
    z = x[:k] - np.max(x[:k])
    e = np.exp(z)
    return e / e.sum()


maxdiff = 0.0
for name, msg in SAMPLES.items():
    with torch.no_grad():
        out = graph(*build_inputs(msg)).numpy().reshape(Q, kmax)
    risk = float(softmax(out[0], 2)[1])
    catp = softmax(out[1], 5)
    cat = CAT[int(catp.argmax())]
    urg = float((np.arange(3) * softmax(out[2], 3)).sum())
    ref = agent.system_one(msg, QUESTIONS)["answers"]
    maxdiff = max(maxdiff, abs(risk - ref["risk"]["noul"]), abs(urg - ref["urgency"]["score"]))
    print(f"{name:18s} graph risk={risk:.3f} cat={cat:14s} urg={urg:.2f} | "
          f"ref risk={ref['risk']['noul']:.3f} cat={ref['category']['choice']:14s} "
          f"urg={ref['urgency']['score']:.2f}")

print("max prob diff (graph vs RLAgent):", maxdiff)
