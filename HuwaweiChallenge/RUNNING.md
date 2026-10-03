# Guardian — running & testing

Guardian is a **Smart Island**. Collapsed it is a small pill; tap it to expand, then
press **Screenshot** to capture the screen and check it for scams. The verdict appears
in the island: green "Looks safe" (then it collapses by itself) or a red/orange warning
with the text. The small **x** turns the island off.

## Island behaviour

The island runs **only as a floating window** — there is no in-app island. The control
screen has one button: **Show floating island** / **Hide floating island**.

- **Collapsed** — small, always-neutral dark pill (`Guardian`); tap it to expand.
- **Expanded** — `Screenshot` and `Close` buttons, plus the small `x` in the corner.
- **Safe** — turns **green** and shows "Looks safe"; it stays until you press `Close`.
- **Scam** — turns **red/orange** and shows the warning text; it stays until you press `Close`.
- **Close** — collapses the island back to the plain neutral pill (status colour cleared).
- **x** — turns the island off (destroys the floating window and its background task).

The island never closes on its own: the only ways out are `Close` (back to the neutral
pill) and `x` (off).

## How the scan works

Tap **Screenshot** → request `ohos.permission.CUSTOM_SCREEN_CAPTURE` (first time) →
`screenshot.capture()` (whole display) → on-device OCR (`@kit.CoreVisionKit`) →
split into lines → classify **by text length** → keep the most severe → show it.
The captured `PixelMap` is released right after OCR; the image is never kept.

The island runs as a **floating window** (`TYPE_FLOAT`, `pages/FloatingIsland`) on top of
other apps. The window resizes between a small pill and the expanded card so it blocks as
little of the screen as possible, and starts a `dataTransfer` continuous task while
visible so the process stays responsive.

Length thresholds (placeholder until the validation model):
`< 50` → SAFE, `50–99` → WARNING (`misinformation`), `>= 100` → CRITICAL (`scam`).

## On-device OCR — emulator limitation

**Core Vision Kit OCR is not available on emulators** — Huawei states it explicitly
("This capability is currently not supported on emulators"), and on the emulator
`textRecognition` is `undefined` (`GuardianOcr: ocr failed ... Cannot read property
init of undefined`). There is no other public OCR library in the SDK that runs on the
emulator (MindSpore Lite is available but needs a `.ms` model; the device-side models
target Arm/Kirin, and the emulator is x86_64).

**Demo behaviour without OCR:** when OCR returns no text, the scanner picks a **random**
built-in sample (a safe or a scam message) so both island states can be shown. The island
labels it `(sample: scam)` / `(sample: safe)`. On a real HarmonyOS phone OCR returns text
and this substitution never happens.

## Prerequisites

- DevEco Studio + HarmonyOS SDK (project builds against `6.1.1(24)`).
- A running emulator/device visible to `hdc`.
- `build-profile.json5` set to `runtimeOS: "HarmonyOS"`.
- `module.json5`: `CUSTOM_SCREEN_CAPTURE`, `SYSTEM_FLOAT_WINDOW`,
  `KEEP_BACKGROUND_RUNNING`; `EntryAbility` declares `backgroundModes: ["dataTransfer"]`.

```powershell
$DEVECO = "D:\Huawei\DevEco Studio"
$PROJ   = "D:\Hackathon\HackYeah\hackyeah2026\HuwaweiChallenge"
$HDC    = "$DEVECO\sdk\default\openharmony\toolchains\hdc.exe"
$TARGET = "127.0.0.1:5555"
```

## 1. Build

```powershell
Set-Location $PROJ; $env:DEVECO_SDK_HOME="$DEVECO\sdk"; & "$DEVECO\tools\node\node.exe" "$DEVECO\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --no-daemon
```

## 2. Install

```powershell
& $HDC -t $TARGET install -r "$PROJ\entry\build\default\outputs\default\entry-default-unsigned.hap"
```

## 3. Run

```powershell
& $HDC -t $TARGET shell aa start -a EntryAbility -b com.example.huwaweichallenge
```

On the app screen: tap the island, then **Screenshot**. Use **Show floating island** to
keep the island on top of other apps; open a message or a web page and use it to scan.

## 4. Live logs

```powershell
& $HDC -t $TARGET shell "hilog -T GuardianIsland,GuardianIslandWin,GuardianScanner,GuardianOcr,CONTINUOUS_TASK -v color"
```

Expected on tap:

```
GuardianIslandWin: island window shown        (floating island only)
GuardianScanner: scan text=<n> sample=<none|scam|safe>
GuardianOcr: ocr failed ...                   (emulator: Core Vision not available)
```

## Files this feature touches

New: `entry/src/main/ets/vision/ScreenScanner.ets`, `entry/src/main/ets/vision/OcrEngine.ets`,
`entry/src/main/ets/vision/ScreenClassifier.ets`, `entry/src/main/ets/components/SmartIsland.ets`,
`entry/src/main/ets/alert/IslandOverlay.ets`, `entry/src/main/ets/pages/FloatingIsland.ets`.
Changed: `entry/src/main/ets/pages/Index.ets`, `entry/src/main/ets/entryability/EntryAbility.ets`,
`entry/src/main/resources/base/profile/main_pages.json`, `entry/src/main/module.json5`.
Removed: `entry/src/main/ets/vision/VisionScanLoop.ets`.

## Limitations

- **OCR does not work on the emulator** (see above); the sample fallback is used instead.
- A third-party app **cannot capture silently**: `screenshot.capture()` shows the system
  capture indicator. That is expected — the user triggers each scan.
- The floating window captures the whole display, including its own text; the classifier
  keeps the most severe line.
- The floating window still occupies a small rectangle at the top and blocks touches
  there (a `TYPE_FLOAT` behaviour).
- **Classification is length-based (a placeholder)** until the validation model is added
  in `ScreenClassifier.classifyOne()`.
