# AI Workflow - minerbomb16

---
## Update: 2026-10-03 21:02:22
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** on-device OCR via HarmonyOS Core Vision Kit (`@kit.CoreVisionKit`) behind the `OcrEngine` seam.
* **Inference Flow:** expand the floating island → `Screenshot` → `CUSTOM_SCREEN_CAPTURE` → `screenshot.capture()` → RGBA frame → OCR → lines → `ScreenClassifier.strongest` → verdict shown in the island (green "Looks safe" / red "Possible scam").
* **Data Handling & Privacy:** frame released right after OCR; only text kept, in memory. Capture is user-initiated.
* **Limitations & Validation:** emulator OCR unavailable (Huawei: not supported on emulators), so a **random** built-in sample is used, labelled `(sample: scam|safe)`. Validated on the emulator: neutral pill → expand → Screenshot → random safe/scam card → Close → neutral pill; confirmed multiple different samples across scans.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** user-requested polish: keep only the floating island (remove the in-app one); make the demo messages random; stop the island from closing by itself; and make `Close` return it to the plain look.
* **Implementation:** removed the in-app island and the safe auto-collapse/timer; `Close` now resets phase/colour/text to neutral and collapses to the plain pill; added a scan token so a result is dropped if the user closed the island mid-scan; `ScreenScanner` now picks a random safe/scam sample from several messages; `Index` is now just the show/hide floating-island control.
* **Key Prompts:**
  * *Prompt 1:* "Jest dobrze, ale wprowadź drobne poprawki, zostaw przycisk z hide… przycisk show robi go w [oknie] aplikacji, co nie jest nam potrzebne, zrób by komunikaty były losowe, teraz są 2 na krzyż, dodatkowo czasem same się zamykają, trzeba to poprawić. Dodaj też, że po zminimalizowaniu przez close okienko wraca do standardowego wyglądu bez kolorów statusu."
* **Testing & Debugging:** build (`assembleHap` OK), install via `hdc`, drove the emulator with `uitest uiInput` and verified each state with screenshots (neutral pill, random safe card, scam card, Close → neutral pill).

#### 4. Review & Validation
* **Human Oversight:** each requested change was checked against an emulator screenshot.
* **Security Checks:** no secrets added; frame released right after OCR.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the earlier safe auto-collapse was removed — it read as the island "closing by itself".
* **Lessons Learned:** keep overlay state transitions strictly user-driven; a random demo sample set and a status-colour reset on `Close` make the states easy to read.


---
## Update: 2026-10-03 20:54:24
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** on-device OCR via HarmonyOS Core Vision Kit (`@kit.CoreVisionKit`) behind the `OcrEngine` seam; no other model feasible.
* **Inference Flow:** tap island → expand → `Screenshot` → `CUSTOM_SCREEN_CAPTURE` → `screenshot.capture()` → RGBA frame → `textRecognition.recognizeText` → lines → `ScreenClassifier.strongest` → verdict shown in the island (green = safe + auto-collapse, red/orange = warning + Close).
* **Data Handling & Privacy:** frame released immediately after OCR; only text is used, in memory. Capture is user-initiated (one-off system indicator expected). If OCR returns nothing, a labelled built-in sample is used (`(sample: scam)` / `(sample: safe)`, alternating) so both island states can be demoed.
* **Limitations & Validation:** Huawei states Core Vision OCR is **not supported on emulators**; on the emulator `textRecognition` is `undefined`. Validated manually: pill → expand → Screenshot → scam card; Close → red pill; Screenshot again → green "Looks safe" + auto-collapse; x hides/destroys the island.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none; web research for OCR options.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** researched OCR options that could work without a real phone. Findings: `@hms.ai.ocr.textRecognition` (HMS, needs HMS Core) and `@ohos.ai.mindSporeLite` + `@kit.MindSporeLiteKit` (no ready `.ms` OCR model; converter is Linux-only; device-side `.ms` targets Arm/Kirin while the emulator is x86_64). Huawei docs: OCR "currently not supported on emulators". Therefore no on-device OCR on the emulator; added an alternating labelled sample fallback.
* **Implementation:** reworked the island UX: small pill that expands; `Screenshot` + `Close` buttons; green/safe state with auto-collapse; red/scam state with a Close button; a small `x` that turns the island off (in-app hides it; floating destroys the window + stops the continuous task). Added `ScreenClassifier` SAFE verdict, `IslandOverlay.resize()` (window grows/shrinks with the island), and `onResize`/`onClose` callbacks from `SmartIsland`.
* **Key Prompts:**
  * *Prompt 1:* "Sprawdź, czy nie ma innych bibliotek do przeglądania obrazków i wyciągania tekstów, może uda się to zrobić bez rzeczywistego telefonu. Nie działa to jak powinno teraz, nie da się wyłączyć tej wyspy, ona powinna też być nieduża i się rozwijać po kliknięciu, tam powinna być opcja screena i zamknięcia, jeśli będzie okej to się zaświeci na zielono i zwinie, jak będzie scam, to da komunikat i przycisk do zwinięcia."
