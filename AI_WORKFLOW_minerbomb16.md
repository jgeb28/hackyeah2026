# AI Workflow — minerbomb16

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
