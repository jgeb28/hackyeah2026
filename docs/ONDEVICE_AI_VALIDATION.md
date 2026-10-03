# On-device AI on Huawei phones — capability validation

**Question.** For a HarmonyOS/OpenHarmony app that runs inference **locally on a
Huawei phone**, is that feasible (a) for small dedicated "classical ML" models
and (b) for small LLMs / decision models such as **LAYA**? And what are the
device capabilities?

**Status:** research / desk validation (2026-10-03). No physical Huawei device
was available on this machine to benchmark; conclusions marked *unverified*
need confirmation on real hardware.

---

## 1. TL;DR

- **Yes for classical ML and small decision/embedding models.** OpenHarmony ships
  `@kit.MindSporeLiteKit` (`@ohos.ai.mindSporeLite`) and `@ohos.data.intelligence`
  (on-device text/image embeddings). These run on CPU everywhere and on the
  **Kirin NPU** via NNRt on Huawei devices.
- **Yes for small LLMs — this is now an official Huawei path.** MindSpore Lite
  advertises a device-side **LLM inference module for the Kirin NPU** and a model
  zoo including Qwen2/Qwen2.5/Qwen3/Qwen3.5 (0.5B–9B), VLMs, ASR/TTS, embeddings,
  rerankers, YOLO/SAM, etc. Device models use the `.ms` format.
- **LAYA is a different beast and a good fit.** `convaiinnovations/laya` is a
  *non-autoregressive decision/routing* model (millisecond-scale, for
  classification/routing) — not a generative LLM. It is exactly the "small,
  dedicated model" class, and should convert to `.ms` / ONNX and run on CPU/NPU.
- **Biggest constraint:** on the **Oniro/OpenHarmony emulator there is no NPU**
  (CPU-only), and the closed **HMS AI Kits do not exist on Oniro**. Demonstrating
  NPU-class performance requires a physical Huawei device (and, for some paths, a
  Huawei developer account).

---

## 2. Frontier Huawei phones (2025–2026)

| Device | SoC | OS | RAM | Notes |
| --- | --- | --- | --- | --- |
| **Mate 80** (Nov 2025) | Kirin 9020 | HarmonyOS 6 | 12/16 GB | 5,750 mAh, 3D face |
| **Mate 80 Pro** | Kirin 9030 (12 GB) / **Kirin 9030 Pro** (16 GB) | HarmonyOS 6 | 12/16 GB | Global release Feb 26 2026 |
| **Mate 80 Pro Max / RS Ultimate** | Kirin 9030 Pro | HarmonyOS 6 | up to 16 GB (some reports claim 20 GB) *unverified* | up to 1 TB storage |
| **Pura 90 series** (2026) | Kirin 9xxx | HarmonyOS 6/7 | high | Pura line |
| **Mate X7** foldable | Kirin 9xxx | HarmonyOS 6/7 | high | |
| Prev-gen **Mate 70 / Pura 70** | Kirin 9010/9020 | HarmonyOS 4/5 (NEXT on some) | 12 GB | installed base |

**NPU.** Huawei uses its **Da Vinci** NPU ("Ascend" NPU block in teardowns). The
Kirin 9030 moved from *Lite + Tiny* cores (9020) to **Lite + two Tiny** cores —
the biggest structural change of any block (SemiAnalysis teardown). **Huawei does
not publish TOPS**, so any "N× TOPS" number is third-party/estimated. Treat raw
TOPS as *unknown*; validate empirically (tokens/s, ms/inference).

**Why this matters for the app:** 12–16 GB RAM is enough to hold a quantized
0.5B–3B LLM or a small vision/NLP model resident, provided the platform lets a
third-party app allocate it.

---

## 3. Developer-facing on-device AI surface (from the SDK we installed)

Inspected `~/ohos/command-line-tools/sdk/default` (HarmonyOS 5.1.0 / API 18):

### OpenHarmony (also present on Oniro)
- **`@kit.MindSporeLiteKit` → `@ohos.ai.mindSporeLite`** — load `.ms`/`.mindir`
  models (`loadModelFromFile/Buffer/Fd`), build a `Context` selecting a device,
  including `NNRTDevice` with `NNRTDeviceType` = `CPU | GPU | ACCELERATOR` (NPU).
  Supports inference *and* on-device training.
- **`@ohos.data.intelligence`** (ArkData, since API 15) — built-in on-device
  **text embedding** and **image embedding** models (`getTextEmbeddingModel`,
  `getImageEmbeddingModel`) — ideal for RAG / semantic features without a
  custom model.
- **`MultimodalAwarenessKit`** — sensing/multimodal context.

### HMS (HarmonyOS only; NOT on Oniro)
- `NaturalLanguageKit` (`@hms.ai.nlp.textProcessing`), `SpeechKit` /
  `CoreSpeechKit` (`@hms.ai.speechRecognizer`, `@hms.ai.textToSpeech`),
  `VisionKit` / `CoreVisionKit` (`@hms.ai.vision.*` object detection, subject
  segmentation, skeleton, OCR, face detect/compare, liveness),
  `IntentsKit` (`@hms.ai.insightIntent.*`) — the OS-level "agent framework"
  integration where Celia/agent services invoke app intents.

