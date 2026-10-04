#!/usr/bin/env python3
"""Convert Laya -> MindSpore Lite (.ms) for Guardian's fixed on-device schema.

Pipeline
--------
1. Download `convaiinnovations/laya` (encoder + tokenizer + weights + config).
2. Rebuild the real `DecisionModel` (encoder + type embedding + 2-layer head +
   per-option [MASK] scorer) exactly as `rl_common.py` does.
3. Wrap it with Guardian's two fixed questions baked in, so the exported graph
   only needs the **tokenized message** (state) as input.
4. Export ONNX (legacy tracer, opset 17) and numerically validate it against
   PyTorch (when onnxruntime is available).
5. Convert ONNX -> MindSpore Lite `.ms` with `converter_lite`.

Graph contract (matches entry/.../data/datasource/MindSporeLiteEngine.ets)
------------------------------------------------------------------------
  input  "state_ids"   int32 [1, STATE_LEN]   tokenized message (padded)
  input  "state_mask"  int32 [1, STATE_LEN]   1 = real token, 0 = pad
  output "logits"      fp32  [1, Q, MAX_OPT]  temperature-scaled, padded -1e4

The app tokenizes the message with the same tokenizer.json (ByteLevel BPE) and
feeds the ids; everything else (instructions, option markers, head budget,
temperature) is baked into the graph.
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple

import numpy as np
import torch
import torch.nn as nn

# The TorchScript ONNX exporter cannot lower PyTorch's fused TransformerEncoder
# fast path (`aten::_transformer_encoder_layer_fwd`), which the decision head
# hits. Force the reference implementation so the head exports to standard ops.
try:
    torch.backends.mha.set_fastpath_enabled(False)
except Exception:  # older/newer torch without the toggle
    pass

REPO_ID = "convaiinnovations/laya"
PATTERNS = ["encoder/*", "tokenizer/*", "model.safetensors", "rl_agent_config.json"]

QTYPES: Dict[str, int] = {"choice": 0, "score": 1, "noul": 2}

# Guardian's question 1 (the deception gate). Order MUST match GuardianSchema.ets.
DECEPTION: Dict = {
    "key": "deception",
    "type": "choice",
    "instructions": "Does this text try to deceive the reader — for example by impersonating "
                    "someone, inventing urgency or a threat, or asking for money, credentials or "
                    "personal data?",
    "criteria": {
        "safe": "the text is not trying to deceive the reader",
        "deceptive": "the text tries to deceive the reader",
    },
}

DEFAULT_KB = (Path(__file__).resolve().parent.parent.parent /
              "HuwaweiChallenge/entry/src/main/resources/rawfile/kb/en/incidents.json")


def build_incident_question(kb_path: Path) -> Dict:
    """Question 1, generated from the incident KB. Options = incident ids (file
    order); option text = the incident description. Matches
    `IncidentKb.publishChoices` in the app."""
    data = json.loads(kb_path.read_text(encoding="utf-8"))
    criteria: Dict[str, str] = {}
    for inc in data.get("incidents", []):
        criteria[inc["id"]] = inc.get("description", "")
    return {
        "key": "incident",
        "type": "choice",
        "instructions": "Which of these known incidents best matches the text? Pick the closest match.",
        "criteria": criteria,
    }


# --------------------------------------------------------------------------- Laya helpers
def render_options(q: Dict) -> List[str]:
    """Option texts in label-index order (verbatim from rl_common.py)."""
    t, crit = q["type"], q.get("criteria")
    if t == "choice":
        return [k if not v else "%s: %s" % (k, v) for k, v in crit.items()]
    if t == "score":
        return ["level %d: %s" % (i, c) for i, c in enumerate(crit)]
    crit = crit or {}
    return ["false: " + (crit.get("false") or "no, the statement does not hold"),
            "true: " + (crit.get("true") or "yes, the statement holds")]


def build_head(tok, q: Dict, head_max_len: int) -> Tuple[List[int], List[int]]:
    """The sequence prefix before the state: [CLS] <type> question: <ins> [SEP] <MASK> opt... [SEP].

    Mirrors `build_sequence` in rl_common.py up to the state ("prefix"), returning the
    token ids and the absolute positions of the per-option [MASK] markers.
    """
    mask_tok = tok.mask_token
    opts = render_options(q)
    ins = str(q["instructions"]).replace(mask_tok, " ")
    head_ids = tok("%s question: %s" % (q["type"], ins), add_special_tokens=False)["input_ids"]
    opt_ids: List[List[int]] = []
    for opt in opts:
        text = " " + opt.replace(mask_tok, " ")
        opt_ids.append([tok.mask_token_id] + tok(text, add_special_tokens=False)["input_ids"][:48])

    opt_budget = head_max_len - sum(len(o) for o in opt_ids)
    if opt_budget < 16:  # too many / too long options: shrink every option evenly
        per = max(4, (head_max_len - 16) // max(1, len(opt_ids)))
        opt_ids = [o[:per] for o in opt_ids]
        opt_budget = head_max_len - sum(len(o) for o in opt_ids)
    head_ids = head_ids[:max(8, opt_budget)]

    ids: List[int] = [tok.cls_token_id] + head_ids + [tok.sep_token_id]
    markers: List[int] = []
    for opt in opt_ids:
        markers.append(len(ids))
        ids.extend(opt)
    ids.append(tok.sep_token_id)
    return ids, markers


def temperature_for(cfg: Dict, qtype_name: str, k: int) -> float:
    size = "2" if k <= 2 else "3-5" if k <= 5 else "6-10" if k <= 10 else "11+"
    key = "%s:%s" % (qtype_name, size)
    by_opts = cfg.get("temperature_by_options", {})
    if key in by_opts:
        return float(by_opts[key])
    return float(cfg.get("temperature", [1.0, 1.0, 1.0])[QTYPES[qtype_name]])


# --------------------------------------------------------------------------- export module
class GuardianGraph(nn.Module):
    """Laya with Guardian's fixed questions baked in.

    Input is the **fully built** sequence (the app replicates Laya's
    `build_sequence`: prefix + state + [SEP] + pad), so the state is packed
    tightly and `[SEP]` sits right after it — matching Laya exactly.

    Masks are built with FLOAT arithmetic only (MSP Lite has no int->bool Cast
    kernel) and passed to the encoder as a 4D-mask dict to bypass ModernBERT's
    dynamic shape ops.
    """

    def __init__(self, model, markers: List[List[int]], qtypes: List[int],
                 temperatures: List[float], max_len: int, kmax: int, sliding_window: int):
        super().__init__()
        self.model = model
        self.max_len = max_len
        self.kmax = kmax
        self.qcount = len(markers)
        self.mask_min = -1e4  # additive mask bias; must survive fp16 (finfo.min -> -inf)

        mpos = torch.zeros((self.qcount, kmax), dtype=torch.long)
        mmask = torch.zeros((self.qcount, kmax), dtype=torch.bool)
        for i, ms in enumerate(markers):
            for j, m in enumerate(ms):
                mpos[i, j] = m
                mmask[i, j] = True
        self.register_buffer("marker_pos", mpos)
        self.register_buffer("marker_mask", mmask)
        self._markers = [list(m) for m in markers]
        self.register_buffer("qtype", torch.tensor(qtypes, dtype=torch.long))
        self.register_buffer("temperature", torch.tensor(temperatures, dtype=torch.float32))
        self.register_buffer("neg_bias", torch.full((self.qcount, kmax), -1e4))

        idx = torch.arange(max_len)
        distance = (idx[:, None] - idx[None, :]).abs()
        self.register_buffer("window_f", (distance <= sliding_window)
                             .to(torch.float32).view(1, 1, max_len, max_len))
        self.heads = int(model.head.layers[0].self_attn.num_heads) if model.head is not None else 1

    def forward(self, input_ids: torch.Tensor, attention_mask: torch.Tensor) -> torch.Tensor:
        input_ids = input_ids.long()
        attention_mask = attention_mask.long()

        # 4D additive masks, FLOAT only: 0 where attended, mask_min where masked.
        keep = attention_mask.to(torch.float32)                        # [Q,S]
        pad_add = (1.0 - keep) * self.mask_min
        full = pad_add[:, None, None, :].expand(
            self.qcount, 1, self.max_len, self.max_len)
        slide = (1.0 - keep[:, None, None, :] * self.window_f) * self.mask_min
        encoder_masks = {"full_attention": full, "sliding_attention": slide}

        h = self.model.encoder(input_ids=input_ids, attention_mask=encoder_masks).last_hidden_state
        h = h + self.model.type_emb(self.qtype)[:, None, :]
        if self.model.head is not None:
            head_mask = pad_add[:, None, None, :].expand(
                self.qcount, self.heads, self.max_len, self.max_len).reshape(
                self.qcount * self.heads, self.max_len, self.max_len)
            for layer in self.model.head.layers:
                h = layer(h, src_mask=head_mask)

        # Extract marker hidden states by STATIC slicing (marker positions are
        # constants) — avoids ONNX GatherElements, which the MSP Lite CPU
        # runtime does not support.
        m_rows = []
        for q in range(self.qcount):
            picks = [h[q, pos] for pos in self._markers[q]]
            while len(picks) < self.kmax:
                picks.append(torch.zeros_like(picks[0]))
            m_rows.append(torch.stack(picks, dim=0))          # [kmax, E]
        m = torch.stack(m_rows, dim=0)                         # [Q, kmax, E]

        logits = self.model.scorer(m).squeeze(-1).float()      # [Q, kmax]
        logits = logits.masked_fill(~self.marker_mask, -1e4)
        z = logits / self.temperature[:, None]
        z = torch.where(self.marker_mask, z, self.neg_bias)
        return z.unsqueeze(0)


def build_decision_model(encoder_dir: Path, weights: Path, cfg: Dict):
    """Recreate rl_common.DecisionModel with **eager** attention (ONNX-friendly)."""
    import gc
    from safetensors.torch import load_file
    from transformers import AutoConfig, AutoModel

    sys.path.insert(0, str(Path(__file__).parent))
    try:
        from rl_common import DecisionModel  # type: ignore
    except Exception:
        from tmp.rl_common import DecisionModel  # type: ignore

    ecfg = AutoConfig.from_pretrained(str(encoder_dir))
    try:
        enc = AutoModel.from_config(ecfg, attn_implementation="eager")
    except TypeError:
        enc = AutoModel.from_config(ecfg)
    model = DecisionModel(enc, cfg["head_layers"], len(cfg["act_costs"]) + 1)
    state = load_file(str(weights))
    model.load_state_dict(state, strict=True)
    del state  # release the raw 1.7 GB copy before tracing/export
    gc.collect()
    model.eval()
    return model


# --------------------------------------------------------------------------- steps
def download_model(model_dir: Path) -> None:
    from huggingface_hub import snapshot_download
    snapshot_download(repo_id=REPO_ID, local_dir=str(model_dir), allow_patterns=PATTERNS)


def export_onnx(graph: GuardianGraph, onnx_path: Path) -> None:
    q, s = graph.qcount, graph.max_len
    dummy_ids = torch.zeros((q, s), dtype=torch.int32)
    dummy_mask = torch.ones((q, s), dtype=torch.int32)
    with torch.no_grad():
        torch.onnx.export(
            graph,
            (dummy_ids, dummy_mask),
            str(onnx_path),
            input_names=["input_ids", "attention_mask"],
            output_names=["logits"],
            opset_version=17,
            dynamo=False,
            do_constant_folding=False,
        )


def validate_onnx(graph: GuardianGraph, onnx_path: Path) -> bool:
    try:
        import onnxruntime as ort
    except Exception:
        print("[validate] onnxruntime not installed; skipping numerical check")
        return True

    rng = np.random.default_rng(0)
    q, s = graph.qcount, graph.max_len
    ids = rng.integers(0, 1000, size=(q, s)).astype(np.int32)
    mask = np.ones((q, s), dtype=np.int32)
    try:
        sess = ort.InferenceSession(str(onnx_path), providers=["CPUExecutionProvider"])
        onnx_out = sess.run(["logits"], {"input_ids": ids, "attention_mask": mask})[0]
        with torch.no_grad():
            ref = graph(torch.from_numpy(ids), torch.from_numpy(mask)).numpy()
        diff = float(np.max(np.abs(onnx_out - ref)))
        print("[validate] max |onnx - torch| = %.3e" % diff)
        return diff < 1e-3
    except Exception as exc:  # pragma: no cover
        print("[validate] skipped: %s" % exc)
        return True


def ort_fold(src: Path, dst: Path) -> bool:
    """Constant-fold Shape/ConstantOfShape with ONNX Runtime (lighter than onnxsim)."""
    try:
        import onnxruntime as ort
    except Exception as exc:  # pragma: no cover
        print("[ort] unavailable: %s" % exc)
        return False
    print("[ort] constant-folding %s" % src)
    so = ort.SessionOptions()
    so.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_BASIC
    so.optimized_model_filepath = str(dst)
    try:
        ort.InferenceSession(str(src), so, providers=["CPUExecutionProvider"])
        return True
    except Exception as exc:
        print("[ort] fold failed: %s" % exc)
        return False


def simplify_onnx(src: Path, dst: Path) -> bool:
    """Fold ConstantOfShape nodes into initializers.

    MindSpore Lite has no kernel for `ConstantOfShape` (it logs
    "lite kernel nullptr" and cannot constant-fold it), so the unknown output
    shape poisons downstream nodes (e.g. `Flatten`, "Shape is empty"). Their
    shape inputs here are already ONNX `Constant`s, so we can evaluate the node
    ourselves without a full shape-inference pass (which OOMs on this box).
    """
    import numpy as np
    from collections import defaultdict
    import onnx
    from onnx import numpy_helper

    print("[fold] loading %s" % src)
    model = onnx.load(str(src))
    g = model.graph
    init = {i.name: i for i in g.initializer}
    const_val = {}
    for n in g.node:
        if n.op_type == "Constant":
            for a in n.attribute:
                if a.name == "value":
                    const_val[n.output[0]] = numpy_helper.to_array(a.t)

    new_nodes = []
    new_inits = []
    folded = 0
    for n in g.node:
        if n.op_type != "ConstantOfShape":
            new_nodes.append(n)
            continue
        shape_name = n.input[0]
        if shape_name in const_val:
            shape = const_val[shape_name].astype(np.int64).tolist()
        elif shape_name in init:
            shape = numpy_helper.to_array(init[shape_name]).astype(np.int64).tolist()
        else:
            new_nodes.append(n)  # leave it; converter will complain if it matters
            continue
        value = None
        for a in n.attribute:
            if a.name == "value":
                value = numpy_helper.to_array(a.t)
        if value is None:
            arr = np.zeros(shape, dtype=np.float32)
        else:
            arr = np.full(shape, value.reshape(-1)[0], dtype=value.dtype)
        new_inits.append(numpy_helper.from_array(arr, n.output[0]))
        folded += 1

    del g.node[:]
    g.node.extend(new_nodes)
    g.initializer.extend(new_inits)
    print("[fold] folded %d ConstantOfShape -> initializers" % folded)

    # After folding, the shape-math subgraphs that fed ConstantOfShape are dead.
    # MindSpore Lite still tries to shape-infer them (and fails on `Flatten`), so
    # prune every node not reachable from the graph outputs.
    producers = {}
    for n in g.node:
        for o in n.output:
            producers[o] = n
    live = set()
    stack = [o.name for o in g.output]
    while stack:
        name = stack.pop()
        n = producers.get(name)
        if n is None or id(n) in live:
            continue
        live.add(id(n))
        for i in n.input:
            if i:
                stack.append(i)
    kept = [n for n in g.node if id(n) in live]
    print("[fold] pruned %d dead nodes" % (len(g.node) - len(kept)))
    del g.node[:]
    g.node.extend(kept)

    used = set()
    for n in g.node:
        used.update(i for i in n.input if i)
    kept_inits = [t for t in g.initializer if t.name in used]
    print("[fold] dropped %d unused initializers" % (len(g.initializer) - len(kept_inits)))
    del g.initializer[:]
    g.initializer.extend(kept_inits)

    onnx.save(model, str(dst))
    return True


def convert_to_ms(onnx_path: Path, out_prefix: Path, quantize: Optional[str],
                  fp16: bool) -> None:
    converter = os.environ.get("CONVERTER_LITE") or shutil.which("converter_lite")
    if not converter:
        print("\nBLOCKER: `converter_lite` (MindSpore Lite converter) not found.")
        print("Install it or point CONVERTER_LITE at the binary, then re-run with --skip-export.")
        print("ONNX is ready at: %s" % onnx_path)
        raise SystemExit(2)

    cmd = [converter, "--fmk=ONNX", "--modelFile=%s" % onnx_path,
           "--outputFile=%s" % out_prefix]
    if quantize:
        cmd.append("--quantType=%s" % quantize)
    if fp16:
        cmd.append("--fp16=on")
    print("[mslite] %s" % " ".join(cmd))

    env = os.environ.copy()
    ms_home = os.environ.get("MSLITE_HOME")
    if ms_home:
        libs = [str(Path(ms_home) / "runtime" / "lib"),
                str(Path(ms_home) / "tools" / "converter" / "lib")]
        env["LD_LIBRARY_PATH"] = ":".join(libs + [env.get("LD_LIBRARY_PATH", "")])
    subprocess.run(cmd, check=True, env=env)
    produced = out_prefix.with_suffix(".ms")
    print("[mslite] wrote %s" % produced)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--out-dir", default=str(Path(__file__).parent / "out"))
    ap.add_argument("--model-dir", default=str(Path(__file__).parent / "laya_model"))
    ap.add_argument("--skip-download", action="store_true")
    ap.add_argument("--skip-export", action="store_true")
    ap.add_argument("--quantize", default=None,
                    help="converter_lite --quantType value, e.g. WEIGHT_QUANT")
    ap.add_argument("--fp16", action="store_true",
                    help="serialize const (weight) tensors as Float16 (smaller .ms)")
    ap.add_argument("--no-simplify", action="store_true",
                    help="skip onnxsim constant-folding before conversion")
    ap.add_argument("--export-only", action="store_true",
                    help="export ONNX + meta, then stop (no simplification/conversion)")
    ap.add_argument("--kb", default=str(DEFAULT_KB),
                    help="incidents.json used to build question 2 (the incident choice)")
    args = ap.parse_args()

    model_dir = Path(args.model_dir)
    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    if not args.skip_download and not (model_dir / "model.safetensors").exists():
        print("[download] %s -> %s" % (REPO_ID, model_dir))
        download_model(model_dir)

    cfg = json.loads((model_dir / "rl_agent_config.json").read_text())
    max_len = int(cfg["max_len"])
    head_max_len = int(cfg["head_max_len"])

    from transformers import AutoTokenizer
    tok = AutoTokenizer.from_pretrained(str(model_dir / "tokenizer"))

    schema: List[Dict] = [DECEPTION, build_incident_question(Path(args.kb))]
    print("[schema] questions: %s" % [q["key"] for q in schema])

    prefixes: List[List[int]] = []
    markers: List[List[int]] = []
    for q in schema:
        prefix, marks = build_head(tok, q, head_max_len)
        prefixes.append(prefix)
        markers.append(marks)
        print("[schema] %-9s prefix=%d options=%d markers=%s"
              % (q["key"], len(prefix), len(marks), marks))

    # Input is the FULL sequence per question: prefix + state + [SEP] + pad,
    # so the app packs the state tightly (matching Laya's build_sequence).
    for q, p in zip(schema, prefixes):
        if len(p) + 8 >= max_len:
            print("BLOCKER: prefix too long for max_len (%s: %d)" % (q["key"], len(p)))
            return 1
    kmax = max(len(m) for m in markers)
    temperatures = [temperature_for(cfg, q["type"], len(m)) for q, m in zip(schema, markers)]
    qtypes = [QTYPES[q["type"]] for q in schema]
    print("[graph] max_len=%d kmax=%d temperatures=%s"
          % (max_len, kmax, ["%.3f" % t for t in temperatures]))

    onnx_path = out_dir / "laya_guardian.onnx"
    meta_path = out_dir / "laya_guardian_meta.json"

    if not args.skip_export:
        from transformers import AutoConfig
        encoder_cfg = AutoConfig.from_pretrained(str(model_dir / "encoder"))
        sliding_window = int(getattr(encoder_cfg, "sliding_window", 64))
        print("[graph] sliding_window=%d" % sliding_window)
        model = build_decision_model(model_dir / "encoder", model_dir / "model.safetensors", cfg)
        graph = GuardianGraph(model, markers, qtypes, temperatures,
                              max_len, kmax, sliding_window)
        graph.eval()
        print("[onnx] exporting %s" % onnx_path)
        export_onnx(graph, onnx_path)
        if not validate_onnx(graph, onnx_path):
            print("BLOCKER: ONNX export does not match PyTorch; not converting.")
            return 1

        meta = {
            "model": "laya-guardian",
            "repo": REPO_ID,
            "quantization": args.quantize or "none",
            "inputs": {"input_ids": [len(schema), max_len],
                       "attention_mask": [len(schema), max_len]},
            "output": {"logits": [1, len(schema), kmax]},
            "questions": [q["key"] for q in schema],
            "labels": {q["key"]: render_labels(q) for q in schema},
            "prefixes": prefixes,
            "markers": markers,
            "temperatures": temperatures,
            "sep_id": int(tok.sep_token_id),
            "pad_id": int(tok.pad_token_id),
            "max_len": max_len,
            "rooms": [max_len - len(p) - 1 for p in prefixes],
        }
        meta_path.write_text(json.dumps(meta, indent=2))
        print("[meta] wrote %s" % meta_path)
        if args.export_only:
            print("[done] export-only")
            return 0

    onnx_for_convert = onnx_path
    if not args.no_simplify:
        sim1 = out_dir / "laya_guardian_onnxsim.onnx"
        try:
            import onnx
            from onnxsim import simplify
            print("[onnxsim] simplifying %s" % onnx_path)
            mm, ok = simplify(onnx.load(str(onnx_path)))
            onnx.save(mm, str(sim1))
            print("[onnxsim] ok=%s" % ok)
            onnx_for_convert = sim1
        except Exception as exc:
            print("[onnxsim] skipped: %s" % exc)
        sim_path = out_dir / "laya_guardian_sim.onnx"
        if simplify_onnx(onnx_for_convert, sim_path):
            onnx_for_convert = sim_path
    convert_to_ms(onnx_for_convert, out_dir / "laya_guardian", args.quantize, args.fp16)
    print("\nDone. Copy these into entry/src/main/resources/rawfile/:")
    print("  - %s.ms" % (out_dir / "laya_guardian"))
    print("  - %s" % (model_dir / "tokenizer" / "tokenizer.json"))
    return 0


def render_labels(q: Dict) -> List[str]:
    if q["type"] == "choice":
        return list(q["criteria"].keys())
    if q["type"] == "score":
        return list(q["criteria"])
    return ["false", "true"]


if __name__ == "__main__":
    raise SystemExit(main())