* **Testing & Debugging:** built with hvigor, installed via `hdc install`, drove the emulator with `uitest uiInput`, verified each state with screenshots. Learned that `KeyCode.KEYCODE_HOME = 1` (not 3) in this SDK for backgrounding during floating-island tests.

#### 4. Review & Validation
* **Human Oversight:** developer's requested behaviours were each verified on the emulator with screenshots.
* **Security Checks:** no secrets added; frame released right after OCR.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** attempting to get real OCR without a phone — no public emulator-capable OCR library, and MindSpore Lite needs a model + Arm target. The floating `TYPE_FLOAT` window blocks touches in its rectangle (mitigated by resizing it with the island).
* **Lessons Learned:** Huawei explicitly excludes emulators from Core Vision OCR, so plan a device or a labelled mock for demos; a user-triggered capture sidesteps the silent-capture approval problem, and a small resizable pill keeps overlay touch-blocking to a minimum.


---
## Update: 2026-10-03 20:35:01
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** on-device OCR via HarmonyOS Core Vision Kit (`@kit.CoreVisionKit` / `textRecognition`) behind the `OcrEngine` seam; no remote model yet.
* **Inference Flow:** user taps the Smart Island → `CUSTOM_SCREEN_CAPTURE` permission → `screenshot.capture()` (whole display) → RGBA frame → `textRecognition.recognizeText` → split into lines → `ScreenClassifier.strongest` (length-based placeholder) → verdict shown in the island, colored by severity.
* **Data Handling & Privacy:** the `PixelMap` is released immediately after OCR; no image is stored. Only the recognized text is used, in memory. Capture is user-initiated (one-off system indicator expected). If OCR returns no text, a built-in sample message is used and marked `(sample)`.
* **Limitations & Validation:** emulator OCR is unavailable (`Cannot read property init of undefined`), so the fallback sample is shown; classification is length-based placeholdered pending the validation model. Validated by tapping the island in-app and as a floating window over the launcher and observing the expansions.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** user pivoted the trigger from an automatic background scan to a user-triggered **Smart Island**: tap → screenshot → scam analysis → verdict in the island. Implemented as an in-app island plus a `TYPE_FLOAT` floating island that works over other apps, kept alive by a `dataTransfer` continuous task.
* **Implementation:** added `vision/ScreenScanner.ets` (one-shot capture+OCR+classify), `components/SmartIsland.ets`, `alert/IslandOverlay.ets`, `pages/FloatingIsland.ets`; rewrote `pages/Index.ets`; removed `vision/VisionScanLoop.ets`; registered `pages/FloatingIsland` in `main_pages.json`.
* **Key Prompts:**
  * *Prompt 1:* "To zmiana planów, zrób jako smart island. Użytkownika ma mieć możliwość skorzystania z tego i on wywoła screenshot, który jest analizowany pod kątem scamów."
* **Testing & Debugging:** built with hvigor (`assembleHap`), installed via `hdc install`, drove the emulator with `uitest uiInput`. Verified: in-app island expands to "Possible scam" after tap; floating island shown over the launcher; tapping it scans and expands. Bug fixed: `KeyCode.KEYCODE_HOME = 1` (not 3) in this SDK, needed to background the app during the floating-island test.

#### 4. Review & Validation
* **Human Oversight:** developer drove the emulator taps/screenshots; agent reported each result.
* **Security Checks:** no secrets added; image frame released right after OCR.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** automatic background screen scanning was dropped — silent cross-app capture needs a Huawei-approved system permission/profile, and emulator OCR is missing.
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
* **Key Prompts:** *Prompt:* "Czy gdybym podpiął telefon mógłbyś poustawiać te wszystkie rzeczy i zbudować w taki sposób, by te zrzuty nie były widoczne, czy nie masz dostępu do takich rzeczy?"
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
* **Key Prompts:** *Prompt:* "Czy gdybym miał telefon z tym system mógłbym zasymulować tą zgodę na robienie niewidocznych zrzutów ekranu?"

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
  * OCR root cause: `GuardianOcr: ocr failed code= msg=Cannot read property init of undefined` — the `textRecognition` module (`@kit.CoreVisionKit`) is `undefined` on this emulator (no HMS Core Vision service), so neither our app nor the browser can be read; the alert falls back to the sample text.
  * Local ACL: the OpenHarmony signing tools are present (`hap-sign-tool.jar`, `OpenHarmony.p12`, `OpenHarmonyProfileDebug.pem`, `UnsgnedDebugProfileTemplate.json`), so a debug profile with `acls.allowed-acls` (e.g. `CAPTURE_SCREEN`, `SYSTEM_FLOAT_WINDOW`) and a signed HAP can be produced locally. However the *silent* capture API (`screenshot.save`) is a system API not exported by the public ArkTS SDK, so this does not remove the visible capture indicator.
