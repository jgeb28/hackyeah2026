# Guardian — AI integration

How Guardian's AI works: the **on-device** model (LAY A), the **OCR**, the **data
science** behind the fine-tune, and the optional **DeepSeek** action. The product
is **offline by default** — the on-device path needs no network; the optional cloud
paths are described in §4.

> This is the AI-integration document that [`AI_WORKFLOW.md`](./AI_WORKFLOW.md) links
> to. The full data-science methodology (every number, script and caveat) is in
> [`DATA_SCIENCE.md`](./DATA_SCIENCE.md).

---

## 1. What is LAY A

[`convaiinnovations/laya`](https://huggingface.co/convaiinnovations/laya) is a
**non-autoregressive "System 1" decision model** — a classifier, **not an LLM**.
Its base is a **ModernBERT-large** encoder (28 layers, hidden 1024, ~395 M params)
plus a small custom **2-layer decision head** (~26 M) = **421 M**. You give it a
**state** (text) and a set of **typed questions** (`choice` / `score` / `noul`);
it returns typed answers with calibrated probabilities in a **single forward pass**.

Guardian ships a **fine-tuned** variant that answers two questions, both **baked
into the on-device graph**:

1. **`deception`** — *choice* `[safe, deceptive]`: is the text trying to deceive or
   mislead the reader? This is the **alert gate**.
2. **`incident`** — *choice* over the **8 incident ids** in
   `rawfile/kb/en/incidents.json`: which known incident does it best match? (Only
   chooses which case copy to show.)

## 2. Data science — how the model was fine-tuned

**Dataset: [DIFrauD](https://huggingface.co/datasets/difraud/difraud)**
(Domain-Independent Fraud Detection benchmark, MIT) — 95,854 binary
deception-labelled texts across 7 domains (`{text, label}`).

- **Task alignment.** DIFrauD's "deceptive" is broader than "tries to deceive the
  reader". We keep `phishing`, `job_scams`, `sms`, `twitter_rumours`, `fake_news`,
  and a **filtered** `political_statements`; we **drop `product_reviews`** (fake
  reviews, not scams). `political_statements` is kept only when the row is deceptive
  **and reads as a factual claim** (contains a number / statistic marker) — fabricated
  claims, not opinions — and those are **relabelled as misinformation**.
  `label=1 → deceptive`, `label=0 → safe`.
- **UI augmentation (hard negatives).** Real SMS/email has no UI chrome, but the app
  OCRs the **whole screen**, so we add app-UI / chrome text (status bar, Back/Menu/
  Settings, "Guardian/Screenshot/Close", …) as **`safe`** — this is what stops the gate
  firing on system chrome.
- **Incident labels (Q2 supervision).** DIFrauD has no incident ids, so every
  **deceptive** row is described by one of the 8 KB incidents — misinformation rows →
  `misinfo-breaking-event`; scam rows → KB keyword match (default
  `bank-authority-impersonation`). Safe rows carry **no incident label** and are
  excluded from the Q2 loss. DIFrauD has no harassment data, so the two harassment
  cases are supplemented from a synthetic set. **The incident labels are rule-derived,
  not human ground truth — a stated limitation.**
- **Sets:** train **63,872** (23,998 deceptive) / test **7,371** (2,899 deceptive),
  disjoint author splits; texts truncated to 2,000 chars.
- **Fine-tune:** **head-only, frozen-encoder** supervised — cross-entropy over each
  choice question's per-option `[MASK]` logits (trainable **26.5 M / 421 M = 6.3%**),
  AMP bf16, AdamW, class weighting, 2 epochs. Train and inference share the *same*
  `build_sequence`, so **train == inference**.
- **Calibration:** **temperature scaling** (`T`) + the **decision threshold**, fit by
  **5-fold CV** on the held-out test set (no leakage into hyperparameters).

### Results
| metric | value |
| --- | --- |
| Deception **ROC-AUC** (5-fold CV) | **0.930** |
| Deployed temperature (baked into the `.ms`) | **T = 1.0485** |
| Alert gate `DECEPTIVE_DANGEROUS` | **0.25** → ~**7% FNR / 27% FPR** (recall-first) |
| `DECEPTIVE_CRITICAL` | **0.55** |
| Incident accuracy / macro-F1 | 0.639 / **0.329** (weak; display only) |

The gate is deliberately **recall-first**: a missed scam is worse than a false alarm.
Full tables, the confusion data and the calibration sweep are in
[`DATA_SCIENCE.md`](./DATA_SCIENCE.md).

## 3. The OCR we use

HarmonyOS **Core Vision Kit OCR is not available on emulators**, so Guardian ships
its own **PP-OCRv4** models (text **detection + recognition**) converted to
MindSpore Lite (`rawfile/ocr/det.ms`, `rawfile/ocr/rec.ms`) and runs them via
`@kit.MindSporeLiteKit` on the CPU:

- **det** — NHWC `[1,960,960,3]` → DB post-process → text quads;
- per-box affine crop → **rec** `[1,48,960,3]` → **CTC** decode with
  `rawfile/ocr/ppocr_keys_v1.txt` → lines joined in reading order.
- **Chrome filtering:** the status bar, nav bar and Guardian's own island are dropped
  before recognition.
- **Validation:** matches an ONNX-Runtime reference (recognition max|Δ| ≈ 3e-5; 6/6
  lines correct on device).

The OCR text is the LAY A **state**; the whole thing runs in memory and the captured
frame is released immediately after OCR.

## 4. The DeepSeek "Describe" action (optional)

The offline verdict comes from LAY A + the incident KB. For **higher-escalation**
incidents (`escalation` L1/L2) the app can additionally offer a plain-language
**"Describe with DeepSeek"** — richer, message-specific wording for the user.

- **Not the default.** Offline is the product; this is a user-triggered enhancement.
- **Bring-your-own key, direct call.** The user enters their own DeepSeek API key in
  Settings; it is stored on-device (`preferences`) and the app calls
  `api.deepseek.com` directly (`dev/DeepSeekClient.ets`). There is **no Guardian
  server** and no key in the repo or the HAP. The request sends the scanned text + the
  incident copy for that single incident; it happens only when the user taps the
  action, and requires `ohos.permission.INTERNET`.
- **Remove for a strictly offline build:** the `dev/` + `DeepSeek*` code, the in-app
  Dev-mode/cloud UI, and `INTERNET`.

## 5. Inference flow (on-device by default)

1. The user scans a screen region; `vision/ScreenScanner` captures it and runs OCR (§3).
2. `vision/LayaClassifier` → `AnalyseMessageUseCase.run(text)`.
3. The use case builds the **two** typed questions from `GuardianSchema` (§1).
4. `DecisionRepositoryImpl` → `MindSporeLiteEngine`: `BpeTokenizer` →
   `input_ids`/`attention_mask` → worker-hosted `model.predict` → per-question
   softmax → `LayaResponse`.
5. **Verdict** = `P(deceptive)` vs the thresholds (§2). The chosen incident id → the
   KB (`alert/IncidentKb`) supplies the title / category / severity, and the island
   shows its explanation and next steps (or the Details page).

**Privacy:** the text is read from the screen and processed in memory; nothing is
transmitted. The only storage is the optional local detection log (DESIGN.md §10).

## 6. On-device model contract (what the `.ms` exposes)

The graph is exported with Guardian's fixed label space baked in (from
`GuardianSchema` + the KB):

| Tensor | Type | Shape | Meaning |
| --- | --- | --- | --- |
| `input_ids` | int32 | `[Q, max_len]` | one full Laya sequence per question |
| `attention_mask` | int32 | `[Q, max_len]` | 1 for real tokens, 0 for pad |
| `logits` | fp32 | `[1, Q, MAX_OPTIONS]` | per-question score per option (temperature-scaled) |

`Q = 2` (deception, incident); `MAX_OPTIONS = 8` (the KB incidents,
`GuardianSchema.maxOptions()`); `max_len` is read from `laya_guardian_meta.json`
(**512**). The instructions, option markers, head budget and temperatures are
**baked into the graph** by the converter (`convert_laya.py`, kept out of the repo
per `AGENTS.md` §9), which builds the question from `rawfile/kb/en/incidents.json`.
The **prefixes** (token ids) are exported to `laya_guardian_meta.json`, and the app
builds the sequence as `prefix + state + [SEP] + pad`, matching Laya exactly.

> Changing `GuardianSchema` (questions / labels / `MAX_OPTIONS`) requires
> **re-exporting the `.ms`** so the graph matches (root `AGENTS.md` §11).
> The shipped artefact is `laya_en_w8_s256.ms`; the `s256` suffix is a **legacy
> name** — the deployed graph uses `max_len = 512`.

## 7. Tokenizer

Laya's tokenizer is a **GPT-2-style ByteLevel BPE** (NFC normalizer,
`[CLS] … [SEP]` post-processor). Because the text must not leave the device,
`BpeTokenizer.ets` reproduces it in ArkTS (byte→unicode map, GPT-2 pre-tokenizer
regex, greedy merge by rank, vocab lookup). The same `tokenizer.json` is bundled.

