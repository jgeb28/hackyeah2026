# Guardian — an on-device scam & misinformation copilot for HarmonyOS

Guardian is a camera-anchored **Smart Island** that watches the text you point it at,
classifies it **on-device**, and warns you about scams and misleading content before
you act. It is a normal HarmonyOS app (a HAP + a reusable `guardian_sdk` HAR) — not a
system or accessibility service.

**Challenge areas:** *Human-Centric Technology* (accessible, wellbeing-focused
guidance) + *Intelligent Experiences* (on-device AI).

## What it does

1. Tap **Guard** → a floating pill appears just under the camera cutout.
2. Tap the pill → **Select area** → drag a box around any text → **Scan this area**.
3. Guardian captures the screen, crops to the box, runs **on-device OCR (PP-OCRv4)**
   and a **local classifier (LAY A on MindSpore Lite)**, and shows the matched
   incident in the island — a severity-coloured pill you can expand, with a **Details**
   page (*What this is / Why it matters / What to do*).

The engine is **offline by default**. The only non-on-device features are an optional
**dev-only** remote backend (for fast iteration) and an optional **DeepSeek "Describe"**
action on higher-escalation incidents, which is served through a backend so the API
key is never shipped (see *Optional cloud*).

## Repository layout

| Path | Contents |
| --- | --- |
| `HuaweiChallenge/` | Guardian app (`entry/`) + `guardian_sdk/` HAR |
| `mocks/mockchat/` | WeChat-like host app that reports messages via the SDK |
| `tests/unit/` | device-free unit tests (`node --test`) |
| `DESIGN.md`, `RUNNING.md`, `AI_INTEGRATION.md` | architecture, run guide, AI/model contract |
| `AGENTS.md`, `AI_WORKFLOW.md`, `DATA_SCIENCE.md` | agent rules, AI workflow log, model data science |

> The LAY A fetch/convert helper scripts under `tools/` are **kept out of the repo**
> (`AGENTS.md` §9) and distributed with the release assets; see *Model asset* below.

## Requirements

