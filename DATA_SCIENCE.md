# Guardian — LAY A data science (DIFrauD + UI augmentation)

This documents the dataset, fine-tuning, calibration, and cross-validated
evaluation of the on-device LAY A classifier used by Guardian. All tooling and
data live **outside the repo** (`C:\guardian-finetune`, `C:\guardian-data`).

## 1. Objective — the exact working-tree schema
The model answers the two questions defined in the forked contract
(`tools/laya/convert_laya.py` + `entry/.../domain/model/GuardianSchema.ets`):

1. **`deception`** — *choice* `[safe, deceptive]`: is the text trying to deceive
   the reader? (the alert gate)
2. **`incident`** — *choice* over the **8 incident ids** in
   `rawfile/kb/en/incidents.json` (option text = *"description — keywords"*): which
   known incident does it best match? (`maxOptions` = 8)

Both are non-autoregressive choices; the on-device `.ms` bakes the questions in.

## 2. Data
### 2.1 Real corpus — DIFrauD
[DIFrauD](https://huggingface.co/datasets/difraud/difraud) (Domain-Independent
Fraud Detection benchmark, MIT): **95,854** binary deception-labelled texts across
**7 domains**. Fields `{text, label}`.

**Task alignment:** DIFrauD's "deceptive" is broader than "tries to deceive/scam the
reader". We keep `phishing`, `job_scams`, `sms`, `twitter_rumours`, `fake_news`, and
a **filtered** `political_statements`; we **drop `product_reviews`** (fake reviews,
not scams). `political_statements` is kept only where the row is deceptive **and
reads as a factual claim** (contains a number / statistic marker) — fabricated
claims, not opinions — and those are **relabelled as `misinformation`**.

Mapping: `label=1 → deceptive`, `label=0 → safe`. Train = `train`+`validation`,
test = `test` (disjoint author splits). Texts truncated to 2,000 chars (some
phishing emails are multi-megabyte and choke the tokenizer).

### 2.2 UI augmentation (hard negatives)
Real SMS/email has no UI chrome, but the app OCRs the **whole screen**. We add
**app-UI/chrome text as `safe`**: our synthetic `app_ui` rows plus a fixed
chrome list (status bar, Back/Menu/Settings, "Guardian/Screenshot/Close", etc.), so
the gate does not fire on system chrome. This directly targets the earlier
false-positive failure mode.

### 2.3 Incident labels (Q2 supervision)
DIFrauD has no incident ids, so **every deceptive row is described by one of the 8
threat incidents** in the KB:
- misinformation rows (`fake_news`, `twitter_rumours`, filtered `political_statements`) →
  **`misinfo-breaking-event`**;
- scam rows (`phishing`, `job_scams`, `sms`) → **KB keyword match**, defaulting to
  **`bank-authority-impersonation`** when nothing matches.

Safe rows carry **no incident label** and are excluded from the Q2 loss (`no-threat`
was removed from the option set — a safe verdict already means "no incident"). Both
questions are still supervised on deceptive rows. The scam incident id is a weak,
rule-derived label — a stated limitation. DIFrauD has no harassment data, so the two
harassment cases (`sextortion-blackmail`, `hate-abuse`) are supplemented from our
synthetic harassment set (keyword-decided).

> **Label-id fix:** earlier data used the incident id `misinfo-breaking-event`; the KB
> was later renamed to `unverified-alarming-news`, which silently dropped every
> misinformation row from the Q2 loss (`row_label` → IGNORE). The KB id was restored to
> `misinfo-breaking-event` and `no-threat` removed, so `misinfo-breaking-event` is now
> index 1 of 8 and the existing head classifies fake news correctly.

### 2.4 Resulting sets
| split | rows | deceptive | safe | misinfo-labelled | with incident label |
|---|---|---|---|---|---|
| train | 63,872 | 23,998 | 39,874 | 13,458 | 63,872 |
| test | 7,371 | 2,899 | 4,472 | 1,504 | 7,371 |

Sources: `difraud` (task-aligned domains) + `synthetic-ui` + `ui-chrome`.
Class weighting compensates the safe-heavy skew. Misinformation rows are forced to
incident `misinfo-breaking-event`; scam rows get a KB keyword-matched incident.