## 8. Acceleration & quantisation

- **Acceleration:** OpenHarmony/HarmonyOS ship **MindSpore Lite**
  (`@kit.MindSporeLiteKit`), which can dispatch to **NNRt** (the NPU on Kirin
  devices). `MindSporeLiteEngine` prefers NNRt and falls back to CPU;
  `NnrtAccelerationProbe` reports the real backend. The **emulator is CPU-only**.
- **Quantisation** happens once at export (not at runtime):
  `w8` weight-only int8 (~413 MB, **shipped**) runs on the x86 emulator; `fp32`
  (~1.69 GB) is validated-correct but too big; `dyn8` crashes the x86 int8 gather
  kernel — unusable. Quantisation + sequence length change the verdict, so diff
  against the validated fp32 graph before trusting a new artefact.

## 9. Assets & fetching

Model artefacts (`*.ms`) are **git-ignored** (too large) and hosted on Hugging Face:
[`s3r10us3r/LAYA-hackyeah2026`](https://huggingface.co/s3r10us3r/LAYA-hackyeah2026).
The small JSON/text assets (`tokenizer.json`, `laya_guardian_meta.json`, the incident
KB) are committed. `tools/fetch_model.py` restores every `.ms` into `rawfile/` and
verifies the `MSL2` magic and byte size (see the README *Assets* section).

## 10. Limitations

- **Incident head is weak** (macro-F1 ≈ 0.33) — it only picks the display copy and
  cannot raise or clear an alert.
- **Rule-derived incident labels** (keyword overlap), not human ground truth.
- **DIFrauD label semantics** (esp. job-scam polarity) assumed `1 = deceptive`.
- **Domain shift:** DIFrauD is SMS/email; deployment is whole-screen OCR text —
  mitigated by UI augmentation but not solved. **English-only**, 8 incidents.
- **Emulator is CPU-only**, so LAY A inference there is slow (hence `w8`, shorter
  sequences); a Kirin phone uses the NPU via NNRt.

## See also

- [`DATA_SCIENCE.md`](./DATA_SCIENCE.md) — full methodology (dataset, training,
  calibration, CV results).
- [`DESIGN.md`](./DESIGN.md) — architecture and the incident KB (§17 as-built, §18).
- [`RUNNING.md`](./RUNNING.md) — how to run and read the logs.
- [`AI_WORKFLOW.md`](./AI_WORKFLOW.md) — how the agents built this.
