# Guardian — running & testing

Guardian is a **camera-anchored Smart Island**. A floating pill sits just under the
front-camera cutout; tap it to expand, tap **Select area**, then drag a box around
the text to check. Guardian screenshots the screen, **crops to your box**, runs
on-device OCR + a local classifier, and shows the verdict in the island: green
"Looks safe" (it resets itself after a few seconds) or a red/orange warning with the
incident title. The small **x** turns the island off.

## Island behaviour

The island runs **only as a floating window** (`TYPE_FLOAT`); there is no in-app
island. The control screen (`Index`) has one button: **Guard** / **Stop guarding**.

> Code paths below are relative to `HuaweiChallenge/`.

- **Collapsed** — a small pill just under the camera cutout (`🛡 Guardian ✕`). Tap to
  expand.
- **Expanded** — shows the action (`Select area`, or `Details` on a scam) and `Close`.
- **Result** — the pill takes the incident's severity colour (red CRITICAL / orange
  WARNING / green SAFE); a CRITICAL result shows a 🛑 icon. Safe / no-text results
  auto-reset to the neutral pill after a few seconds. `Close` also resets to neutral.
- **x** — destroys the floating window and its background task.

The window is positioned from `display.getCutoutInfo()` (centred on the camera,
top edge just below the cutout), so it adapts to the device's cutout.

## How a scan works

Tap the pill → **Select area** → a full-screen dim overlay (`SelectorOverlay` /
`pages/SelectArea`) appears → **drag a box** around the text → **Scan this area**.
Guardian then: `screenshot.capture()` (whole display) → **crop to the box**
(`PixelMap.crop`, vp→px) → **on-device PP-OCRv4** (`ets/ocr/`) → **classify**
(`vision/LayaClassifier` → LAYA) → map the category to an **incident**
(`alert/IncidentKb.forText`, keyword-matched) → show it. The captured `PixelMap` is
released right after OCR; the image is never kept. The island is hidden from the
capture (`setWindowPrivacyMode`).

**Details** opens `pages/IncidentDetail` **inside the island window** (a background
app may not start an ability): it renders the incident JSON — *What this is / Why it
matters / What to do*.

## On-device OCR — emulator limitation

HarmonyOS Core Vision Kit OCR is not available on emulators, so Guardian ships its
own **PP-OCRv4** models (det + rec) converted to MindSpore Lite and run via
`@kit.MindSporeLiteKit`; this works on the emulator (CPU). LAYA runs the same way
(`entry/src/main/resources/rawfile/*.ms`, git-ignored — provision separately).

## Prerequisites

- DevEco Studio + HarmonyOS SDK (project builds against `6.1.1(24)`).
- A running emulator/device visible to `hdc`.
- `build-profile.json5` set to `runtimeOS: "HarmonyOS"`.
- `module.json5`: `CUSTOM_SCREEN_CAPTURE`, `SYSTEM_FLOAT_WINDOW`,
  `KEEP_BACKGROUND_RUNNING`; `EntryAbility` declares `backgroundModes: ["dataTransfer"]`.

```powershell
$DEVECO = "<DevEco Studio>"                 # e.g. C:\Program Files\Huawei\DevEco Studio
$PROJ   = "<repo>\HuaweiChallenge"
$HDC    = "$DEVECO\sdk\default\openharmony\toolchains\hdc.exe"
$TARGET = "127.0.0.1:5555"
```

## 1. Build

```powershell
Set-Location $PROJ; $env:DEVECO_SDK_HOME="$DEVECO\sdk"; `
& "$DEVECO\tools\node\node.exe" "$DEVECO\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --no-daemon
```

> Build with **JDK 17** on `PATH` (the package step shells out to `java`). Build from
> the project's canonical-cased path (hvigor rejects a path whose real case differs).

## 2. Install

```powershell
& $HDC -t $TARGET install -r "$PROJ\entry\build\default\outputs\default\entry-default-unsigned.hap"
```

## 3. Run

```powershell
& $HDC -t $TARGET shell aa start -a EntryAbility -b com.example.huwaweichallenge
```

On the app screen tap **Guard** (shows the floating pill). Open any app, tap the pill,
**Select area**, drag a box, **Scan this area**.

## 4. Live logs

```powershell
& $HDC -t $TARGET shell "hilog -T GuardianIslandWin,GuardianScanner,GuardianOcr,GuardianSelector,GuardianTrigger -v color"
```

Expected on a scan:

```
GuardianIslandWin: island shown at x=... y=...
GuardianSelector: selector shown 1320x2856
GuardianScanner: cropped to <x>,<y> <w>x<h>
GuardianOcr: models loaded … / detect N boxes / recognized N lines
GuardianScanner: scan text=<n> error=
```

## Files this feature touches

Core: `entry/src/main/ets/alert/IslandOverlay.ets`, `alert/SelectorOverlay.ets`,
`pages/FloatingIsland.ets`, `pages/SelectArea.ets`, `pages/IncidentDetail.ets`,
`components/SmartIsland.ets`, `components/IncidentDetailView.ets`,
`vision/ScreenScanner.ets`, `vision/LayaClassifier.ets`, `alert/IncidentKb.ets`,
`alert/NotificationService.ets`, `alert/AlertTheme.ets`, `entryability/EntryAbility.ets`,
`pages/Index.ets`, `module.json5`, `resources/base/profile/main_pages.json`.

## Limitations

- **Emulator CPU-only** (no NPU); LAYA inference is slow — the app has a dev "Dev mode"
  switch that routes OCR/LAY A to a host server (`C:\guardian-devserver`) for fast
  iteration. **Dev-only**; the shipping build is on-device/offline.
- A third-party app **cannot capture silently**: `screenshot.capture()` shows the system
  capture indicator. The user triggers each scan.
- The camera-cutout band **is not touch-sensitive** to our window; controls live below
  it.
- Classification depends on the bundled LAYA model; misinformation is weaker than scam.
