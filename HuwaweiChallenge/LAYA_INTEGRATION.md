# Laya integration (Guardian) — on-device, offline

Guardian runs the Laya decision model **entirely on the device**. The shipping
product is offline and declares **no `ohos.permission.INTERNET`**. There is a
**dev-only** "Dev mode" switch (see `dev/`) that routes OCR and LAY A to a host
server for fast iteration; it declares `INTERNET` in `module.json5` and must be
removed before the submission build.

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
    usecase/AnalyseMessageUseCase.ets  # builds questions, maps the gate -> verdict
  data/                                # adapters — the only place that knows "how"
    config/InferenceConfig.ets         # artefact, NPU, threads, quantisation
    assets/AssetLoader.ets             # reads rawfile (model path, tokenizer text)
    datasource/BpeTokenizer.ets        # on-device ByteLevel BPE tokenizer
    datasource/MindSporeLiteEngine.ets # local inference + NPU/CPU context
    datasource/NnrtAccelerationProbe.ets
    datasource/LayaEngineClient.ets    # UI-thread client for the model worker
    repository/DecisionRepositoryImpl.ets    # on-device engine
  di/AppContainer.ets                  # composition root
  vision/LayaClassifier.ets            # Laya -> Guardian ScanResult (island scan path)
  pages/Index.ets                      # Guard control screen
  workers/LayaWorker.ets               # loads the .ms and runs predict off the UI thread