Scripts: `difyrau_prep.py` (build), `data.py`/`common.py` (loader+sequencer, reuses
the repo's `rl_common.build_sequence` so **train == inference**).

## 3. Model & fine-tuning
- Base: `convaiinnovations/laya` = **ModernBERT-large encoder (28 layers, hidden
  1024, ~395 M)** + 2-layer decision head (~26 M) = **421 M**.
- **Head-only (frozen-encoder) supervised** fine-tune: cross-entropy over each
  choice question's per-option `[MASK]` logits; encoder frozen (`trainable 26.5 M /
  421 M, 6.29%`). AMP bf16, AdamW, class weighting, head_loss_weights
  `{deception: 1.0, incident: 0.5}`. 2 epochs (1,250 steps), batch 32 × accum 2.

## 4. Calibration
The head is **overconfident** (probabilities saturate at 0/1). We fit a
**temperature `T`** (probability/Platt scaling on the deception score) and treat
the **decision threshold** as a second hyperparameter.

## 5. Evaluation — 5-fold cross-validation
On the **held-out DIFrauD+UI test set**, with `T` and the threshold **fit on train
folds and evaluated on held-out folds** (no test leakage into hyperparameters):
- **Q1 `deception`**: ROC-AUC, and TPR/**FNR**/FPR/balanced-accuracy at (a) the
  balanced threshold and (b) a **recall-first** threshold (train-fold FNR ≤ 5%),
  since missed scams are the costlier error.
- **Q2 `incident`**: top-1 accuracy and macro-F1 over deceptive rows with a KB id.

## 6. Results

Fine-tune (head-only, frozen encoder; validation split):

| epoch | val_loss | deception AUC | bal-acc @thr | incident acc |
|---|---|---|---|---|
| 0 | 0.9093 | 0.8975 | 0.8184 @0.54 | 0.5965 |
| **1** | **0.7717** | **0.9231** | **0.8523 @0.47** | **0.6625** |

5-fold CV on the held-out test set (`n=2500`; `T` + threshold fit on train folds):

| metric | value |
|---|---|
| Q1 CV AUC | **0.9302** |
| Q1 balanced-thr: T, thr, TPR, FNR, FPR, bal | 0.52, 0.46, 0.850, 0.150, 0.135, 0.858 |
| Q1 recall-first (FNR≤5%): thr, TPR, FNR, FPR | 0.05, 0.985, 0.015, 0.661 |
| Q2 incident accuracy / macro-F1 (`n=1982`) | **0.639 / 0.329** |

**Deployed operating point.** The single deploy temperature (fit on all test data,
composed with the config's previous `choice:2`) is **`T_bake = 1.0485`**, baked
into the `.ms`. At this calibration, the shipped alert gate uses
`DECEPTIVE_DANGEROUS = 0.25` (**FNR 6.9% / FPR 27.0%**, balanced 0.830) and
`DECEPTIVE_CRITICAL = 0.55` — the middle, recall-leaning point requested by the
product owner. (Temperature scaling does not change the `incident` argmax, so Q2
needs no temperature.)

## 7. Limitations
- **Incident labels are rule-derived** (keyword overlap), not human ground truth;
  Q2 numbers are illustrative.
- **DIFrauD label semantics** (esp. job-scam polarity) assumed `1=deceptive`.
- **Domain shift**: DIFrauD is SMS/email; deployment is whole-screen OCR text —
  mitigated by UI augmentation but not solved.
- **English-only**, and the base head is not calibrated for this bespoke question
  without fine-tuning + temperature.
- **On-device `.ms` export**: `converter_lite` also ships for Windows (2.4.1), but
  dropped `--quantType`; weight quantization now needs a `--configFile` INI
  (`quant_type = WEIGHT_QUANT`). The repo's `convert_laya.py` ONNX export was
  patched with a static-mask override (ModernBERT's `_update_attention_mask` path
  emits dynamic-shape ops the Lite CPU runtime rejects). Parity with the app
  schema is mandatory before shipping (root AGENTS §11).

## 8. Reproducibility
```powershell
# data
uv run python C:\guardian-finetune\difyrau_prep.py
# train (head-only, capped)
uv run python C:\guardian-finetune\train.py --config C:\guardian-finetune\config_difraud.json
# cross-validated eval (both questions)
uv run python C:\guardian-finetune\calib_cv_difraud.py
# export ONNX graph (temperature baked from rl_agent_config.json)
uv run python C:\hackyeah2026\tools\laya\convert_laya.py `
  --model-dir C:\guardian-finetune\out_difraud\runtime `
  --out-dir   C:\guardian-finetune\out_difraud\export --skip-download --export-only
# quantize ONNX -> .ms (Windows MindSpore Lite 2.4.1; put tools/converter/lib + runtime/lib on PATH)
converter_lite.exe --fmk=ONNX \
  --modelFile=C:\guardian-finetune\out_difraud\export\laya_guardian.onnx \
  --outputFile=C:\guardian-finetune\out_difraud\export\laya_guardian \
  --configFile=C:\guardian-finetune\msl\weight_quant.cfg   # [common_quant_param] quant_type = WEIGHT_QUANT
```
