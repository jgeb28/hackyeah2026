# AI Workflow - minerbomb16

---
## Update: 2026-10-04 01:16:25
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** LAYA on-device via MindSpore Lite; switched the shipped artefact from **fp32 s512** to **`laya_en_w8_s256.ms`** (weight-only int8, 412 MB, sequence 256).
* **Inference Flow:** unchanged (island screenshot → PP-OCRv4 → text → Laya in worker → `ScanResult` → `IncidentKb` → island card).
* **Data Handling & Privacy:** offline; model materialised from rawfile into `filesDir` on first scan.
* **Limitations & Validation:** measured on the 6 GB emulator: **`infer ok: tokens=82 latency=40 073 ms`** vs **fp32 s512 = 151 463 ms** → **3.8× faster**, HAP 1574 → 424 MB, guest RAM 4.5/5.9 GB (no swap). **Caveat:** the verdict moved **CRITICAL → DANGEROUS** (w8/s256 gives an orange WARNING card vs the fp32 red one), so the model must be validated (their `tools/laya/{test_equiv,validate_ms}.py`) before it becomes the trusted default.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** pick the fastest LAYA artefact that actually runs on the x86 emulator.
* **Implementation:** found 10 variants in `D:\models` (`en|ml` × `fp32|w8|dyn8` × `s256|s512`); tried **`laya_en_dyn8_s512`** first → it **SIGSEGVs** in `libmindspore-lite.so → DynamicGatherInt8CPUKernel::DoGather` (x86 MSP int8 kernel bug); switched to **`laya_en_w8_s256`**, set `InferenceConfig.msModelPath/msFileName`, `quantization.dtype='w8'`, and `laya_guardian_meta.json` `max_len` 512 → 256 (graph input `[3,256]`).
* **Key Prompts:** "Checkout D:/Models… Let's test with the fastest one"; "a czemu nie przetestujemy w8_s256 skoro oceniasz go jako najlepszy?"; "We need this state on main. Make a pr".
* **Testing & Debugging:** emulator RAM 6144 (8192 crashed the guest via host OOM → `Kernel panic - sysrq triggered crash`); verified via `hilog` (`GuardianOcr`, `AssetLoader`, `LayaWorker`) and `cppcrash` fault logs; screenshots of the island card.

#### 4. Review & Validation
* **Human Oversight:** developer chose to ship this state via a PR to `main`.
* **Security Checks:** no secrets; model `.ms` git-ignored; no network path.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** `laya_en_dyn8_s512.ms` (dynamic int8) crashes inside MindSpore Lite's x86 int8 gather kernel — unusable. 8192 MB emulator RAM is too much for this 15.6 GB host (host OOM → guest kernel panic).
* **Lessons Learned:** (1) weight-only int8 (`w8`) runs where dynamic int8 (`dyn8`) crashes; (2) the real win came from **fitting in RAM** (no swap) plus the shorter sequence; (3) **quantisation + a shorter window changed the verdict** — always diff the decisions against fp32.