| Tool | Version / note |
| --- | --- |
| DevEco Studio + HarmonyOS SDK | `6.1.1(24)` (project `compileSdkVersion`), `compatibleSdkVersion 6.0.0(20)` — **minimum API 20** |
| JDK | **17** on `PATH` (the package step shells out to `java`) |
| Node.js | ≥ 20 (DevEco's bundled `tools/node` works) |
| Device | a HarmonyOS/OpenHarmony emulator or device visible to `hdc` |

> **Build from the project's canonical-cased path.** `hvigor` compares
> `realpathSync` output to the path you give it; if the on-disk case differs (e.g.
> `C:\hackyeah2026` vs `C:\Hackyeah2026`) the build fails with `PATH_NOT_FOUND`.

## Assets (models)

Committed to the repo: the PP-OCRv4 models (`rawfile/ocr/det.ms`, `rec.ms`,
`ppocr_keys_v1.txt`, `sample.png`), the LAY A tokenizer + converter metadata
(`rawfile/tokenizer.json`, `rawfile/laya_guardian_meta.json`), and the incident KB
(`rawfile/kb/en/incidents.json`).

**Not committed:** the LAY A classifier `laya_en_w8_s256.ms` (~413 MB — over GitHub's
100 MB file limit; gzip only reaches ~382 MB, so it can't be committed either). It is
hosted on **Hugging Face** at
[`s3r10us3r/LAYA-hackyeah2026`](https://huggingface.co/s3r10us3r/LAYA-hackyeah2026)
(the LAY A `.ms` + metadata + tokenizer and the PP-OCRv4 `.ms` all live there). Drop
them into the rawfile dir:

- **A. Let the build fetch it (recommended):** `build.ps1` / `build.sh` / `build.py`
  download the missing `.ms` from the HF repo before building. To manage the models
  yourself, use `fetch_model.py` (distributed with the release assets; `tools/` stays
  out of the repo per `AGENTS.md` §9), which downloads every model asset into
  `rawfile/` and verifies the `MSL2` magic and byte size:
  ```powershell
  python tools/fetch_model.py --out-dir .        # or --repo <org>/<name>, HF_TOKEN=...
  ```
  Or fetch the one file directly:
  ```powershell
  $URL = "https://huggingface.co/s3r10us3r/LAYA-hackyeah2026/resolve/main/laya_en_w8_s256.ms"
  Invoke-WebRequest -Uri $URL -OutFile `
      "HuaweiChallenge/entry/src/main/resources/rawfile/laya_en_w8_s256.ms"
  ```
  To re-host: `hf upload <org>/<repo> <file>` (or a GitHub Release, ≤ 2 GB).
- **B. Build it:** the converter (`convert_laya.py`, kept out of the repo) runs on
  Windows or Linux with MindSpore Lite's `converter_lite`; see `AI_INTEGRATION.md`
  for the full contract.

If the `.ms` is absent the app still **builds, installs and runs**; the classifier
reports that the on-device model is unavailable (no fabricated result).

## Build

One-command build (fetches the models if missing, then builds **only the `entry`
app** — not the mocks): `build.ps1` (Windows), `build.sh` (macOS/Linux), or
`build.py` (any OS):

```powershell
.\build.ps1                 # Windows
python build.py             # cross-platform
```
```bash
./build.sh                  # macOS / Linux
```

Or build directly with hvigor:

```powershell
$DEVECO   = "<DevEco Studio>"          # e.g. C:\Program Files\Huawei\DevEco Studio
$PROJ     = "<repo>\HuaweiChallenge"
$env:DEVECO_SDK_HOME = "$DEVECO\sdk"
Set-Location $PROJ
& "$DEVECO\tools\node\node.exe" "$DEVECO\tools\hvigor\bin\hvigorw.js" `
    --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone `
    assembleHap --no-daemon
```

Output: `entry/build/default/outputs/default/entry-default-unsigned.hap` (or
`entry-default-signed.hap` when a local signing config is present).

## Install & launch

```powershell
$HDC = "$DEVECO\sdk\default\openharmony\toolchains\hdc.exe"
$TARGET = "<device, e.g. 127.0.0.1:5555>"
& $HDC -t $TARGET install -r "$PROJ\entry\build\default\outputs\default\entry-default-unsigned.hap"
& $HDC -t $TARGET shell aa start -a EntryAbility -b com.example.huwaweichallenge
```

See `RUNNING.md` for the on-screen flow and live logs.

## Tests

```powershell
# device-free unit suite (Node >= 20 + TypeScript)
tsc -p tsconfig.tests.json
node --test ".test-build/tests/unit/*.test.js"        # 31/31
```

On-device integration tests live in `entry/src/ohosTest` (hypium); build + install the
`ohosTest` HAP and run `aa test -b com.example.huwaweichallenge -m entry_test -s unittest OpenHarmonyTestRunner`.

## Optional cloud

The core product is **offline**. Two optional, non-default paths use the network:

- **Dev "Remote GPU" backend** — the in-app **Dev mode** switch routes OCR/LAY A to a
  host server (kept **outside** the repo, e.g. `C:\guardian-devserver`) over
  `hdc rport tcp:9100 tcp:9100`, for fast iteration on the emulator or a tethered
  device.
- **DeepSeek "Describe"** — on incidents whose `escalation` is above the lowest level,
  the user can tap **Describe with DeepSeek**. The app calls DeepSeek **directly**
  (`api.deepseek.com`) with **the user's own API key**, entered in Settings and stored
  on-device (`preferences`). For that one request the scanned text and the incident are
  sent to DeepSeek; nothing is transmitted unless the user opts in.

The DeepSeek key is a **runtime credential supplied by the user** — nothing is baked
into the repo or the HAP. Remove the `dev/` + `DeepSeek*` code and
`ohos.permission.INTERNET` for a strictly offline build.

## Security & hygiene

- **No secrets in the repo.** The DeepSeek key is entered by the user at runtime and
  kept in on-device `preferences`; no key is committed or bundled.
- Permissions: `CUSTOM_SCREEN_CAPTURE` (normal / user-granted),
  `KEEP_BACKGROUND_RUNNING` (normal), `SYSTEM_FLOAT_WINDOW` (**system_basic** — the
  floating island, which needs an ACL-enabled signing profile; see `DESIGN.md` §12),
  and the optional `INTERNET` (dev / cloud paths only).
- Screen capture always shows the system indicator (a third-party app cannot capture
  silently); the captured frame is released immediately after OCR.

## Docs

| File | What it contains |
| --- | --- |
| `DESIGN.md` | Product & architecture design; §17 as-built; §18 the incident KB. |
| `RUNNING.md` | How to run: island behaviour, the scan flow, live logs, limitations. |
| `AI_INTEGRATION.md` | The on-device AI: what LAY A is, the OCR, the DeepSeek fallback, the fine-tuning **data science**, the model contract, privacy. |
| `DATA_SCIENCE.md` | Deep dive: dataset ([DIFrauD](https://huggingface.co/datasets/difraud/difraud)), incident labelling, fine-tune, calibration, 5-fold CV results. |
| `AI_WORKFLOW.md` | The team's AI-assisted development workflow (required deliverable). |
| `AGENTS.md` | The rules every AI agent followed in this repo. |