### Inference stack
```
ArkTS app ──> @ohos.ai.mindSporeLite ──> MindSpore Lite runtime
   │                │
   │                └─> NNRt (Neural Network Runtime) ──> Kirin NPU (HiAI)
   └─ native (N-API/C++) ──> MindSpore Lite C/C++ API  ──> CPU / NNRt
```
`.ms` models are converted from MindSpore/ONNX/TF/TFLite/Caffe via the MindSpore
Lite converter. NPU access historically went through the **HUAWEI HiAI DDK**
(`libhiai*.so`); NNRt is the OpenHarmony-standard bridge.

---

## 4. Feasibility by model class

| Model class | On-device feasible? | Path | Emulator? | Notes |
| --- | --- | --- | --- | --- |
| Classical CV / tabular ML (YOLO, ViT, small CNN/GBDT) | **Yes, mature** | MindSpore Lite `.ms`, ArkTS or NAPI | **Yes (CPU)** | Docs say MindSpore Lite is "debuggable using the Emulator"; NPU only on device |
| Embeddings / rerankers (RAG) | **Yes** | `@ohos.data.intelligence`, or Qwen3-Embedding/BGE `.ms` | Yes (CPU) | Great privacy-preserving option |
| Decision/routing (e.g. **LAYA** non-autoregressive) | **Yes** | export → ONNX → `.ms`; run CPU/NPU | Yes (CPU) | Tiny, millisecond-scale; ideal on-device |
| Small generative LLM (Qwen 0.5B–3B, quantized) | **Yes, officially targeted** | MindSpore Lite **LLM module (Kirin NPU)**, `.ms` | Limited — CPU-only, slow/tight RAM | Huawei's model zoo lists Qwen2/2.5/3/3.5 0.5B–9B |
| VLM / ASR / TTS | **Yes** | MindSpore Lite (Qwen3-VL, Qwen3-ASR, CosyVoice2) | CPU-only, slow | |
| Large LLM (>7B) / image-video generation | Risky on-device | cloud/Ascend | No | Memory/thermal bound |

**LAYA specifics.** `convaiinnovations/laya` (HuggingFace), described as a
"RLCD-reinforced, millisecond-level, non-autoregressive decision/routing model"
targeting classification/triage/routing on phones and IoT. It is *not* an
autoregressive chat LLM, so it should be far cheaper than even a 0.5B LLM.
**Unverified:** its exact parameter count/architecture and whether a ready `.ms`/
GGUF build exists — it likely needs ONNX export + MindSpore Lite conversion.

---

## 5. Constraints & risks

1. **No NPU on the emulator.** Our Oniro/QEMU emulator (API 23) is CPU-only; the
   HMS AI kits are absent. A credible demo of NPU-local inference needs a real
   Huawei phone.
2. **Huawei account / DDK gating.** HiAI/NPU tooling has historically required a
   Huawei developer account (and sometimes enterprise agreements). Confirm before
   committing to an NPU-dependent demo.
3. **`.ms` conversion, not arbitrary runtimes.** You cannot ship arbitrary
   PyTorch/GGUF weights unchanged; they must be converted (ONNX → `.ms`), and
   operator/NPU support is model-dependent.
4. **Memory & thermals.** 12–16 GB RAM is shared with the OS; sustained LLM
   generation throttles. Budget for quantized weights and short contexts.
5. **Closed vs open split.** Great AI kits are HMS (HarmonyOS). On OpenHarmony/
   Oniro you get MindSpore Lite + embeddings only.
6. **API level.** Challenge requires **API ≥ 20**; our SDK is API 18. MindSpore
   Lite and `data.intelligence` exist at API 15–18, so API 20 is fine — but the
   build SDK must be upgraded (Oniro `6.0` = API 20, `6.1` = API 23).

---

## 6. Recommendation for the hackathon

Given "must run on an emulator or compatible device" and "demonstrate real use of
a platform capability":

- **If you have a Huawei phone** (Mate 60/70/80, Pura 70/80/90): build the real
  on-device experience with **MindSpore Lite + Kirin NPU** — a small LLM or a
  LAYA-style decision model, plus `data.intelligence` embeddings for RAG. This is
  the strongest, most differentiated demo and clearly hits "Intelligent
  Experiences".
- **If you only have the emulator:** design so the **model runs on CPU** on the
  emulator and opportunistically switches to `NNRTDeviceType.ACCELERATOR` on
  device. Keep the model tiny (embeddings, LAYA-style router, or a quantized
  ≤0.5B model). Document the device-only NPU path as the production target.
- **Avoid** committing to >3B generative LLMs or image/video generation on-device.

---

## 7. Open questions

1. Which Huawei device(s) can we actually test on (model + RAM + OS version)?
2. Is "LAYA" the `convaiinnovations/laya` HF model, or a different internal model?
3. Do we have/can we get a **Huawei developer account** for NPU/DDK and, if
   needed, AGC signing?
4. Demo target: emulator (CPU) vs physical device (NPU) — this decides the model
   size ceiling and the feature set.

## Sources
- Huawei Mate 80 — Wikipedia; PhoneArena; consumer.huawei.com specs.
- MindSpore Lite — official docs (NPU integration, HiAI DDK), GitHub README
  (device-side LLM module, model zoo), OpenHarmony MindSpore Lite Kit intro.
- SDK inspection: `@kit.MindSporeLiteKit`, `@ohos.ai.mindSporeLite`,
  `@ohos.data.intelligence`, `@hms.ai.*`, `@kit.*Kit` (API 18).
- SemiAnalysis teardown (Kirin 9030 vs 9020 NPU cores).
- `convaiinnovations/laya` (HuggingFace) via AWS China blog / 163.com coverage.
