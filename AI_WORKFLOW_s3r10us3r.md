# AI Workflow — developer `s3r10us3r`

Per the project's updated agent rules (`HuwaweiChallenge/AGENTS.md`), AI-assisted
development is documented **per developer**. This is the workflow log for git
user **`s3r10us3r`**. Entries are **newest-first**, each starts with a timestamp,
and each is kept deliberately compressed (highlights only — no transcripts).

> Rules: see [`HuwaweiChallenge/AGENTS.md`](./HuwaweiChallenge/AGENTS.md) and the
> repo [`AGENTS.md`](./AGENTS.md). This file holds only this developer's entries.

---
## Update: 2026-10-03 17:03:29
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app` skill (Oniro emulator scripts); no MCP servers.
* **Configuration/toolchain:** DevEco command-line-tools bundled `typescript` (`tsc` invoked via Node 26) for device-free tests; `oniro-app` for build/install.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Implemented the Phase-1 SDK trigger as a real HAR (`@hackyeah/guardian_sdk`) behind an `IngestSource` abstraction (DESIGN §7.1), replacing the ad-hoc common-event bridge.
* **Implementation:**
  * New HAR `HuwaweiChallenge/guardian_sdk`: platform-free `GuardianProtocol` (`GUARDIAN_MESSAGE_EVENT`, `encodeReport`/`decodeReport`) + `GuardianClient`/`ReportEmitter` (common-event publish; emitter injectable for tests).
  * Engine refactor (platform-free, unit-testable): `trigger/TriggerTypes.ts`, `Classify.ts`, `ScanPolicy.ts` (dedupe + per-minute budget, injectable clock), `IngestSource.ts` (`ScanJob`/`IngestSource`/`TriggerAlertSink`). `TriggerEngine` now takes an injectable policy + alert sink; `NotificationService` implements the sink.
  * Guardian-side `sdk/InAppSdkSource.ets` subscribes to the SDK event, decodes, and feeds the engine; wired in `EntryAbility`. Removed `TriggerBridge.ets`/`TriggerTypes.ets`.
  * `mocks/mockchat` now calls `GuardianClient.report(...)` instead of publishing raw common events.
* **Key Prompt:** "Now implement the SDK based trigger. Create automatic unit and integration tests."
* **Testing & Debugging:**
  * **Unit (device-free):** `tests/unit/*.test.ts` compiled with the SDK `tsc` (`tsconfig.tests.json`) and run via `node --test`; `tests/run.sh` → **16/16 pass** (protocol round-trip/fallback/rejects; classifier thresholds; dedupe/budget).
  * **Integration (on-device):** `entry/src/ohosTest/ets/test/SdkTrigger.test.ets` (hypium) encodes via the SDK, decodes as `InAppSdkSource` does, and runs a real `TriggerEngine` with a fake alert sink; `tests/run-integration.sh` builds+installs both HAPs and runs `aa test`. **Result on the Oniro API 23 emulator: `Tests run: 3, Failure: 0, Error: 0, Pass: 3`.**
  * Fixes: HAR required `src/main/module.json5`; cross-project HAR linking failed hvigor's module-boundary check until `guardian_sdk` was declared as a module in the mockchat project (plain symlinked `ohpm install` then works); ohosTest `deviceTypes` had to match the app (`default`); `start-windowed.sh` had a malformed QEMU `hostfwd` rule → `tcp::PORT-:55555`.

#### 4. Review & Validation
* **Human Oversight:** autonomous implementation; developer to review before PR.
* **Validation evidence:** device-free unit suite = 16/16 pass; on-device `ohosTest` on the Oniro API 23 emulator = 3/3 pass; both apps build via `oniro-app`; launching the app logs `GuardianSdkSource: SDK source subscribed` (runtime wiring confirmed).
* **Security Checks:** no secrets added; signingConfigs (passwords) left unstaged; generated `.test-build/` and `BuildProfile.ets` gitignored.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** cross-project `file:` HAR dependency as a raw symlink is rejected by the ArkTS module-boundary check; project-level `.ohpmrc` is not honored.
* **Lessons Learned:** declare a cross-project HAR as a module in the consumer project; keep detection logic platform-free in `.ts` for off-device testing — Node strips types but not enums, so compile with the SDK `tsc`.
* **Known limitation (emulator):** the live cross-app demo (mockchat foreground → Guardian) is not reproducible on this Oniro emulator because it kills the backgrounded Guardian process, dropping the common-event subscriber. Phase 1's in-app/ohosTest paths still validate the full SDK→engine→alert pipeline; staying alive cross-app is Phase 2 (continuous task / real device).

---
## Update: 2026-10-03 16:51:12
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none; used `websearch` to verify HarmonyOS screen-capture constraints.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture (decision):** Adopted a **phased HarmonyOS strategy**: **Phase 1 = in-app SDK** trigger (hackathon simulation, emulator-friendly), **Phase 2 = screen capture → on-device OCR** (the "real" path that reads apps *without their cooperation*), **§16 north star = first-level system access**. Rationale: embedding Guardian into the mock app is a weak demo; OCR is the closest a third-party HarmonyOS app gets to system access.
* **Verification (internet):** Huawei FAQ confirms `screenshot.capture()` returns a **full-screen** shot; third-party access via `CUSTOM_SCREEN_CAPTURE` (`normal`/`user_grant`), requested from a foreground window (`CAPTURE_SCREEN` is system-only). Background/continuous capture uses `AVScreenCapture` + a continuous task (`KEEP_BACKGROUND_RUNNING` + `backgroundModes`) but **AVScreenCapture is real-device only (not on the emulator)**.
* **Implementation:** updated `DESIGN.md` (696 lines) — phase framing in the scope banner/§1/§3; new Phase 2 prerequisites (§4.5); HarmonyOS feasibility table (§5); triggers §7.1 SDK / §7.2 OCR; notifications clarified as local-vs-Push-Kit (§10); permissions + risks + milestones (M7) updated; OCR labels changed from "stretch" to "Phase 2".
* **Key Prompts:** "What is the push kit vs sdk based difference? … If it would mean we need to embed our app in the mock it's the worse design."; "Let's do it via sdk FIRST … we will simulate then do real OCR if we have time"; "Verify then using the internet."

#### 4. Review & Validation
* **Human Oversight:** user approved consent+indicator, throttling + NPU acceleration; accepted SDK-first sequencing.
* **Security Checks:** no secrets added; shipping build still assumes no system/restricted permissions.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** on HarmonyOS a third-party app cannot read other apps' UI or notifications; **screen capture + OCR is the only no-cooperation trigger**, and it is real-device-only for continuous capture. Local notifications are an *alert output*, not a trigger; Push Kit is server-originated and unrelated.

---
## Update: 2026-10-03 16:43:57
**Developer:** s3r10us3r

#### 3. Development Workflow & Prompts
* **Ideation & Architecture (decision):** After comparing HarmonyOS vs OpenHarmony, chose **HarmonyOS-only** as the shipping target and rewrote `DESIGN.md` (v2) around the triggers a **third-party HarmonyOS app** can actually use: **A1 in-app SDK (primary)**, **SDK-driven local notifications** as the alert surface, **A3 screen capture → on-device OCR (stretch)**, plus optional share/clipboard. Added a new **§4 Requirements & prerequisites** and a top-level **§16 Intended / final design — first-level (system) access** capturing the accessibility + notification-listening vision reachable only with system signing (OpenHarmony self-sign today; Huawei system signing on HarmonyOS).
* **Implementation:** full rewrite of `DESIGN.md` (16 sections + 2 appendices, 661 lines), reconciling an earlier partial edit; renumbered sections and fixed cross-references. No source code changed.
* **Key Prompts:** "we will restrict our design to HarmonyOS… The design doc should then have the sdk based notifications. Add also the screenshot thing - as a stretch"; "keep an intended/final design where you write about the first-level system access"; "Top level section. Edit the DESIGN.md."

#### 4. Review & Validation
* **Human Oversight:** confirmed scope = HarmonyOS; interpreted "first-level system access" as APL `system_basic` system-app access.
* **Security Checks:** no secrets added; no restricted/system permissions assumed in the shipping build.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** a third-party HarmonyOS app cannot read other apps' UI or notifications; SDK integration is the only automatic cross-app trigger. Local notifications are an *alert output*, not a trigger; Push Kit is server-originated and not a local trigger.

---
## Update: 2026-10-03 16:29:29
**Developer:** s3r10us3r

#### 3. Development Workflow & Prompts
* **Ideation & Architecture (decision):** Recorded the technical decision in `DESIGN.md`: the accessibility premise is **removed** (closed to third-party apps at API 12+), and Guardian ingestion becomes **A1 in-app SDK (primary) + A4 notification trigger (secondary, restricted/best-effort)**, with **A3 screen-capture→OCR as a stretch**. Engine moves behind an `IngestSource` abstraction (`InAppSdkSource`, `NotificationSource`, `ScreenOcrSource`).
* **Implementation:** rewrote `DESIGN.md` §1, §2 (persona), §3 (goals/non-goals), §4 (feasibility table → SDK/notification/OCR, accessibility marked closed), §5 (architecture diagram + components), §6 (IngestSource interface, per-source rules, scan policy), §10 (consent/data handling/threat model), §11 (permissions), §12 (demo), §13 (risks), §14 (milestones), Appendix B.
* **Key Prompt:** "In design make a technical decision, we will use A1 AND push notification trigger, A3 as a stretch."

#### 4. Review & Validation
* **Human Oversight:** interpretation of "push notification trigger" = the notification-subscriber ingress (A4); flagged to the user for confirmation.
* **Security Checks:** no permissions invented; permission levels cited from `PermissionDefinitions.json`; no secrets.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** documenting the restricted notification permission explicitly as "inactive + logged, never faked" keeps the design honest and the demo reproducible (A1 via mock apps).

---
## Update: 2026-10-03 16:25:42
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none (plain SDK + web research).
* **Configuration:** searched the local OpenHarmony SDK at `~/setup-ohos-sdk/linux/23/` (`ets/api/*.d.ts`, `toolchains/lib/PermissionDefinitions.json`, `toolchains/modulecheck/module.json`) to derive API/permission facts; cross-checked with Huawei docs (via websearch) since the doc pages are JS-rendered and `webfetch` returns an empty shell.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** Asked for an extensive survey of event/listener sources a **third-party** app can use on HarmonyOS/OpenHarmony **API 20+**, to replace the accessibility trigger (which is closed to third-party apps: `AccessibilityExtensionAbility.onAccessibilityEvent/onKeyEvent/onConnect/onDisconnect` are `@deprecated since 12`; `ohos.permission.ACCESSIBILITY_EXTENSION_ABILITY` is `system_basic` since 20). Goal: decide the real trigger surface for Guardian.
* **Implementation:** none (research only). Mined permission levels from `PermissionDefinitions.json`, enumerated all `on(type:'…')` subscription APIs across `ets/api/*.d.ts`, listed the public `usual.event.*` common events, and verified third-party viability per API.
* **Key Prompts:** "Do an extensive search and bring me back a list of events that **can** be listened to. If nothing works we will do notification listener and In-app sdk."
* **Testing & Debugging:** n/a (no code changed).

#### 4. Review & Validation
* **Human Oversight:** findings are sourced from the installed SDK's permission table (authoritative) plus Huawei/community docs; conclusions flagged where only community evidence exists.
* **Security Checks:** no secrets used; local signing passwords stay out of the workflow file.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** third-party accessibility trigger — closed at API 12+, not an emulator issue, so the Windows HarmonyOS emulator would not help either.
* **Lessons Learned (key):** Third-party notification listening is **also restricted**, not open: `NotificationSubscriberExtensionAbility.onReceiveMessage` (API 22) needs `ohos.permission.SUBSCRIBE_NOTIFICATION` = `system_basic`/`system_grant`, provision-gated via AGC and documented for third-party **wearable/companion** apps. So "notification listener + in-app SDK" collapses to **in-app SDK + user-initiated paths** unless Huawei grants the restricted permission.
* **Only real third-party text surfaces found:** (1) own/in-app SDK, (2) ShareExtensionAbility + foreground clipboard/paste (user-initiated), (3) InputMethodExtensionAbility (an IME can read the focused editor's text across apps, incl. `getForward/getBackward`, `SecurityMode.FULL`), (4) screen capture + OCR (`ohos.permission.CUSTOM_SCREEN_CAPTURE` = `normal`/`user_grant`; AVScreenCapture basic only shows a mandatory consent dialog). No general "rendered on-screen text" event exists for third parties.

---
## Update: 2026-10-03 15:17:25
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** OpenCode `opencode` skill (V2 docs) for config/model guidance.

#### 3. Development Workflow & Prompts
* **Key Prompt:** "Set 400K context limit for deepseek models (all)".
* **Configuration:** created global `~/.config/opencode/opencode.json` (no repo files
  changed) with `providers.deepseek.models.{deepseek-flash,deepseek-v4-pro}.limit.context = 400000`.

#### 4. Review & Validation
* **Output Review:** `opencode api get /api/model` reports both DeepSeek models with
  `limit.context=400000` and the catalog output limit preserved (393216). JSON validated
  with `python3 -m json.tool`.

#### 5. Limitations & Lessons Learned
* **Limitations:** a partial `limit` override merges with the catalog (context replaced,
  output retained); every DeepSeek model must be listed explicitly — V2 has no
  provider-wide limit wildcard.

---
## Update: 2026-10-03 16:11:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app`; SDK API reference
  (`~/setup-ohos-sdk/linux/23`).

#### 3. Development Workflow & Prompts
* **Key Prompt:** "Can you wire the trigger to the notification?"
* **Implementation:** added `alert/NotificationService.ets` — publishes a local
  notification (title by verdict, message text, `signals` + `via`) from
  `TriggerEngine.handle()` whenever `action=ALERT`. Added the first deterministic
  rules pass in `TriggerEngine.classify()` (impersonation / urgency / payment /
  isolation; 0→SAFE, 1→DANGEROUS, ≥2→CRITICAL) so the scam thread actually
  alerts. Both abilities call `notificationManager.requestEnableNotification()`.
  Also added the in-app `TriggerDemo` + `DemoAbility` so the trigger is runnable
  locally, and made the path explicit in logs (`via=… action=…`).
* **Testing & Debugging:** rules verified on the emulator — messages now yield
  `DANGEROUS/phishing`/`CRITICAL/scam` and `action=ALERT`; `NotificationService`
  is invoked per alert.

#### 4. Review & Validation
* **Human Oversight / blocker:** notification **delivery could not be shown on the
  Oniro emulator** — there is no running ANS/`NotificationService` process in the
  image, so `notificationManager.publish()` fails with `Notification disabled`
  and `requestEnableNotification()` returns an IPC error. The notification path
  is wired and will work where the notification service runs (device / DevEco
  HarmonyOS emulator).
* **Security Checks:** no restricted permission declared; notification content is
  the on-screen text only; no secrets.

#### 5. Limitations & Lessons Learned
* **Limitations:** the emulator lacks a working notification service and cannot
  enable third-party accessibility; only the in-app `TriggerDemo` runs there.
* **Lessons Learned:** ArkTS rejects a ternary over two enum members as a field
  value when the target type is the enum (`SlotType` union not assignable) —
  drop the optional field or assign via an `if`.

---

## Update: 2026-10-03 15:47:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app` (build/install/launch; windowed
  emulator). API verified against the installed SDK (`~/setup-ohos-sdk/linux/23`).

#### 3. Development Workflow & Prompts
* **Key Prompts:** "Now, we need to create the triggers, explore the design doc."
  Clarified → *main app* (`HuwaweiChallenge`), trigger "whenever text is rendered
  in the messaging app"; deterministic rules then LAYA later.
* **Implementation (DESIGN.md §6/§7):**
  * `entry/src/main/ets/trigger/TriggerTypes.ets` — `Verdict`, `TriggerSource`,
    `ScanResult`, `ScanRequest`.
  * `entry/src/main/ets/trigger/TriggerEngine.ets` — `onTextRendered()` (the
    trigger): unchanged-skip + dedupe window + rolling scans/min budget, then
    `classify()` (model-agnostic; today returns SAFE) and `handle()` (logs;
    TODO alert). Per-app target `com.hackyeah.mockchat`.
  * `entry/src/main/ets/accessibility/GuardianAccessibilityExtAbility.ets` —
    `AccessibilityExtensionAbility`; on every accessibility event flattens the
    current window root (text + description, ≤2000 chars), gates on the target
    bundle, and calls `TriggerEngine.onTextRendered()`.
  * `resources/base/profile/accessibility_config.json` (`retrieve` capability);
    registered in `entry/src/main/module.json5` with metadata
    `ohos.accessibleability`; added accessibility strings.
* **Testing & Debugging:** `oniro-app sign` + `oniro-app build` → **BUILD
  SUCCESSFUL**; `bm dump` confirms the extension is registered
  (`extensionTypeName: "accessibility"`). First build failed with
  `arkts-no-untyped-obj-literals` for `TRIGGER_CONFIG` → fixed by declaring a
  `TriggerConfig` interface.

#### 4. Review & Validation
* **Human Oversight / blocker:** end-to-end firing could **not** be validated on
  this Oniro emulator. The Settings "Accessibility features" page has **no
  Installed/Downloaded-services section**, and writing
  `enabled_accessibility_services` directly in the secure settings DB
  (`/data/app/el1/0/database/com.ohos.settingsdata/.../settingsdata.db`) is
  **reset on boot** by the accessibility framework. Enabling a third-party
  accessibility service therefore needs a real HarmonyOS device or the DevEco
  HarmonyOS emulator (teammate's API 23/24 images).
* **Security Checks:** no restricted permissions requested; all logic is
  on-device; no secrets added.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** direct secure-settings DB write + reboot (value
  reset by `accessibility_config_impl`); launching Settings via
  `aa start -a MainAbility` (needs the *full* ability name
  `com.ohos.settings.MainAbility -m phone`).
* **Lessons Learned:** the Oniro x86 emulator exposes accessibility *syscaps* but
  not a UI/framework path to enable a third-party accessibility service; plan the
  cross-app trigger demo for a real-device/DevEco HarmonyOS emulator. ArkTS
  requires explicitly typed object literals (`arkts-no-untyped-obj-literals`).

---

## Update: 2026-10-03 15:34:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app` (added a windowed launcher).

#### 3. Development Workflow & Prompts
* **Key Prompts:** "change the layout to phone"; "Make sure the message mock works
  on the latest PR".
* **Implementation / debugging:** root-caused the QEMU window showing
  `Display output is not active.` The stock `run.sh` uses
  `-vga none -device virtio-gpu-pci`; on this host (Wayland + hybrid GPU,
  QEMU 11.1.1) that console is never presented by SDL/GTK. Fix: use the
  VGA-class `-vga virtio` (+ `-display sdl,gl=on`) — the window then shows the
  full OS. Also found `virtio-vga` makes the guest follow the host window size,
  so `xres/yres`/`edid=off` only apply with `-vga none` (which breaks the
  presenter) — phone layout = resize the window instead.
* **Skill changes:** new `scripts/start-windowed.sh`; `emulator.sh` now defaults
  to the windowed launcher and keeps `start-vnc`/`capture` as fallbacks;
  `SKILL.md` §1.1 rewritten.

#### 4. Review & Validation
* **Output Review:** launched `com.hackyeah.mockchat` on the emulator and
  captured the host desktop — the mock renders in the window, mission
  `#FOREGROUND`. Confirmed the mock is committed in **PR #5** (`feat/mockchat`,
  commit `ef7688d`): `Index.ets` + module/resources tracked; no generated/test
  junk (`oh_modules`, `build/`, `.vscode`, `local.properties`, `signatures/`)
  is committed. The only working-tree mock change is an `oniro-app sign`-added
  `signingConfigs` block in `build-profile.json5` (contains signing passwords) —
  it must **not** be committed.

#### 5. Limitations & Lessons Learned
* **Limitations:** windowed mode is portrait-unfriendly unless the window is
  resized; phone resolution can't be pinned via QEMU args while keeping the
  presenter.
* **Lessons learned:** on this host, present the emulator with `-vga virtio`,
  never `-vga none + virtio-gpu-pci`; VNC (`start-vnc` + `capture`) still works
  dependency-free if no VNC viewer is installed.

---

## Update: 2026-10-03 15:20:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app` skill (build/sign/install/launch;
  headless/VNC emulator helper + `vnccap.py`).

#### 3. Development Workflow & Prompts
* **Key Prompt:** "Continue with showing me the working message mock."
* **Implementation:** built, signed, installed and launched the existing
  `com.hackyeah.mockchat` ArkTS mock (`mocks/mockchat`) on the Oniro emulator via
  `scripts/run-app.sh .`; drove the tap-to-advance script with
  `oniro-app input --type click` and captured the guest framebuffer over VNC.

#### 4. Review & Validation
* **Output Review:** VNC capture shows the mock rendering correctly — top bar
  ("Unknown number"), incoming/outgoing bubbles, composer — and the full 6-line
  scam script after tapping. `aa dump -l` confirms mission `#FOREGROUND` for
  `com.hackyeah.mockchat`. Evidence: `/tmp/opencode/mock_0.png`,
  `/tmp/opencode/mock_full.png`.

#### 5. Limitations & Lessons Learned
* **Limitations:** the mock is UI-only (hardcoded script, no model/back-end yet);
  it only demonstrates the interaction shell, not the AI feature.
* **Dead ends:** the QEMU SDL/GTK window still shows "Display output is not
  active" on this host; VNC is the working display path (documented in the skill).

---

## Update: 2026-10-03 15:14:09
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none; shell, websearch, gcc.

#### 3. Development Workflow & Prompts
* **Key Prompts:** "Can we check if my right click is working on hardware level?"
* **Implementation:** read `/sys/.../capabilities/key`; after the user granted a
  read ACL (`setfacl`) on `/dev/input/event7,8`, captured raw evdev with a small
  Python parser; because a clickpad exposes no `BTN_RIGHT`, compiled a native-Wayland
  GTK4 probe (`~/.cache/gtkclick.c`) that logs the **processed** `button=` the
  compositor delivers.
* **Testing & Debugging:** raw evdev proved the pad is a clickpad (`BTN_LEFT` +
  `BTN_TOOL_*` only; two-finger tap → `BTN_TOOL_DOUBLETAP`, no button). The GTK
  probe received a real `button=3 (RIGHT)` event, so right-click works end-to-end
  at the OS level. Touchpad opts: `tap-to-click=true`, `clickfinger_behavior=false`.

#### 4. Review & Validation
* **Human Oversight:** user performed gestures on-screen; results read from the
  probe log.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** an independent `libinput` path context refused the
  devices (opens `O_RDWR`; ACL was read-only) — the compositor-level GTK probe was
  the working method.
* **Lessons Learned:** on a clickpad right-click is software-emulated, so raw evdev
  never shows `BTN_RIGHT`; verify at the compositor level. Two-finger-tap
  right-click needs Hyprland `touchpad.clickfinger_behavior=true`.
* **Security Checks:** the input-device read ACL is temporary (resets on reboot);
  no secrets committed.

---
## Update: 2026-10-03 14:56:57
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app` skill; no MCP servers.
* **Configuration:** JDK 17; project `.npmrc` kept local (git-ignored).

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "we are going to make a MOCK app … mock messages and 'on click' render the
    scenario A conversation … Before pushing anything i MUST test it via EMU."
* **Ideation & Architecture:** standalone OpenHarmony project `mocks/mockchat`
  (bundle `com.hackyeah.mockchat`, API 20) that visually mimics the HarmonyOS
  Messages app; tap-**anywhere** advances Scenario A one bubble at a time
  (including one outgoing user reply), so it will emit accessibility
  `textUpdate`/window-content events for Guardian.
* **Implementation:** scaffolded via `oniro-app create --sdk 20`; wrote
  `entry/src/main/ets/pages/Index.ets` (top bar, bubble list, input bar);
  `oniro-app sign → build → app install → app launch`.

#### 4. Review & Validation
* **Human Oversight:** emulator test (required before push) — `BUILD SUCCESSFUL`,
  install/launch OK, `aa dump -l` shows the app `#FOREGROUND`; screenshots confirm
  the full thread renders; `oniro-app dump layout` shows every message as a
  `"text"` node (i.e. readable by an accessibility service).
* **Security Checks:** `.npmrc` / `.vscode` / `local.properties` are git-ignored
  (`gitignore` now ignores `.npmrc` repo-wide); the `signingConfigs` block written
  by `oniro-app sign` was reverted and not committed.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** the mock's on-screen text is exposed in the layout tree, so
  the accessibility-trigger phase can key off it; keep the project `.npmrc`
  uncommitted (it can carry registry tokens).

---
## Update: 2026-10-03 14:45:32
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none.
* **Configuration:** per-developer workflow rules (`HuwaweiChallenge/AGENTS.md`).

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "Remove all the files other than agents.md and the design doc… Keep all
    instructions required to run this local though."
  * "You should keep the AI_WORKFLOW_s3r10us3r file. Add it now. Make sure that
    AI_WORKFLOW rules is there."
* **Implementation:** cleaned up the over-broad PR #2 after it merged (removed the
  probe app, research docs, editor config, model binary and local npm config);
  kept `AGENTS.md`, `DESIGN.md`, `.gitignore`, the `run-openharmony-app` skill
  and this workflow file; stated the per-developer AI_WORKFLOW rules in
  `AGENTS.md`.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** `git add -A` in the cleanup first swept in
  `init_design.md`; it was removed from the commit.
* **Lessons Learned:** keep PRs scoped; state the workflow rules in the canonical
  `AGENTS.md` so they survive file cleanups.

---
## Update: 2026-10-03 14:40:17
**Developer:** s3r10us3r

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "In agents.md make sure to not add all of the files like 'setting.json'. …
    add a rule to avoid that in the future."

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** an earlier PR swept in everything on local `main`
  (editor config, the probe app, an 11 MB model binary, unrelated prior work)
  instead of only the task's files.
* **Lessons Learned:** added **`AGENTS.md` §8 "Commit & staging hygiene — do not
  dump files"** (no `git add -A` on mixed work; no editor/IDE or generated files;
  no large binaries; keep commits/PRs scoped). Stage explicit paths only.

---
## Update: 2026-10-03 14:25:39
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** `run-openharmony-app` skill; no MCP servers.
* **Configuration:** new team rules in `HuwaweiChallenge/AGENTS.md`
  (per-developer workflow files, timestamped, strict conciseness).

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "Rebase on main and curate all the things dumped in AI_WORKFLOW.md according
    to the new rules. Then commit and push."
* **Implementation:** rebased local `main` onto `origin/main` (new ruleset
  `3cf5efa`), then rebased `design/app-spec` onto `main`. Replaced the verbose
  workflow dump with this compressed, per-developer, newest-first log; reduced
  `AI_WORKFLOW.md` to an index.

#### 4. Review & Validation
* **Human Oversight:** developer reviews the branch before merge.
* **Security Checks:** scrubbed credentials from the historical notes; no secrets
  committed.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** the team standardized on per-developer, timestamped,
  highlights-only workflow files; reference prior entries instead of repeating.

---
## Update: 2026-10-03 14:23:00
**Developer:** s3r10us3r

#### 1. AI Features (designed, not yet built)
* **Model/Service:** **LAYA** non-autoregressive decision model (classification),
  a bundled **embedding** model, and an optional small on-device LLM; optional
  cloud LLM only with consent.
* **Inference Flow:** accessibility event → read on-screen UI text tree →
  `classify()` → verdict (`SAFE`/`DANGEROUS`/`CRITICAL`) → embedding-RAG
  retrieval → remediation; escalation `KB → on-device LLM → cloud (consent)`.
* **Data Handling & Privacy:** on-device by default; screen text processed in
  memory; cloud only with explicit per-incident consent.
* **Limitations & Validation:** LAYA conversion/accuracy unproven; kept a
  model-agnostic `classify()` plus a fallback classifier; emulator is CPU-only.

#### 2. AI Development Tools Used
* **Models & Agents:** `deepseek/deepseek-flash` via OpenCode.
* **MCP Servers & Skills:** none (read/grep/shell, websearch, question tools).

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** the assistant proposed the accessibility-based
  architecture and ran a multi-round Q&A to lock scope.
* **Key Prompts:**
  * "There are several on-the-fly design decisions and inaccuracies that I made
    here. Ask me questions and we will arrive on a final design."
* **Implementation:** grounded every feasibility claim in the installed SDK
  `.d.ts` files; produced `DESIGN.md` (architecture, feasibility table,
  detection, RAG/escalation, alert UX, consent/privacy/threat model, demo plan,
  risks, milestones, LAYA appendix).

#### 4. Review & Validation
* **Human Oversight:** the developer answered the design questions; the doc is
  on branch `design/app-spec` (adds only `DESIGN.md`).

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the draft's core UX (Smart Island + overlay over
  another app) is **not achievable by a normal third-party HAP**.
* **Lessons Learned:** on OpenHarmony, "read the screen" is an accessibility
  capability, but "draw over other apps" and Live View are system-only — verify
  against the SDK before designing UX.

---
## Update: 2026-10-03 14:08:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** `deepseek/deepseek-flash` via OpenCode.
* **MCP Servers & Skills:** none; shell + `oniro-app`, `ohpm`, `hvigorw`, `hdc`.

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "Do all the steps required to run it through API 20+."
* **Testing & Debugging:** the API 23 build **destroyed the project** at the
  packaging step. Instrumented Node `fs`/`fs-extra` (no deletes logged), then
  reproduced the cause directly: the API 23 `app_packing_tool.jar` **deletes its
  own CWD** on failure. Root cause was the **JVM version** — under the system
  Java 27 it misbehaves; **JDK 17** (the version DevEco bundles) fixes it.
* **Implementation:** installed SDK 6.0/6.1, fetched Temurin JDK 17, then
  `oniro-app sign → build → app install → app launch`.

#### 4. Review & Validation
* **Human Oversight / evidence:** `BUILD SUCCESSFUL`; `install bundle
  successfully`; `start ability successfully`; `aa dump -l` shows the app
  `state #FOREGROUND`; the signed HAP declares `minAPIVersion: 23`.
* **Security Checks:** reverted the `signingConfigs` block that `oniro-app sign`
  writes (it contains passwords); never committed.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** when a build tool "eats" the project, suspect the external
  packing tool and its **JVM version**, not just build-system versions. API 20+
  builds here require JDK 17; keep sources recoverable and build in scratch
  copies.

---
## Update: 2026-10-03 14:00:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** `deepseek/deepseek-flash` via OpenCode.
* **MCP Servers & Skills:** none; `git`, `oniro-app`, `hdc`, `ohpm`.

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "Pull the newest main. Validate you can open the hello world app set up there
    on the emulator."
* **Implementation:** merged the unrelated team `origin/main` (the
  `HuwaweiChallenge` ArkTS project) into local `main`; started the Oniro
  emulator; installed SDK 6.1 (API 23). The API 23 build failed destructively, so
  the app was first validated from a scratch **API 18** build.

#### 4. Review & Validation
* **Human Oversight / evidence:** `install bundle successfully`,
  `start ability successfully`, mission `state #FOREGROUND`, screenshot shows the
  ArkUI "Hello World" screen.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the destructive API 23 build (resolved next
  session — see the 2026-10-03 14:08 update).
* **Lessons Learned:** always keep project sources recoverable; validate via a
  known-good toolchain while diagnosing.

---
## Update: 2026-10-03 13:36:00
**Developer:** s3r10us3r

#### 1. AI Features (built)
* **Model/Service:** MobileNetV2 (`.ms`) run via `@ohos.ai.mindSporeLite`.
* **Inference Flow:** the app loads the model from `rawfile`, feeds a synthetic
  `[1,224,224,3]` input, calls `predict`, and renders timing + top-1. CPU on the
  emulator; the same code path selects the Kirin NPU (`NNRTDeviceType.ACCELERATOR`)
  on device.
* **Data Handling & Privacy:** fully on-device; no network.
* **Limitations & Validation:** CPU-only on the emulator, synthetic input, API 18.
  Validated via `hilog` (`predict success in 191 ms`) and a screenshot
  ("INFERENCE OK").

#### 2. AI Development Tools Used
* **Models & Agents:** `deepseek/deepseek-flash` via OpenCode.
* **MCP Servers & Skills:** none; `oniro-app`, `hvigorw`, `hdc`, websearch.

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "We could have the windows dedicated environment with an account somewhere.
    but we need to validate the idea here."
* **Ideation & Architecture:** desk-validated on-device AI on Huawei silicon
  (MindSpore Lite + NNRt/Kirin NPU; `data.intelligence` embeddings; HMS AI kits),
  and clarified that "app level" means **APL**
  (`normal`/`system_basic`/`system_core`), not model precision.
* **Implementation:** probed the emulator syscaps (`MindSporeLite` present,
  `DataIntelligence` absent), scaffolded an in-repo probe app, and ran real
  inference on the emulator.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** the local Linux SDK previewer is unusable
  (incomplete build), so the emulator is the way to see a GUI.
* **Lessons Learned:** MindSpore Lite is present and functional on the Oniro
  emulator, so the app architecture can be built and validated locally and then
  run on the Kirin NPU on a real device.

---
## Update: 2026-10-03 12:29:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none; shell, websearch.

#### 3. Development Workflow & Prompts
* **Key Prompts:** "Right mouse click on firefox does not work, check my system try
  to fix this".
* **Implementation:** Firefox 156 on Hyprland/Wayland; a prior session cycled the
  `eDP-1` scale live (1.0→1.2→1.5 via `hyprctl eval`). Firefox 146+ enables
  `widget.wayland.fractional-scale.enabled` by default (Mozilla Bug 1997907) and
  mishandles mid-session scale changes (1849109/1881086/1891405/2049137), which
  breaks context menus. Fix: profile `user.js` sets the pref `false`, then
  restart Firefox.

#### 4. Review & Validation
* **Human Oversight:** pref confirmed present in `prefs.js`; user to confirm the
  context menu.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** at non-integer scales Firefox now renders integer+downscale
  (slightly softer); alternatively restart Firefox after each `scale.sh` change.

---
## Update: 2026-10-03 11:58:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** `deepseek/deepseek-flash` via OpenCode.
* **MCP Servers & Skills:** created the `run-openharmony-app` skill
  (`build → sign → install → launch → screenshot`).
* **Configuration:** self-contained `~/ohos/env.sh` (no shell dotfiles modified).

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "Set up harmony os development environment on this computer."
  * "Can we run the emulator. Research what Oniro is."
  * "It works, save the workflow on how to run the app somewhere (a skill?)"
* **Implementation:** installed the public HarmonyOS command-line tools
  (`5.1.0.840`) and the **Eclipse Oniro** QEMU emulator on Arch Linux; fixed a
  QEMU split-package segfault (`qemu-hw-display-virtio-gpu`); built, signed,
  installed and launched a Hello World HAP via `@oniroproject/oniro-app`; saved
  the working loop as an OpenCode skill.

#### 4. Review & Validation
* **Human Oversight / evidence:** `.hap` built (`BUILD SUCCESSFUL`), `hdc`
  connected (`127.0.0.1:55555`), mission `state #FOREGROUND`, screenshot shows
  "Hello World".

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** DevEco Studio IDE is unavailable on Linux; the
  native Linux SDK previewer is an unfinished build.
* **Lessons Learned:** Oniro + the HarmonyOS CLI tools give an account-free Linux
  inner loop; a project-local `.npmrc` is required for the `@ohos` npm scope.

---
## Update: 2026-10-03 11:40:00
**Developer:** s3r10us3r

#### 2. AI Development Tools Used
* **Models & Agents:** `deepseek/deepseek-flash` via OpenCode.
* **MCP Servers & Skills:** none; websearch + shell.

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "Set up agents.md. You have to instruct all agents to work on AI_WORKFLOW.md
    file according to the rules presented in the challenge instruction."
  * "Explore the deliverables. If we were to add a system component, how would
    the deliverables look?"
* **Ideation & Architecture:** extracted the challenge's "Use of AI" rules;
  created `AGENTS.md` + an `AI_WORKFLOW.md` skeleton; produced
  `docs/DELIVERABLES.md` mapping the required deliverables to system-component
  options.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** a true OpenHarmony SystemAbility requires rebuilding the
  system image (conflicts with "don't modify the system"), so the compliant path
  is an installable HAP using an ExtensionAbility and/or native NAPI; system
  signing is only a documented stretch.
