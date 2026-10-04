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
| `HuwaweiChallenge/` | Guardian app (`entry/`) + `guardian_sdk/` HAR |
| `mocks/mockchat/` | WeChat-like host app that reports messages via the SDK |
| `facebook-feed-mock/` | static web feed used to demo the screen scan |
| `tests/unit/` | device-free unit tests (`node --test`) |
| `DESIGN.md`, `RUNNING.md`, `LAYA_INTEGRATION.md` | architecture, run guide, model contract |
| `AGENTS.md`, `AI_WORKFLOW_*.md` | agent rules + per-developer AI workflow logs |

> The LAY A fetch/convert helper scripts under `tools/` are **kept out of the repo**
> (`AGENTS.md` §9) and distributed with the release assets; see *Model asset* below.

## Requirements

| Tool | Version / note |
| --- | --- |
| DevEco Studio + HarmonyOS SDK | `6.1.1(24)` (project `compileSdkVersion`), `compatibleSdkVersion 6.1.0(23)`, minimum API 20 |
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

**Not committed:** the LAY A classifier `laya_en_w8_s256.ms` (~412 MB — over GitHub's
100 MB file limit; gzip only reaches ~382 MB, so it can't be committed either), and
the small **fetch/convert helper scripts** (`tools/*.py`, `tools/laya/*.py` — kept
out of the repo per `AGENTS.md` §9 and distributed with the release assets). Host the
model once (**Hugging Face** or a **GitHub Release**) and drop it into the rawfile dir:

- **A. Fetch it (recommended):** download the hosted `.ms` straight into
  `entry/src/main/resources/rawfile/` and confirm it starts with the `MSL2` magic:
  ```powershell
  $URL = "https://huggingface.co/<org>/<repo>/resolve/main/laya_en_w8_s256.ms"
  Invoke-WebRequest -Uri $URL -OutFile `
      "HuwaweiChallenge/entry/src/main/resources/rawfile/laya_en_w8_s256.ms"
  ```
  To host it yourself:
  - **Hugging Face:** `huggingface-cli upload <org>/<repo> laya_en_w8_s256.ms`
    (direct URL: `https://huggingface.co/<org>/<repo>/resolve/main/laya_en_w8_s256.ms`).
  - **GitHub Release:** `gh release create guardian-v1 laya_en_w8_s256.ms` (≤ 2 GB).
- **B. Build it:** the converter (`convert_laya.py`, kept out of the repo) runs on
  Linux with MindSpore Lite's `converter_lite`; see `LAYA_INTEGRATION.md` for the
  full contract.

If the `.ms` is absent the app still **builds, installs and runs**; the classifier
reports that the on-device model is unavailable (no fabricated result).

## Build

```powershell
$DEVECO   = "<DevEco Studio>"          # e.g. C:\Program Files\Huawei\DevEco Studio
$PROJ     = "<repo>\HuwaweiChallenge"
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

## Optional cloud (dev-only)

Two features use a backend (kept **outside** the repo, e.g. `C:\guardian-devserver`):

- **Remote OCR + LAY A** — the in-app **Dev mode** switch routes OCR/inference to a
  host server over `hdc rport tcp:9100 tcp:9100` (works on the emulator and a tethered
  real device).
- **DeepSeek "Describe"** — shown on incidents whose `escalation` is above the lowest
  level; the app POSTs to the backend's `/describe`, which holds the API key.

**Keys are never shipped.** The DeepSeek key is a **server-side environment variable**
(`DEEPSEEK_API_KEY`) read by the backend process — not in the repo, the app, or the
HAP. For a device that is not tethered to the dev machine, run the same endpoint as a
hosted proxy and point the app's `baseUrl` at it.

## Security & hygiene

- No secrets in the repo; the dev-only `ohos.permission.INTERNET` and the remote code
  are marked for removal before a shipping build.
- Only normal / user-granted permissions (`CUSTOM_SCREEN_CAPTURE`,
  `SYSTEM_FLOAT_WINDOW`, `KEEP_BACKGROUND_RUNNING`).
- Screen capture always shows the system indicator (a third-party app cannot capture
  silently); the captured frame is released immediately after OCR.

## Docs

- `DESIGN.md` — product/architecture design + §17 as-built + §18 incident KB.
- `RUNNING.md` — how to run, island behaviour, logs, limitations.
- `LAYA_INTEGRATION.md` — the LAY A on-device model contract + AI feature notes.
- `AI_WORKFLOW_*.md` — per-developer AI-assisted workflow logs (required deliverable).
