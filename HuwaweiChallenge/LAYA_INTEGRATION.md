# Laya integration (Guardian) — on-device, offline

Guardian runs the Laya decision model **entirely on the device**. There is no
network backend and **no `ohos.permission.INTERNET`** in the app. This document
covers the architecture, the on-device model contract, OS acceleration, and
quantisation.

Model: [`convaiinnovations/laya`](https://huggingface.co/convaiinnovations/laya) —
non-autoregressive "System 1" decision model (ModernBERT-large + a custom RL
decision head). It takes a **state** and **typed questions** and returns typed
answers with calibrated probabilities. It is a classifier, not an LLM.

## Clean architecture

```
entry/src/main/ets/
  domain/                              # pure rules — no UI, no platform
    model/Decision.ets                 # LayaRequest/Response, Verdict, MessageAnalysis
    model/GuardianSchema.ets           # label space, shared by request + graph decode
    repository/DecisionRepository.ets  # port: predict(request) -> response
    usecase/AnalyseMessageUseCase.ets  # builds questions, maps risk -> verdict
  data/                                # adapters — the only place that knows "how"
    config/InferenceConfig.ets         # artefacts, NPU, threads, quantisation
    assets/AssetLoader.ets             # reads rawfile (model fd, tokenizer text)
    datasource/BpeTokenizer.ets        # on-device ByteLevel BPE tokenizer
    datasource/MindSporeLiteEngine.ets # local inference + NPU/CPU context
    datasource/NnrtAccelerationProbe.ets
    repository/DecisionRepositoryImpl.ets    # on-device engine
  di/AppContainer.ets                  # composition root
  presentation/components/AnswerPopup.ets
  pages/Index.ets                      # question; tap -> analyse -> popup
```

Dependency rule: `presentation → domain ← data`. The page only sees
`AnalyseMessageUseCase`; it never imports MindSpore or any transport.

## Inference flow (all on-device)

1. User taps the question on `Index`.
2. `AnalyseMessageUseCase.run(message)` builds the three typed questions from
   `GuardianSchema` (`risk` noul, `category` choice, `urgency` score).
3. `DecisionRepositoryImpl` calls `MindSporeLiteEngine.infer`:
   `BpeTokenizer` → build `input_ids`/`attention_mask` `[Q, 512]` (prefix + state +
   `[SEP]` + pad, from `laya_guardian_meta.json`) → `model.predict` →
   `[1, Q, MAX_OPTIONS]` logits → softmax per question → `LayaResponse`.
4. The use case maps the **category** distribution (P(scam)+P(harassment)) to
   `SAFE`/`DANGEROUS`/`CRITICAL` (the base `noul` head is unreliable).
5. `AnswerPopup` shows the verdict, answers and probability breakdowns.

**Privacy:** the message text is read from the screen and processed in memory.
Nothing is transmitted; the only storage is the optional local detection log
(DESIGN.md §10).

## On-device model contract (what the `.ms` must expose)

The graph is exported with Guardian's fixed label space baked in (see
`GuardianSchema`):

| Tensor | Type | Shape | Meaning |
| --- | --- | --- | --- |
| `input_ids` | int32 | `[Q, 512]` | one full Laya sequence per question |
| `attention_mask` | int32 | `[Q, 512]` | 1 for real tokens, 0 for pad |
| `logits` | fp32 | `[1, Q, MAX_OPTIONS]` | per-question score per option (temperature-scaled) |

`Q = 3` (risk, category, urgency) and `MAX_OPTIONS = 5`. The instructions, option
markers, head budget and temperatures are **baked into the graph** by the converter
(`~/tmp/convert_laya.py`). The per-question **prefixes** (token ids) are exported to
`laya_guardian_meta.json`, and the app builds each sequence as
`prefix + state + [SEP] + pad` — matching Laya's `build_sequence` exactly.

## Tokenizer — ByteLevel BPE, ported on-device

Laya's tokenizer (`tokenizer/tokenizer.json`) is a **GPT-2-style ByteLevel BPE**
(NFC normalizer, `[CLS] … [SEP]` post-processor) — verified by inspecting the
file (`model.type = BPE`, `pre_tokenizer = ByteLevel`). Because the text must not
leave the device, `BpeTokenizer.ets` reproduces it in ArkTS: byte→unicode map,
the GPT-2 pre-tokenizer regex, greedy merge by merge-rank, then a vocab lookup.
The same `tokenizer.json` is bundled in `rawfile/`.

> **Status:** the ArkTS BPE algorithm was validated against Hugging Face's
> `AutoTokenizer` via a Python reimplementation — **identical token ids on all 5
> sample messages**. (Note: `merges` in `tokenizer.json` are `["a","b"]` arrays, not
> strings.) The one thing not testable here is ArkTS's own regex support for `\p{L}`
> at runtime.

## Is inference accelerated by the OS? — Yes

OpenHarmony/HarmonyOS ship **MindSpore Lite** (`@kit.MindSporeLiteKit`), which
can dispatch to **Neural Network Runtime (NNRt)** — the NPU on Kirin devices.
`MindSporeLiteEngine.buildContext()` sets:

```ts
context.target = ['nnrt', 'cpu'];   // prefer NPU, fall back to CPU
context.nnrt   = {};
context.cpu.precisionMode = 'preferred_fp16';
```

`NnrtAccelerationProbe` calls `mindSporeLite.getAllNNRTDeviceDescriptions()` and
the UI states the real backend. The Oniro/OpenHarmony **emulator is CPU-only**
(no accelerator); a Kirin phone reports the NPU.

## Quantisation — configurable, offline

Quantisation happens once, at export, with the MindSpore Lite converter — not at
runtime. `InferenceConfig.quantization` records the artefact choice:

| dtype | ~size (421M params) | use |
| --- | --- | --- |
| **`fp32` (shipped)** | **~1.69 GB** | validated correct (`laya_guardian_fp32.ms`); large |
| `fp16` | ~0.84 GB | produces NaN under `converter_lite --fp16=on` (open issue) |
| `int8` | ~0.42 GB | not yet tried; needs accuracy check |

Runtime CPU thread count is configurable (`enforce_fp32` used for the shipped fp32
model to reproduce the validated results).

## Assets to bundle (`entry/src/main/resources/rawfile/`)

| File | Source | Notes |
| --- | --- | --- |
| `tokenizer.json` | `convaiinnovations/laya/tokenizer/tokenizer.json` | copy verbatim |
| `laya_guardian_meta.json` | converter output | prefixes, SEP/PAD ids, max_len |
| `laya_guardian_fp32.ms` | converter output (1.69 GB) | validated fp32 graph, contract above |

The `.ms`/`.onnx`/`.mindir` files are **git-ignored** (too large); build them with
`~/tmp/convert_laya.py` — see `LAYA_ONDEVICE_RESEARCH.md` for the full pipeline.
The conversion is at `CONVERT RESULT SUCCESS:0`, and the fp32 `.ms` matches the
reference `RLAgent` (max prob diff 2.5e-3).

## Fallback — none (by design)

There is deliberately **no heuristic fallback**: a rule-based guess could raise
a false positive, which for a safety alert is worse than showing nothing. If the
`.ms` is missing or fails to load, `DecisionRepositoryImpl` propagates the error
and the UI reports that the on-device model is unavailable.

## Build

Open `HuwaweiChallenge` in DevEco Studio (API 20+, compileSdk 23) and run on the
emulator/device. No permissions are required — the app is offline by design.