* **Key Prompts:** *Prompt:* "Czy nie da się ustawić tych uprawnień w środowisku testowym…? Dodatkowo screeny pokazują komunikaty, ale tylko w naszej aplikacji… na przeglądarce nie robią zrzutów."
* **Testing & Debugging:** `assembleHap` → BUILD SUCCESSFUL; OCR error code/message surfaced by improving `OcrEngine` logging; popups verified in both silent and whole-screen modes (`scan #N` → `overlay shown` → `notification published`).

#### 4. Review & Validation
* **Human Oversight:** hilog inspected; OCR failure isolated to a missing runtime module.
* **Security Checks:** image released after OCR; no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** expecting whole-screen mode to read the browser on the emulator.
* **Lessons Learned:** reading other apps needs (a) a HarmonyOS device with the OCR service and (b) — for silence — a Huawei-approved system-level profile; the emulator lacks HMS OCR entirely.


---
## Update: 2026-10-03 19:56:35
**Developer:** minerbomb16

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none; built-in tools + `hdc` + web research.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Investigate whether an approved (Huawei-signed) app could capture the screen silently/backgrounded outside the app, and fix missing popups in whole-screen mode.
* **Implementation:** `vision/VisionScanLoop.ets` now always falls back to the on-screen text when OCR is unavailable **or the capture failed**, so the overlay/notification shows in both silent and whole-screen modes (previously the fallback was skipped in whole-screen mode → empty text → no popup).
* **Research (cited):**
  * `ohos.permission.CAPTURE_SCREEN` is "available only to system applications"; `screenshot.save` (system API) needs it.
  * Huawei's `declare-permissions-in-acl` doc: a **normal app can be granted `CAPTURE_SCREEN` (system_core) and `SYSTEM_FLOAT_WINDOW` (system_basic) via the ACL** in the signing profile (debug phase); commercial builds apply for a release certificate/profile in the app market.
  * `AccessibilityExtensionAbility` is third-party-implementable, but enabling/listing is gated by Huawei verification.
  * => With Huawei's approval, silent background capture of other apps is possible; without it the public `screenshot.capture()` always shows the capture indicator.
* **Testing & Debugging:** `assembleHap` → BUILD SUCCESSFUL; verified `scan #N text=14 chars` → `GuardianOverlay: overlay shown` → `GuardianNotify … via=vision` in whole-screen mode.

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
* **Ideation & Architecture:** Move the trigger from host-app reports to reading the screen: periodic screenshot → on-device OCR → classify → keep the most severe → dedupe → show the existing overlay.
* **Implementation:**
  * `vision/VisionScanLoop.ets` — 5 s loop; silent mode uses `window.snapshot()` (own window, no permission/indicator), "whole screen" mode uses `screenshot.capture()` (reads other apps, shows the system indicator); releases the `PixelMap` right after OCR; 60 s dedupe.
  * `vision/OcrEngine.ets` — Core Vision Kit `textRecognition` seam (RGBA_8888 conversion, releases intermediates).
  * `vision/ScreenClassifier.ets` — length-based placeholder (<50 INFO, 50–99 WARNING, ≥100 CRITICAL), picks the highest severity across messages.
  * `pages/Index.ets` — Start/Stop, `Next text` sample messages, silent/whole-screen toggle, status.
  * `EntryAbility` + `module.json5` — `backgroundModes: ["dataTransfer"]` + `startBackgroundRunning`, so the timer survives backgrounding (fixed `bgMode invalid` 9800005).
* **Key Prompts:**
  * *Prompt:* "…teraz aplikacja ma robić co jakiś czas screeny i sprawdzać tekst… zawsze wybiera najwyższy stopień krytyczności… bezpiecznik, by nie wysyłać non stop notyfikacji… możesz zrobić, że ocena jest losowa…" plus follow-ups to remove the capture flash, not keep the image, and later "…widac robienie screenu, co jest złe i nie wyświetla popupów".
* **Testing & Debugging:** `assembleHap` → BUILD SUCCESSFUL; verified scan #1..#N every 5 s both foreground and after Home (`OnContinuousTaskStart`); overlay+notification fire (silent fallback = sample text). On the emulator Core Vision OCR is unavailable (`GuardianOcr: ocr failed`), so no text is read there.

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
  * *Prompt:* "Zmień język na angielski, niech informacja na poczatek będzie ogólne o podejrzanej wiadomości, a potem będzie dokładniejszy opis ... dodaj możliwość w wywołaniu podanie tekstu, który się pokaże po rozwinięciu zamiast defaultowego."
