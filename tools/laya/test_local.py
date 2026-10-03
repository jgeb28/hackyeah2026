#!/usr/bin/env python3
"""Localize the graph-vs-RLAgent discrepancy: encoder diff and full-forward diff."""
import json
from pathlib import Path

import torch
from transformers import AutoTokenizer

import convert_laya as C

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
state_len = min(max_len - len(p) - 1 for p in prefixes)
kmax = max(len(m) for m in markers)
Q = len(prefixes)
temps = [C.temperature_for(cfg, q["type"], len(m)) for q, m in zip(C.SCHEMA, markers)]
qtypes = [C.QTYPES[q["type"]] for q in C.SCHEMA]

msg = "URGENT: This is your bank. Your account has been locked. Verify immediately at http://secure-verify-bank.tj49.com"
ids = tok(msg, add_special_tokens=False)["input_ids"][:state_len]
sids = ids + [tok.pad_token_id] * (state_len - len(ids))
smask = [1] * len(ids) + [0] * (state_len - len(ids))

rows, atts = [], []
for i in range(Q):
    p = prefixes[i]
    pad = max_len - len(p) - state_len - 1
    rows.append(p + sids + [tok.sep_token_id] + [tok.pad_token_id] * pad)
    atts.append([1] * len(p) + smask + [1] + [0] * pad)
input_ids = torch.tensor(rows, dtype=torch.long)
attn = torch.tensor(atts, dtype=torch.long)

mpos = torch.zeros(Q, kmax, dtype=torch.long)
mmask = torch.zeros(Q, kmax, dtype=torch.bool)
for i, ms in enumerate(markers):
    for j, m in enumerate(ms):
        mpos[i, j] = m
        mmask[i, j] = True
qtype = torch.tensor(qtypes)

mask_min = float(torch.finfo(torch.float32).min)
idx = torch.arange(max_len)
window_f = ((idx[:, None] - idx[None, :]).abs() <= 64).to(torch.float32).view(1, 1, max_len, max_len)
keep = attn.to(torch.float32)
pad_add = (1.0 - keep) * mask_min
full = pad_add[:, None, None, :].expand(Q, 1, max_len, max_len)
slide = (1.0 - keep[:, None, None, :] * window_f) * mask_min

with torch.no_grad():
    h_ref = model.encoder(input_ids=input_ids, attention_mask=attn).last_hidden_state
    h_g = model.encoder(input_ids=input_ids,
                        attention_mask={"full_attention": full, "sliding_attention": slide}).last_hidden_state
print("encoder diff (float masks):", (h_ref - h_g).abs().max().item())

# head: reference key_padding_mask vs additive src_mask
pad = ~attn.bool()
h2 = h_ref + model.type_emb(qtype)[:, None, :]
hg = h_g + model.type_emb(qtype)[:, None, :]
heads = model.head.layers[0].self_attn.num_heads
head_mask = pad_add[:, None, None, :].expand(Q, heads, max_len, max_len).reshape(Q * heads, max_len, max_len)
for layer in model.head.layers:
    h2 = layer(h2, src_key_padding_mask=pad)
    hg = layer(hg, src_mask=head_mask)
print("head-output diff:", (h2 - hg).abs().max().item())

with torch.no_grad():
    ref_logits, _ = model(input_ids, attn, mpos, mmask, qtype)
graph = C.GuardianGraph(model, prefixes, markers, qtypes, temps, max_len,
                        tok.pad_token_id, int(tok.sep_token_id), state_len, kmax, 64)
graph.eval()
with torch.no_grad():
    g = graph(torch.tensor([sids], dtype=torch.int32),
              torch.tensor([smask], dtype=torch.int32)).reshape(Q, kmax)
ref_z = ref_logits / torch.tensor(temps)[:, None]
print("final z diff (graph vs DecisionModel):", (g - ref_z).abs().max().item())
print("ref_z:", ref_z.tolist())
print("graph:", g.tolist())
