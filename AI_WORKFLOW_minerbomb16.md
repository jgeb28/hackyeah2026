# AI Workflow - minerbomb16

---
## Update: 2026-10-03 23:45:55
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** **LAYA fp32 on-device** via MindSpore Lite, running in an ArkTS **Worker** (`LayaWorker` + `LayaEngineClient`), fully offline (no INTERNET permission).
* **Inference Flow:** bundled rawfile → `AssetLoader` materialises it to `filesDir` (offset-aware) → worker `loadModelFromFile` → `BpeTokenizer` → `input_ids`/`attention_mask` `[3,512]` → `predict` → `[1,3,5]` logits → verdict in `AnswerPopup`.
* **Data Handling & Privacy:** text and model stay on device; frame/text never leaves it.
* **Limitations & Validation:** ✅ **first successful end-to-end run** on the emulator. Verdict: **CRITICAL**, category **scam 93%**, risk 23%, urgency 1.60. `LayaWorker: infer ok: tokens=48 **latency=183135 ms**` (~3 min). Memory saturated (5893/5941 MB, 47 MB free) → the latency is swap-bound, not a code issue.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** get Laya running end-to-end on a local emulator and measure whether the earlier failure was code or memory.
* **Implementation:** raised the emulator RAM 4096→**6144**; hit `ErrorCode: 00801002` (host C: needed 21.6 GB, had 21.0 GB) and moved the emulator instance store to D: with a junction — then moved a **single** instance (`Pura 90 max`, 6 GB RAM, **12 GB data**) back to C: and rewrote `lists.json`/`config.ini`; verified `free -m` (5941 MB) and `/data` (6.8 GB free); ran the app and monitored memory every 15 s.
* **Key Prompts:** "zmien emulator na 6gb ramu"; "puściłem tests, monitoruj pamiec"; "przeszło!"
* **Testing & Debugging:** memory climbed from ~1.8 GB baseline to **~5.9 GB used / 42–81 MB free**; logs showed `model loaded (prefixes=3 maxLen=512)` in 12 s then, after ~3 min, `infer ok: … latency=183135`; screenshot confirms the popup (CRITICAL / scam 93% / 183135 ms).

#### 4. Review & Validation
* **Human Oversight:** developer ran the test and confirmed the result ("przeszło!").
* **Security Checks:** no secrets; model artefact git-ignored; no network path.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** 4 GB emulator → `predict` never returned and the system issued `LowMemoryKill`; the earlier main-thread `loadModelFromFd` gave `getInputs() === undefined` (whole-HAP fd, offset ignored).
* **Lessons Learned:** (1) the rawfile **offset/length** must be honoured when materialising a bundled `.ms`; (2) the ArkTS **Worker** is required so the 1.7 GB load does not trip `THREAD_BLOCK_6S`; (3) **memory is the real limit**: 6 GB completes the inference but takes ~183 s due to swap — the next win is 8 GB RAM or a quantised (int8/q4) artefact.


---
## Update: 2026-10-03 23:14:08
**Developer:** minerbomb16

#### 1. AI Features
* **Model/Service:** LAYA fp32 on-device via MindSpore Lite, now running in an ArkTS **Worker** (teammate branch `add_jev` after pulling `feat/laya-ondevice`).
* **Inference Flow:** bundled rawfile (`offset=106894`, magic `MSL2`) → `AssetLoader` materialises it to `filesDir` (offset-aware) → `LayaWorker.loadModelFromFile` → `predict` in the worker; UI thread only decodes logits.
* **Data Handling & Privacy:** fully offline, no INTERNET permission; text stays on device.
* **Limitations & Validation:** on the **4 GB** Huawei emulator the worker **loaded the model in ~5 s** (`model loaded (prefixes=3 maxLen=512)`) but `predict` never returned — the system logged `LowMemoryKill` and killed the session. fp32 (~1.69 GB) does not fit a 4 GB guest.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash` (DeepSeek V4.1 Flash).
* **MCP Servers & Skills:** none.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** decide whether the earlier `model.getInputs() === undefined` was a code bug or a memory problem, and test Laya end-to-end on the existing emulator without changing the machine.
* **Implementation:** probed the rawfile-fd hypothesis (logged `getRawFdSync` `offset`/`length`); cleaned the branch and fast-forward pulled `origin/add_jev` (`8cd7f8c → 162c40a`) which already contains the fix (offset-aware rawfile→filesDir copy + worker); built and installed the 1.57 GB HAP (model bundled in `rawfile` for the first install) and monitored `free -m`.
* **Key Prompts:** "dokończ"; "spróbuj narazie bez zmiany maszyny"; "what is the verdict? is it a problem with swap?"
* **Testing & Debugging:** `t+100 s` Mem **3852/3931 MB used (78 MB free)** → thrashing; `t+200/300 s` fell back to ~1.3 GB used. Logs: `AssetLoader: copied 1686318032 bytes`, `LayaWorker: model loaded (prefixes=3 maxLen=512)`, `Engine ready (fp32)`, then `SCBMain ... LowMemoryKill` ×3 and **no** inference result.

#### 4. Review & Validation
* **Human Oversight:** developer asked to try on the current machine without changing it.
* **Security Checks:** offline; no new permissions; model artefact git-ignored.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the old main-thread `loadModelFromFd` path yielded `getInputs() === undefined` (invalid model); superseded by the upstream worker + offset-aware copy.
* **Lessons Learned:** (1) `getRawFdSync` returns the whole HAP — the rawfile `offset`/`length` must be honoured; (2) a correct worker fix still cannot beat physics: a 1.7 GB fp32 model + 4 GB guest = `LowMemoryKill`. Check `free -m`/VmSwap before blaming the model; use ≥6 GB RAM or a smaller quantised artefact.


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