* **Testing & Debugging:** `assembleHap` → BUILD SUCCESSFUL; reinstalled and verified both states via screenshots (collapsed "Suspicious message" pill, expanded card with the call-site text).

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
  * Added `entry/src/main/ets/components/DynamicIslandAlert.ets`: dark pill (`rgba(28,28,30,.96)`) anchored top-centre, `@Prop shortText/title/detail` + `onDismiss`, `@State expanded`; `.animation({ curve: Curve.Friction })` animates width/radius/padding during expand/collapse; ✕ and "Zamknij" dismiss.
  * Rewired `pages/Index.ets`: root `Stack({ alignContent: Alignment.Top })`; tapping the text sets `showIsland = true`; the island wrapper uses `.transition(TransitionEffect.move(TransitionEdge.TOP))` to slide in from the top.
  * The earlier `DangerousMessagePopup.ets` is left in place, intentionally unwired.
* **Key Prompts:**
  * *Prompt:* "A da się to zrobić jako dynamic island jak na iphonie? Może się najpierw wyświetlać krótka notka, a po wejsciu będzie więcej informacji, to się tak z góry bedzie wyswietlać."
* **Testing & Debugging:** `assembleHap` → BUILD SUCCESSFUL. First two taps missed because the island's inner `Row` only covered its content within the padding; fixed by attaching the toggle `onClick` to the island root. Verified by screenshots: collapsed pill, then expanded card after `uitest uiInput click 628 187`.

#### 4. Review & Validation
* **Human Oversight:** Both states captured from the running emulator and visually confirmed (collapsed pill → expanded detail card).
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
  * Added `entry/src/main/ets/components/DangerousMessagePopup.ets` — a red (`#D32F2F`) modal card with `@Prop title` / `@Prop detail` and an `onDismiss` callback, rendered as a full-screen `Stack` overlay (dimmed backdrop) above page content. Header comment documents the future path to a real system overlay via `window.createWindow({ windowType: TYPE_FLOAT })` + `ohos.permission.SYSTEM_FLOAT_WINDOW`.
  * Rewired `pages/Index.ets`: root `Stack` with the popup rendered last (on top); tapping the text sets `showDangerousPopup = true` instead of changing the message to "Welcome".
* **Key Prompts:**
  * *Prompt:* "Dodaj opcję wyskakiwania popupu nad aplikacjami ... jak się kliknie na apce, to zamiast pokazywać się welcome, to bedzie popup z napisem \"Niebezpieczna wiadomość\". Popup ma być czerwony."
* **Testing & Debugging:** `hvigor assembleHap` → BUILD SUCCESSFUL; installed via `hdc install -r`; launched with `aa start`; tapped the screen centre via `uitest uiInput click`; captured a screenshot confirming the red popup.

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
  * Phone image: downloaded via emulator CLI — `Emulator.exe -install -deviceType phone -osVersion "HarmonyOS 6.1.1(24)"` (the CLI waits for a TTY confirmation; piping `y` unblocks it). Created and started instance `Huawei_Phone` (API 24).
  * SDK/runtimeOS (fix 2): project was `"runtimeOS": "OpenHarmony"`, API 23, while the emulators are HarmonyOS (API 23/24); sources import `@kit.*` (HarmonyOS), which caused a SysCap deployment error. Fixed `build-profile.json5`: `compileSdkVersion "6.1.1(24)"`, `compatibleSdkVersion "6.1.0(23)"`, `targetSdkVersion "6.1.1(24)"`, `runtimeOS "HarmonyOS"`.
* **Key Prompts:**
  * *Prompt 1:* "W deveco studio chcę uruchomić emulator, jednak mam tylko opcję preview ... dostęp tylko do wearable ... jak mogę zrobić emulator, rozwiąż problem."
  * *Prompt 2:* "Wersja sdk mi się nie zgadza z oboma emulatorami jakie posiadam i nie mogę uruchomić, napraw to."
* **Testing & Debugging:** hvigor `assembleHap` → BUILD SUCCESSFUL; `hdc install` on API 24 (5555) and API 23 (5557) emulators; launch via `aa start`; device screenshot confirmed the "Hello World" UI.

#### 4. Review & Validation
* **Human Oversight:** Developer requested the fixes; results were verified by a full build plus on-device install, launch, and screenshot.
* **Security Checks:** The region change only edits local IDE config; `.bak` backups kept; no secrets, credentials, or PII involved.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** `Emulator.exe -install` silently no-ops without piped input (needs a TTY confirmation). Changing the Windows region/language alone does nothing — the IDE's `country.region.xml` must be edited while DevEco Studio is fully closed.
* **Lessons Learned:** For local HarmonyOS emulators, the IDE region gates which device images are offered; and a project's `runtimeOS` must match the emulator OS (OpenHarmony vs HarmonyOS), otherwise the SysCap check blocks deployment.