```

Dependency rule: `vision/UI → domain ← data`. The scanner and UI only see
`AnalyseMessageUseCase`; they never import MindSpore or any transport.

> The `data/datasource/Remote*` adapters + `dev/BackendFactory` are the dev-only
> remote path selected by "Dev mode" (`BackendSettings`); they mirror this interface.

## Inference flow (all on-device by default)

1. The user scans a screen region; `vision/ScreenScanner` captures it and runs OCR.
2. `vision/LayaClassifier` calls `AnalyseMessageUseCase.run(text)`.
3. `AnalyseMessageUseCase` builds **two** typed questions from `GuardianSchema`:
   `deception` (choice: `safe` / `deceptive`) and `incident` (a choice over the KB
   incident **ids**, file order; option text = the incident `description`).
4. `DecisionRepositoryImpl` calls `MindSporeLiteEngine.infer`: `BpeTokenizer` →
   `input_ids`/`attention_mask` `[Q, max_len]` (prefix + state + `[SEP]` + pad, from
   `laya_guardian_meta.json`) → worker-hosted `model.predict` → `[1, Q, MAX_OPTIONS]`
   logits → per-question softmax → `LayaResponse`.
5. The verdict is `P(deceptive)` (`DECEPTIVE_DANGEROUS = 0.34`,
   `DECEPTIVE_CRITICAL = 0.55` in `AnalyseMessageUseCase`). `vision/LayaClassifier`
   then looks up the chosen incident (`alert/IncidentKb.forId`) for the title /
   category / severity, and the island shows its explanation / next steps (or opens
   `pages/IncidentDetail`).

**Privacy:** the text is read from the screen and processed in memory. Nothing is
transmitted; the only storage is the optional local detection log (DESIGN.md §10).

## On-device model contract (what the `.ms` must expose)

The graph is exported with Guardian's fixed label space baked in (see
`GuardianSchema`):

| Tensor | Type | Shape | Meaning |
| --- | --- | --- | --- |
| `input_ids` | int32 | `[Q, max_len]` | one full Laya sequence per question |
| `attention_mask` | int32 | `[Q, max_len]` | 1 for real tokens, 0 for pad |
| `logits` | fp32 | `[1, Q, MAX_OPTIONS]` | per-question score per option (temperature-scaled) |

`Q = 2` (deception, incident) and `MAX_OPTIONS` = the number of KB incidents (9)
(`GuardianSchema.maxOptions()`); `max_len` is read from `laya_guardian_meta.json`
(256 for the shipped w8/s256 graph). The instructions, option markers, head budget
and temperatures are **baked into the graph** by the converter
(`convert_laya.py`, kept out of the repo per `AGENTS.md` §9), which builds the
question from `rawfile/kb/en/incidents.json`. The **prefixes** (token ids) are
exported to `laya_guardian_meta.json`, and the app builds the sequence as
`prefix + state + [SEP] + pad` — matching Laya's `build_sequence` exactly.

> Changing `GuardianSchema` (questions/labels/`MAX_OPTIONS`) requires **re-exporting
> the on-device `.ms`** so the graph matches (root AGENTS.md §11).

## Tokenizer — ByteLevel BPE, ported on-device

Laya's tokenizer (`tokenizer/tokenizer.json`) is a **GPT-2-style ByteLevel BPE**
(NFC normalizer, `[CLS] … [SEP]` post-processor) — verified by inspecting the
file (`model.type = BPE`, `pre_tokenizer = ByteLevel`). Because the text must not
leave the device, `BpeTokenizer.ets` reproduces it in ArkTS: byte→unicode map,
the GPT-2 pre-tokenizer regex, greedy merge by merge-rank, then a vocab lookup.
The same `tokenizer.json` is bundled in `rawfile/`.

## Is inference accelerated by the OS? — Yes

OpenHarmony/HarmonyOS ship **MindSpore Lite** (`@kit.MindSporeLiteKit`), which
can dispatch to **Neural Network Runtime (NNRt)** — the NPU on Kirin devices.
`MindSporeLiteEngine.buildContext()` prefers NNRt and falls back to CPU, and
`NnrtAccelerationProbe` reports the real backend. The **emulator is CPU-only**
(no accelerator); a Kirin phone reports the NPU (`config.useNpu` is set from the
probe).

## Quantisation — configurable, offline

Quantisation happens once, at export, with the MindSpore Lite converter — not at
runtime. `InferenceConfig.quantization` records the artefact choice:

| dtype | ~size | notes |
| --- | --- | --- |
| **`w8` (shipped)** | **~412 MB** | weight-only int8, seq 256 (`laya_en_w8_s256.ms`); runs on the x86 emulator, 3.8× faster than fp32 s512 |
| `fp32` | ~1.69 GB | validated correct (s512); too big to swap-fit a 4 GB guest |
| `dyn8` | ~0.4 GB | **crashes** in MindSpore Lite's x86 int8 gather kernel — unusable |

Runtime CPU thread count is configurable. Quantisation + a shorter sequence change
the verdict, so diff decisions against the validated fp32 graph before trusting a
new artefact.

## Validation & limitations

- **OCR.** PP-OCRv4 det+rec (fp16 `.ms`) matches an ONNX-Runtime reference —
  recognition max|Δ| 3e-5 and 6/6 lines correct on device.
- **Deception gate.** The fine-tuned head was selected on a leakage-free held-out
  set: deception **AUC 0.930**. The shipped gate threshold of 0.25 gives roughly
  **7% false negatives / 27% false positives** (recall-first by design).
- **Incident head.** Weaker (macro-F1 ≈ 0.33); it only chooses which incident
  copy to show, so it cannot by itself raise or clear an alert.
- **Latency & device.** The emulator is CPU-only, so Laya inference there takes
  seconds-to-minutes — hence the int8 `w8`/s256 artefact. A Kirin phone would use
  the NPU via NNRt.
- **Coverage.** OCR is English-only and the incident set is small (9 cases).

## Assets to bundle (`entry/src/main/resources/rawfile/`)

| File | Source | Notes |
| --- | --- | --- |
| `tokenizer.json` | `convaiinnovations/laya/tokenizer/tokenizer.json` | copy verbatim |
| `laya_guardian_meta.json` | converter output | prefixes, SEP/PAD ids, `max_len` |
| `laya_en_w8_s256.ms` | converter output | shipped graph, contract above |

The `.ms`/`.onnx`/`.mindir` files are **git-ignored** (too large); build them with
`convert_laya.py` (kept out of the repo; Linux `converter_lite`).

## Fallback — none (by design)

There is deliberately **no heuristic fallback**: a rule-based guess could raise
a false positive, which for a safety alert is worse than showing nothing. If the
`.ms` is missing or fails to load, `DecisionRepositoryImpl` propagates the error
and the UI reports that the on-device model is unavailable.

## Build

Open `HuwaweiChallenge` in DevEco Studio (API 20+) and run on the emulator/device.
Permissions: `CUSTOM_SCREEN_CAPTURE`, `SYSTEM_FLOAT_WINDOW`,
`KEEP_BACKGROUND_RUNNING`; the dev-only `INTERNET` (Dev mode) must be removed for
the shipping build.