---
## Update: 2026-10-04 00:07:51
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** two on-device models chained — **PP-OCRv4** (MindSpore Lite, det+rec) for text, then **LAYA** (MindSpore Lite, in an ArkTS Worker) for the decision. Fully offline.
* **Inference Flow:** island `Screenshot` → `screenshot.capture()` → PP-OCRv4 → text → Laya (`risk`/`category`/`urgency`) → `ScanResult` (`SAFE/DANGEROUS/CRITICAL` + category + severity) → `IncidentKb` lookup in `rawfile/kb/en/incidents.json` → island card (title/explanation/remediation from the matching incident).
* **Data Handling & Privacy:** on-device only; the captured frame is released right after OCR; no network path.
* **Limitations & Validation:** ✅ **first full end-to-end run** on the emulator: capture worked on `Pura 90 max` (API 24), OCR `detect 13 boxes in 1072 ms` + `recognized 13 lines in 7134 ms`, Laya `infer ok: tokens=82 latency=151463`, `GuardianScanner scan text=250 error=` (no error). Island showed `Possible family-emergency…` (KB) in CRITICAL red.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** the user described the target flow (screenshot → OCR → text → Laya → decision, per DESIGN §6/§7.2/§8/§9 + `incidents.json`).
* **Implementation:** (1) merged `origin/main` into `add_jev` (2 conflicts: workflow file unioned to 14 entries; `Index.ets` = main's island screen + an `Open Laya demo` button while keeping the Laya page as `pages/LayaDemo.ets`). (2) Added `alert/IncidentKb.ets` (reads the 10 KB incidents, picks the most severe for a category) and `vision/LayaClassifier.ets` (Laya → `ScanResult`); `vision/ScreenScanner` now classifies via Laya instead of the length placeholder; `SmartIsland` renders the KB title + explanation + remediation; `EntryAbility` loads the KB.
* **Key Prompts:** "okej 1. to co jest na branchu add_jev push to remote 2. do the rebase 3. how it should work… screenshot is taken, then ocr reads… then that txt goes to laya" ; "może być (a)"; "dawaj".
* **Testing & Debugging:** rebuilt (`BUILD SUCCESSFUL`), uninstalled the old app (the 1.57 GB HAP failed to install twice with `insufficient disk memory` until the stale sandbox copy was removed), installed, granted the capture permission, and ran the scan; verified via logs and screenshots.

#### 4. Review & Validation
* **Human Oversight:** developer approved the merge approach and asked for the integration.
* **Security Checks:** no network permission; models are `.ms` in rawfile / git-ignored; no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** a plain `git rebase` of `add_jev` onto main was aborted — the two branches had added the same Laya files in parallel, producing add/add conflicts; a merge resolved them once.
* **Lessons Learned:** (1) the floating island **captures its own window**, so its UI text is OCR'd and can skew the verdict — it should hide during capture; (2) KB matching by `category` alone is coarse (it picked the generic `family-emergency` incident); (3) on a 6 GB emulator Laya takes ~151 s per inference.

---
## Update: 2026-10-03 23:45:55
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** **LAYA fp32 on-device** via MindSpore Lite, running in an ArkTS **Worker** (`LayaWorker` + `LayaEngineClient`), fully offline (no INTERNET permission).
* **Inference Flow:** bundled rawfile Ôćĺ `AssetLoader` materialises it to `filesDir` (offset-aware) Ôćĺ worker `loadModelFromFile` Ôćĺ `BpeTokenizer` Ôćĺ `input_ids`/`attention_mask` `[3,512]` Ôćĺ `predict` Ôćĺ `[1,3,5]` logits Ôćĺ verdict in `AnswerPopup`.
* **Data Handling & Privacy:** text and model stay on device; frame/text never leaves it.
* **Limitations & Validation:** Ôťů **first successful end-to-end run** on the emulator. Verdict: **CRITICAL**, category **scam 93%**, risk 23%, urgency 1.60. `LayaWorker: infer ok: tokens=48 **latency=183135 ms**` (~3 min). Memory saturated (5893/5941 MB, 47 MB free) Ôćĺ the latency is swap-bound, not a code issue.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** get Laya running end-to-end on a local emulator and measure whether the earlier failure was code or memory.
* **Implementation:** raised the emulator RAM 4096Ôćĺ**6144**; hit `ErrorCode: 00801002` (host C: needed 21.6 GB, had 21.0 GB) and moved the emulator instance store to D: with a junction ÔÇö then moved a **single** instance (`Pura 90 max`, 6 GB RAM, **12 GB data**) back to C: and rewrote `lists.json`/`config.ini`; verified `free -m` (5941 MB) and `/data` (6.8 GB free); ran the app and monitored memory every 15 s.
* **Key Prompts:** "zmien emulator na 6gb ramu"; "pu┼Ťci┼éem tests, monitoruj pamiec"; "przesz┼éo!"
* **Testing & Debugging:** memory climbed from ~1.8 GB baseline to **~5.9 GB used / 42ÔÇô81 MB free**; logs showed `model loaded (prefixes=3 maxLen=512)` in 12 s then, after ~3 min, `infer ok: ÔÇŽ latency=183135`; screenshot confirms the popup (CRITICAL / scam 93% / 183135 ms).

#### 4. Review & Validation
* **Human Oversight:** developer ran the test and confirmed the result ("przesz┼éo!").
* **Security Checks:** no secrets; model artefact git-ignored; no network path.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** 4 GB emulator Ôćĺ `predict` never returned and the system issued `LowMemoryKill`; the earlier main-thread `loadModelFromFd` gave `getInputs() === undefined` (whole-HAP fd, offset ignored).
* **Lessons Learned:** (1) the rawfile **offset/length** must be honoured when materialising a bundled `.ms`; (2) the ArkTS **Worker** is required so the 1.7 GB load does not trip `THREAD_BLOCK_6S`; (3) **memory is the real limit**: 6 GB completes the inference but takes ~183 s due to swap ÔÇö the next win is 8 GB RAM or a quantised (int8/q4) artefact.


---
## Update: 2026-10-03 23:14:08
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** LAYA fp32 on-device via MindSpore Lite, now running in an ArkTS **Worker** (teammate branch `add_jev` after pulling `feat/laya-ondevice`).
* **Inference Flow:** bundled rawfile (`offset=106894`, magic `MSL2`) Ôćĺ `AssetLoader` materialises it to `filesDir` (offset-aware) Ôćĺ `LayaWorker.loadModelFromFile` Ôćĺ `predict` in the worker; UI thread only decodes logits.
* **Data Handling & Privacy:** fully offline, no INTERNET permission; text stays on device.
* **Limitations & Validation:** on the **4 GB** Huawei emulator the worker **loaded the model in ~5 s** (`model loaded (prefixes=3 maxLen=512)`) but `predict` never returned ÔÇö the system logged `LowMemoryKill` and killed the session. fp32 (~1.69 GB) does not fit a 4 GB guest.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** decide whether the earlier `model.getInputs() === undefined` was a code bug or a memory problem, and test Laya end-to-end on the existing emulator without changing the machine.
* **Implementation:** probed the rawfile-fd hypothesis (logged `getRawFdSync` `offset`/`length`); cleaned the branch and fast-forward pulled `origin/add_jev` (`8cd7f8c Ôćĺ 162c40a`) which already contains the fix (offset-aware rawfileÔćĺfilesDir copy + worker); built and installed the 1.57 GB HAP (model bundled in `rawfile` for the first install) and monitored `free -m`.
* **Key Prompts:** "doko┼äcz"; "spr├│buj narazie bez zmiany maszyny"; "what is the verdict? is it a problem with swap?"
* **Testing & Debugging:** `t+100 s` Mem **3852/3931 MB used (78 MB free)** Ôćĺ thrashing; `t+200/300 s` fell back to ~1.3 GB used. Logs: `AssetLoader: copied 1686318032 bytes`, `LayaWorker: model loaded (prefixes=3 maxLen=512)`, `Engine ready (fp32)`, then `SCBMain ... LowMemoryKill` ├Ś3 and **no** inference result.

#### 4. Review & Validation
* **Human Oversight:** developer asked to try on the current machine without changing it.
* **Security Checks:** offline; no new permissions; model artefact git-ignored.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the old main-thread `loadModelFromFd` path yielded `getInputs() === undefined` (invalid model); superseded by the upstream worker + offset-aware copy.
* **Lessons Learned:** (1) `getRawFdSync` returns the whole HAP ÔÇö the rawfile `offset`/`length` must be honoured; (2) a correct worker fix still cannot beat physics: a 1.7 GB fp32 model + 4 GB guest = `LowMemoryKill`. Check `free -m`/VmSwap before blaming the model; use Ôëą6 GB RAM or a smaller quantised artefact.


---
## Update: 2026-10-03 21:02:22
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** on-device OCR via HarmonyOS Core Vision Kit (`@kit.CoreVisionKit`) behind the `OcrEngine` seam.
* **Inference Flow:** expand the floating island Ôćĺ `Screenshot` Ôćĺ `CUSTOM_SCREEN_CAPTURE` Ôćĺ `screenshot.capture()` Ôćĺ RGBA frame Ôćĺ OCR Ôćĺ lines Ôćĺ `ScreenClassifier.strongest` Ôćĺ verdict shown in the island (green "Looks safe" / red "Possible scam").
* **Data Handling & Privacy:** frame released right after OCR; only text kept, in memory. Capture is user-initiated.
* **Limitations & Validation:** emulator OCR unavailable (Huawei: not supported on emulators), so a **random** built-in sample is used, labelled `(sample: scam|safe)`. Validated on the emulator: neutral pill Ôćĺ expand Ôćĺ Screenshot Ôćĺ random safe/scam card Ôćĺ Close Ôćĺ neutral pill; confirmed multiple different samples across scans.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** user-requested polish: keep only the floating island (remove the in-app one); make the demo messages random; stop the island from closing by itself; and make `Close` return it to the plain look.
* **Implementation:** removed the in-app island and the safe auto-collapse/timer; `Close` now resets phase/colour/text to neutral and collapses to the plain pill; added a scan token so a result is dropped if the user closed the island mid-scan; `ScreenScanner` now picks a random safe/scam sample from several messages; `Index` is now just the show/hide floating-island control.
* **Key Prompts:**
  * *Prompt 1:* "Jest dobrze, ale wprowad┼║ drobne poprawki, zostaw przycisk z hideÔÇŽ przycisk show robi go w [oknie] aplikacji, co nie jest nam potrzebne, zr├│b by komunikaty by┼éy losowe, teraz s─ů 2 na krzy┼╝, dodatkowo czasem same si─Ö zamykaj─ů, trzeba to poprawi─ç. Dodaj te┼╝, ┼╝e po zminimalizowaniu przez close okienko wraca do standardowego wygl─ůdu bez kolor├│w statusu."
* **Testing & Debugging:** build (`assembleHap` OK), install via `hdc`, drove the emulator with `uitest uiInput` and verified each state with screenshots (neutral pill, random safe card, scam card, Close Ôćĺ neutral pill).

#### 4. Review & Validation
* **Human Oversight:** each requested change was checked against an emulator screenshot.
* **Security Checks:** no secrets added; frame released right after OCR.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the earlier safe auto-collapse was removed ÔÇö it read as the island "closing by itself".
* **Lessons Learned:** keep overlay state transitions strictly user-driven; a random demo sample set and a status-colour reset on `Close` make the states easy to read.


---
## Update: 2026-10-03 20:54:24
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** on-device OCR via HarmonyOS Core Vision Kit (`@kit.CoreVisionKit`) behind the `OcrEngine` seam; no other model feasible.
* **Inference Flow:** tap island Ôćĺ expand Ôćĺ `Screenshot` Ôćĺ `CUSTOM_SCREEN_CAPTURE` Ôćĺ `screenshot.capture()` Ôćĺ RGBA frame Ôćĺ `textRecognition.recognizeText` Ôćĺ lines Ôćĺ `ScreenClassifier.strongest` Ôćĺ verdict shown in the island (green = safe + auto-collapse, red/orange = warning + Close).
* **Data Handling & Privacy:** frame released immediately after OCR; only text is used, in memory. Capture is user-initiated (one-off system indicator expected). If OCR returns nothing, a labelled built-in sample is used (`(sample: scam)` / `(sample: safe)`, alternating) so both island states can be demoed.
* **Limitations & Validation:** Huawei states Core Vision OCR is **not supported on emulators**; on the emulator `textRecognition` is `undefined`. Validated manually: pill Ôćĺ expand Ôćĺ Screenshot Ôćĺ scam card; Close Ôćĺ red pill; Screenshot again Ôćĺ green "Looks safe" + auto-collapse; x hides/destroys the island.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none; web research for OCR options.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** researched OCR options that could work without a real phone. Findings: `@hms.ai.ocr.textRecognition` (HMS, needs HMS Core) and `@ohos.ai.mindSporeLite` + `@kit.MindSporeLiteKit` (no ready `.ms` OCR model; converter is Linux-only; device-side `.ms` targets Arm/Kirin while the emulator is x86_64). Huawei docs: OCR "currently not supported on emulators". Therefore no on-device OCR on the emulator; added an alternating labelled sample fallback.
* **Implementation:** reworked the island UX: small pill that expands; `Screenshot` + `Close` buttons; green/safe state with auto-collapse; red/scam state with a Close button; a small `x` that turns the island off (in-app hides it; floating destroys the window + stops the continuous task). Added `ScreenClassifier` SAFE verdict, `IslandOverlay.resize()` (window grows/shrinks with the island), and `onResize`/`onClose` callbacks from `SmartIsland`.
* **Key Prompts:**
  * *Prompt 1:* "Sprawd┼║, czy nie ma innych bibliotek do przegl─ůdania obrazk├│w i wyci─ůgania tekst├│w, mo┼╝e uda si─Ö to zrobi─ç bez rzeczywistego telefonu. Nie dzia┼éa to jak powinno teraz, nie da si─Ö wy┼é─ůczy─ç tej wyspy, ona powinna te┼╝ by─ç niedu┼╝a i si─Ö rozwija─ç po klikni─Öciu, tam powinna by─ç opcja screena i zamkni─Öcia, je┼Ťli b─Ödzie okej to si─Ö za┼Ťwieci na zielono i zwinie, jak b─Ödzie scam, to da komunikat i przycisk do zwini─Öcia."
* **Testing & Debugging:** built with hvigor, installed via `hdc install`, drove the emulator with `uitest uiInput`, verified each state with screenshots. Learned that `KeyCode.KEYCODE_HOME = 1` (not 3) in this SDK for backgrounding during floating-island tests.

#### 4. Review & Validation
* **Human Oversight:** developer's requested behaviours were each verified on the emulator with screenshots.
* **Security Checks:** no secrets added; frame released right after OCR.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** attempting to get real OCR without a phone ÔÇö no public emulator-capable OCR library, and MindSpore Lite needs a model + Arm target. The floating `TYPE_FLOAT` window blocks touches in its rectangle (mitigated by resizing it with the island).
* **Lessons Learned:** Huawei explicitly excludes emulators from Core Vision OCR, so plan a device or a labelled mock for demos; a user-triggered capture sidesteps the silent-capture approval problem, and a small resizable pill keeps overlay touch-blocking to a minimum.


---
## Update: 2026-10-03 20:35:01
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** on-device OCR via HarmonyOS Core Vision Kit (`@kit.CoreVisionKit` / `textRecognition`) behind the `OcrEngine` seam; no remote model yet.
* **Inference Flow:** user taps the Smart Island Ôćĺ `CUSTOM_SCREEN_CAPTURE` permission Ôćĺ `screenshot.capture()` (whole display) Ôćĺ RGBA frame Ôćĺ `textRecognition.recognizeText` Ôćĺ split into lines Ôćĺ `ScreenClassifier.strongest` (length-based placeholder) Ôćĺ verdict shown in the island, colored by severity.
* **Data Handling & Privacy:** the `PixelMap` is released immediately after OCR; no image is stored. Only the recognized text is used, in memory. Capture is user-initiated (one-off system indicator expected). If OCR returns no text, a built-in sample message is used and marked `(sample)`.
* **Limitations & Validation:** emulator OCR is unavailable (`Cannot read property init of undefined`), so the fallback sample is shown; classification is length-based placeholdered pending the validation model. Validated by tapping the island in-app and as a floating window over the launcher and observing the expansions.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** user pivoted the trigger from an automatic background scan to a user-triggered **Smart Island**: tap Ôćĺ screenshot Ôćĺ scam analysis Ôćĺ verdict in the island. Implemented as an in-app island plus a `TYPE_FLOAT` floating island that works over other apps, kept alive by a `dataTransfer` continuous task.
* **Implementation:** added `vision/ScreenScanner.ets` (one-shot capture+OCR+classify), `components/SmartIsland.ets`, `alert/IslandOverlay.ets`, `pages/FloatingIsland.ets`; rewrote `pages/Index.ets`; removed `vision/VisionScanLoop.ets`; registered `pages/FloatingIsland` in `main_pages.json`.
* **Key Prompts:**
  * *Prompt 1:* "To zmiana plan├│w, zr├│b jako smart island. U┼╝ytkownika ma mie─ç mo┼╝liwo┼Ť─ç skorzystania z tego i on wywo┼éa screenshot, kt├│ry jest analizowany pod k─ůtem scam├│w."
* **Testing & Debugging:** built with hvigor (`assembleHap`), installed via `hdc install`, drove the emulator with `uitest uiInput`. Verified: in-app island expands to "Possible scam" after tap; floating island shown over the launcher; tapping it scans and expands. Bug fixed: `KeyCode.KEYCODE_HOME = 1` (not 3) in this SDK, needed to background the app during the floating-island test.

#### 4. Review & Validation
* **Human Oversight:** developer drove the emulator taps/screenshots; agent reported each result.
* **Security Checks:** no secrets added; image frame released right after OCR.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** automatic background screen scanning was dropped ÔÇö silent cross-app capture needs a Huawei-approved system permission/profile, and emulator OCR is missing.
* **Lessons Learned:** a user-triggered capture sidesteps the silent-capture/platform approval problem entirely; a `TYPE_FLOAT` window can host an interactive island but blocks touches in its rectangle.


---
## Update: 2026-10-03 20:15:52
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Determine what is achievable if the user connects a real phone (can the agent build/install with invisible capture?).
* **Findings / constraints:**
  * The silent capture API (`screenshot.save`) is a `@systemapi` **not exported by the public ArkTS SDK**, so our build cannot call it regardless of granted permissions; a system/privileged SDK build would be required.
  * Installing on a retail HarmonyOS phone requires a Huawei-issued signing profile (Huawei account + device UDID). A self-signed OpenHarmony debug profile with ACL is not trusted by a retail Huawei device; the ACL/restricted permissions must be **approved/issued by Huawei** (AGC).
  * The agent has no access to the user's Huawei account/AGC, no system SDK, and cannot grant restricted permissions itself.
* **Key Prompts:** *Prompt:* "Czy gdybym podpi─ů┼é telefon m├│g┼éby┼Ť poustawia─ç te wszystkie rzeczy i zbudowa─ç w taki spos├│b, by te zrzuty nie by┼éy widoczne, czy nie masz dost─Öpu do takich rzeczy?"
* **Testing & Debugging:** n/a (analysis).

#### 4. Review & Validation
* **Human Oversight:** n/a.
* **Security Checks:** the agent will not handle user credentials.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** none.
* **Lessons Learned:** a connected phone would fix the **OCR** blocker (HMS Core present) but **not** the silent-capture blocker, which needs Huawei-issued permissions and a privileged/system build.


---
## Update: 2026-10-03 20:13:30
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none; web research only.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Can a real HarmonyOS phone be made to grant silent (invisible) screen capture?
* **Findings (cited):**
  * `ohos.permission.CAPTURE_SCREEN` is **system_core** and the silent API `screenshot.save` is a **system API**; the public `screenshot.capture()` (`CUSTOM_SCREEN_CAPTURE`) always shows the indicator.
  * OpenHarmony/Huawei `declare-permissions-in-acl`: a normal app can be granted `CAPTURE_SCREEN` (system_core) / `SYSTEM_FLOAT_WINDOW` (system_basic) **via the ACL in a debug signing profile**, but those methods **cannot ship to the app market**; commercial builds must request a release profile in AGC.
  * `AVScreenCapture` always shows a picker/privacy dialog for user approval.
  * No developer option exists to disable the capture indicator; `PRIVACY_WINDOW` only blocks capture of one's own window.
* **Key Prompts:** *Prompt:* "Czy gdybym mia┼é telefon z tym system m├│g┼ébym zasymulowa─ç t─ů zgod─Ö na robienie niewidocznych zrzut├│w ekranu?"

#### 4. Review & Validation
* **Human Oversight:** n/a (research).
* **Security Checks:** none.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** none attempted on-device.
* **Lessons Learned:** silent screen capture is a system-level grant (debug ACL or Huawei-approved release profile), not a user consent toggle; and the silent API is outside the public ArkTS SDK.


---
## Update: 2026-10-03 20:02:49
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none; built-in tools + `hdc` + SDK inspection + web research.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Determine if the system permissions can be granted locally for testing, and why the browser is not read.
* **Implementation / findings:**
  * OCR root cause: `GuardianOcr: ocr failed code= msg=Cannot read property init of undefined` ÔÇö the `textRecognition` module (`@kit.CoreVisionKit`) is `undefined` on this emulator (no HMS Core Vision service), so neither our app nor the browser can be read; the alert falls back to the sample text.
  * Local ACL: the OpenHarmony signing tools are present (`hap-sign-tool.jar`, `OpenHarmony.p12`, `OpenHarmonyProfileDebug.pem`, `UnsgnedDebugProfileTemplate.json`), so a debug profile with `acls.allowed-acls` (e.g. `CAPTURE_SCREEN`, `SYSTEM_FLOAT_WINDOW`) and a signed HAP can be produced locally. However the *silent* capture API (`screenshot.save`) is a system API not exported by the public ArkTS SDK, so this does not remove the visible capture indicator.
* **Key Prompts:** *Prompt:* "Czy nie da si─Ö ustawi─ç tych uprawnie┼ä w ┼Ťrodowisku testowymÔÇŽ? Dodatkowo screeny pokazuj─ů komunikaty, ale tylko w naszej aplikacjiÔÇŽ na przegl─ůdarce nie robi─ů zrzut├│w."
* **Testing & Debugging:** `assembleHap` Ôćĺ BUILD SUCCESSFUL; OCR error code/message surfaced by improving `OcrEngine` logging; popups verified in both silent and whole-screen modes (`scan #N` Ôćĺ `overlay shown` Ôćĺ `notification published`).

#### 4. Review & Validation
* **Human Oversight:** hilog inspected; OCR failure isolated to a missing runtime module.
* **Security Checks:** image released after OCR; no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** expecting whole-screen mode to read the browser on the emulator.
* **Lessons Learned:** reading other apps needs (a) a HarmonyOS device with the OCR service and (b) ÔÇö for silence ÔÇö a Huawei-approved system-level profile; the emulator lacks HMS OCR entirely.


---
## Update: 2026-10-03 19:56:35
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none; built-in tools + `hdc` + web research.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Investigate whether an approved (Huawei-signed) app could capture the screen silently/backgrounded outside the app, and fix missing popups in whole-screen mode.
* **Implementation:** `vision/VisionScanLoop.ets` now always falls back to the on-screen text when OCR is unavailable **or the capture failed**, so the overlay/notification shows in both silent and whole-screen modes (previously the fallback was skipped in whole-screen mode Ôćĺ empty text Ôćĺ no popup).
* **Research (cited):**
  * `ohos.permission.CAPTURE_SCREEN` is "available only to system applications"; `screenshot.save` (system API) needs it.
  * Huawei's `declare-permissions-in-acl` doc: a **normal app can be granted `CAPTURE_SCREEN` (system_core) and `SYSTEM_FLOAT_WINDOW` (system_basic) via the ACL** in the signing profile (debug phase); commercial builds apply for a release certificate/profile in the app market.
  * `AccessibilityExtensionAbility` is third-party-implementable, but enabling/listing is gated by Huawei verification.
  * => With Huawei's approval, silent background capture of other apps is possible; without it the public `screenshot.capture()` always shows the capture indicator.
* **Testing & Debugging:** `assembleHap` Ôćĺ BUILD SUCCESSFUL; verified `scan #N text=14 chars` Ôćĺ `GuardianOverlay: overlay shown` Ôćĺ `GuardianNotify ÔÇŽ via=vision` in whole-screen mode.

#### 4. Review & Validation
* **Human Oversight:** hilog + layout verified.
* **Security Checks:** image frames released after OCR; no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** relying on OCR-only text in whole-screen mode on the emulator produced no alerts.
* **Lessons Learned:** silent + other-apps needs a Huawei-approved system-level profile (ACL/release); a public build must show the capture indicator.


---
## Update: 2026-10-03 19:51:12
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none enabled; built-in file/edit/shell tools + `hdc` + SDK `.d.ts` inspection.
* **Configuration:** repo `AGENTS.md`; bundled hvigor (`DEVECO_SDK_HOME`); HarmonyOS 6.1.1 (API 24) emulator.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Move the trigger from host-app reports to reading the screen: periodic screenshot Ôćĺ on-device OCR Ôćĺ classify Ôćĺ keep the most severe Ôćĺ dedupe Ôćĺ show the existing overlay.
* **Implementation:**
  * `vision/VisionScanLoop.ets` ÔÇö 5 s loop; silent mode uses `window.snapshot()` (own window, no permission/indicator), "whole screen" mode uses `screenshot.capture()` (reads other apps, shows the system indicator); releases the `PixelMap` right after OCR; 60 s dedupe.
  * `vision/OcrEngine.ets` ÔÇö Core Vision Kit `textRecognition` seam (RGBA_8888 conversion, releases intermediates).
  * `vision/ScreenClassifier.ets` ÔÇö length-based placeholder (<50 INFO, 50ÔÇô99 WARNING, Ôëą100 CRITICAL), picks the highest severity across messages.
  * `pages/Index.ets` ÔÇö Start/Stop, `Next text` sample messages, silent/whole-screen toggle, status.
  * `EntryAbility` + `module.json5` ÔÇö `backgroundModes: ["dataTransfer"]` + `startBackgroundRunning`, so the timer survives backgrounding (fixed `bgMode invalid` 9800005).
* **Key Prompts:**
  * *Prompt:* "ÔÇŽteraz aplikacja ma robi─ç co jaki┼Ť czas screeny i sprawdza─ç tekstÔÇŽ zawsze wybiera najwy┼╝szy stopie┼ä krytyczno┼ŤciÔÇŽ bezpiecznik, by nie wysy┼éa─ç non stop notyfikacjiÔÇŽ mo┼╝esz zrobi─ç, ┼╝e ocena jest losowaÔÇŽ" plus follow-ups to remove the capture flash, not keep the image, and later "ÔÇŽwidac robienie screenu, co jest z┼ée i nie wy┼Ťwietla popup├│w".
* **Testing & Debugging:** `assembleHap` Ôćĺ BUILD SUCCESSFUL; verified scan #1..#N every 5 s both foreground and after Home (`OnContinuousTaskStart`); overlay+notification fire (silent fallback = sample text). On the emulator Core Vision OCR is unavailable (`GuardianOcr: ocr failed`), so no text is read there.

#### 4. Review & Validation
* **Human Oversight:** Screenshots + hilog reviewed for each change; the reported bug (wrong text, no background) reproduced and fixed.
* **Security Checks:** No secrets; image frames released; silent capture requires no permission.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** `aa start` on an `appService` is blocked (10107101); a UIAbility `aa start` always foregrounds; `window.snapshot()` cannot see other apps.
* **Lessons Learned:** Reading other apps is never silent for a third-party HarmonyOS app (system indicator required; accessibility gated), so the app exposes a silent (own-window) mode and a whole-screen mode, and OCR needs a real device.


---
## Update: 2026-10-03 15:13:16
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none enabled; built-in file/edit/shell tools + `hdc` for screenshots and input.
* **Configuration:** repo `AGENTS.md` rules; bundled hvigor with `DEVECO_SDK_HOME=D:\Huawei\DevEco Studio\sdk`.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Localize the Dynamic Island to English, keep the collapsed note general, and allow the expanded text to be passed per invocation.
* **Implementation:**
  * `DynamicIslandAlert.ets`: English defaults (`shortText`/`title` = "Suspicious message", general `detail`), English comments, "Dismiss" button; `@Prop detail` documented as the call-site override for the expanded text.
  * `pages/Index.ets`: passes a custom `detail` in the constructor to demonstrate overriding the default expanded text.
* **Key Prompts:**
  * *Prompt:* "Zmie┼ä j─Özyk na angielski, niech informacja na poczatek b─Ödzie og├│lne o podejrzanej wiadomo┼Ťci, a potem b─Ödzie dok┼éadniejszy opis ... dodaj mo┼╝liwo┼Ť─ç w wywo┼éaniu podanie tekstu, kt├│ry si─Ö poka┼╝e po rozwini─Öciu zamiast defaultowego."
* **Testing & Debugging:** `assembleHap` Ôćĺ BUILD SUCCESSFUL; reinstalled and verified both states via screenshots (collapsed "Suspicious message" pill, expanded card with the call-site text).

#### 4. Review & Validation
* **Human Oversight:** Both English states captured from the emulator and visually confirmed.
* **Security Checks:** No permissions, no system logic; UI-only.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** None.
* **Lessons Learned:** Keeping all display strings as `@Prop` with sane English defaults makes the component reusable and lets each call site supply its own message.

---
## Update: 2026-10-03 15:03:46
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none enabled; built-in file/edit/shell tools plus `hdc` (`snapshot_display`, `uitest uiInput click`) for on-device verification.
* **Configuration:** repo `AGENTS.md` rules; bundled hvigor with `DEVECO_SDK_HOME=D:\Huawei\DevEco Studio\sdk`.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Asked whether the warning could be presented as an iPhone-style "Dynamic Island": a short note at the top that expands to detail on tap.
* **Implementation:**
  * Added `entry/src/main/ets/components/DynamicIslandAlert.ets`: dark pill (`rgba(28,28,30,.96)`) anchored top-centre, `@Prop shortText/title/detail` + `onDismiss`, `@State expanded`; `.animation({ curve: Curve.Friction })` animates width/radius/padding during expand/collapse; ÔťĽ and "Zamknij" dismiss.
  * Rewired `pages/Index.ets`: root `Stack({ alignContent: Alignment.Top })`; tapping the text sets `showIsland = true`; the island wrapper uses `.transition(TransitionEffect.move(TransitionEdge.TOP))` to slide in from the top.
  * The earlier `DangerousMessagePopup.ets` is left in place, intentionally unwired.
* **Key Prompts:**
  * *Prompt:* "A da si─Ö to zrobi─ç jako dynamic island jak na iphonie? Mo┼╝e si─Ö najpierw wy┼Ťwietla─ç kr├│tka notka, a po wejsciu b─Ödzie wi─Öcej informacji, to si─Ö tak z g├│ry bedzie wyswietla─ç."
* **Testing & Debugging:** `assembleHap` Ôćĺ BUILD SUCCESSFUL. First two taps missed because the island's inner `Row` only covered its content within the padding; fixed by attaching the toggle `onClick` to the island root. Verified by screenshots: collapsed pill, then expanded card after `uitest uiInput click 628 187`.

#### 4. Review & Validation
* **Human Oversight:** Both states captured from the running emulator and visually confirmed (collapsed pill Ôćĺ expanded detail card).
* **Security Checks:** No permissions, no system logic; UI-only.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** `onClick` on a padded inner child leaves dead zones in the padding; move the handler to the outer container.
* **Lessons Learned:** For an iPhone-like island, animate the container's width/borderRadius/padding with a single `.animation()` and drive the entrance with `TransitionEffect.move(TransitionEdge.TOP)` on the wrapper.

---
## Update: 2026-10-03 14:57:05
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none enabled; used built-in file/edit/shell tools plus `hdc` for on-device verification.
* **Configuration:** repo `AGENTS.md` rules; project built via bundled hvigor with `DEVECO_SDK_HOME=D:\Huawei\DevEco Studio\sdk`.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Requested a reusable "popup over apps" warning, not wired to any real logic yet, demonstrated by showing it on tap instead of the "Welcome" text.
* **Implementation:**
  * Added `entry/src/main/ets/components/DangerousMessagePopup.ets` ÔÇö a red (`#D32F2F`) modal card with `@Prop title` / `@Prop detail` and an `onDismiss` callback, rendered as a full-screen `Stack` overlay (dimmed backdrop) above page content. Header comment documents the future path to a real system overlay via `window.createWindow({ windowType: TYPE_FLOAT })` + `ohos.permission.SYSTEM_FLOAT_WINDOW`.
  * Rewired `pages/Index.ets`: root `Stack` with the popup rendered last (on top); tapping the text sets `showDangerousPopup = true` instead of changing the message to "Welcome".
* **Key Prompts:**
  * *Prompt:* "Dodaj opcj─Ö wyskakiwania popupu nad aplikacjami ... jak si─Ö kliknie na apce, to zamiast pokazywa─ç si─Ö welcome, to bedzie popup z napisem \"Niebezpieczna wiadomo┼Ť─ç\". Popup ma by─ç czerwony."
* **Testing & Debugging:** `hvigor assembleHap` Ôćĺ BUILD SUCCESSFUL; installed via `hdc install -r`; launched with `aa start`; tapped the screen centre via `uitest uiInput click`; captured a screenshot confirming the red popup.

#### 4. Review & Validation
* **Human Oversight:** On-device screenshot reviewed; popup visually confirmed (red card, title, detail, dismiss button).
* **Security Checks:** No permissions added and no system logic wired; popup is UI-only for now.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** None.
* **Lessons Learned:** Modeling the popup as a separate component with a dismiss callback keeps it reusable for a future floating-window / system-overlay implementation.

---
## Update: 2026-10-03 14:50:02
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none enabled for this task; used built-in shell/read/edit tools.
* **Configuration:** repo `AGENTS.md` (root + `HuwaweiChallenge/AGENTS.md`) rules; no custom MCP or skills.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Diagnosed (a) why DevEco Studio's Device Manager only offered a wearable emulator, and (b) why the app would not deploy to the phone emulator.
* **Implementation:**
  * Region gate (fix 1): DevEco stored country `PL` in `%APPDATA%\Huawei\DevEcoStudio6.1\options\country.region.xml`, cached in `%LOCALAPPDATA%\Huawei\DevEcoStudio6.1\caches\grs.json` (`countryCode: PL`, EU `-dre` endpoints). Phone/foldable/tablet images are served from the CN (`-drcn`) catalog. Set region to `CN`, deleted `grs.json`, restarted the IDE. Wrote a reusable `fix-deveco-emulator-region.ps1`.
  * Phone image: downloaded via emulator CLI ÔÇö `Emulator.exe -install -deviceType phone -osVersion "HarmonyOS 6.1.1(24)"` (the CLI waits for a TTY confirmation; piping `y` unblocks it). Created and started instance `Huawei_Phone` (API 24).
  * SDK/runtimeOS (fix 2): project was `"runtimeOS": "OpenHarmony"`, API 23, while the emulators are HarmonyOS (API 23/24); sources import `@kit.*` (HarmonyOS), which caused a SysCap deployment error. Fixed `build-profile.json5`: `compileSdkVersion "6.1.1(24)"`, `compatibleSdkVersion "6.1.0(23)"`, `targetSdkVersion "6.1.1(24)"`, `runtimeOS "HarmonyOS"`.
* **Key Prompts:**
  * *Prompt 1:* "W deveco studio chc─Ö uruchomi─ç emulator, jednak mam tylko opcj─Ö preview ... dost─Öp tylko do wearable ... jak mog─Ö zrobi─ç emulator, rozwi─ů┼╝ problem."
  * *Prompt 2:* "Wersja sdk mi si─Ö nie zgadza z oboma emulatorami jakie posiadam i nie mog─Ö uruchomi─ç, napraw to."
* **Testing & Debugging:** hvigor `assembleHap` Ôćĺ BUILD SUCCESSFUL; `hdc install` on API 24 (5555) and API 23 (5557) emulators; launch via `aa start`; device screenshot confirmed the "Hello World" UI.

#### 4. Review & Validation
* **Human Oversight:** Developer requested the fixes; results were verified by a full build plus on-device install, launch, and screenshot.
* **Security Checks:** The region change only edits local IDE config; `.bak` backups kept; no secrets, credentials, or PII involved.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** `Emulator.exe -install` silently no-ops without piped input (needs a TTY confirmation). Changing the Windows region/language alone does nothing ÔÇö the IDE's `country.region.xml` must be edited while DevEco Studio is fully closed.
* **Lessons Learned:** For local HarmonyOS emulators, the IDE region gates which device images are offered; and a project's `runtimeOS` must match the emulator OS (OpenHarmony vs HarmonyOS), otherwise the SysCap check blocks deployment.
