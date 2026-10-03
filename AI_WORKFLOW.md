# AI_WORKFLOW.md

This document records how AI-assisted tools were used to design and build this
submission, as required by the hackathon rules. **All agents must keep it up to
date** — see [`AGENTS.md`](./AGENTS.md) for the mandatory workflow.

> **Status:** In progress. Entries are appended below as work happens.

## Contents

1. [Project summary](#1-project-summary)
2. [AI tools used](#2-ai-tools-used)
3. [Prompts, reusable instructions & configuration](#3-prompts-reusable-instructions--configuration)
4. [Development workflow](#4-development-workflow)
5. [Review, testing & validation of generated output](#5-review-testing--validation-of-generated-output)
6. [AI features (if applicable)](#6-ai-features-if-applicable)
7. [Limitations, unsuccessful approaches & lessons learned](#7-limitations-unsuccessful-approaches--lessons-learned)
8. [Privacy & data handling](#8-privacy--data-handling)
9. [Chronological work log](#9-chronological-work-log)

---

## 1. Project summary

<!-- Agents: fill this in once the idea is decided. -->

- **Idea / product name:** _TBD_
- **Challenge area(s):** _Intelligent Experiences / Spatial Experiences /
  Human-Centric Technology — choose one or more_
- **Target platform:** _HarmonyOS / OpenHarmony / Oniro_
- **Minimum API level:** API 20
- **One-line description:** _TBD_
- **Architecture overview / link to design doc:** _TBD_
- **AI features in the product:** _none yet / describe_

---

## 2. AI tools used

Document **every** AI model, coding agent, MCP server, Agent Skill, and other
AI-assisted tool used. Add a row per tool.

| Tool / model | Provider & version | Type | What it was used for |
| --- | --- | --- | --- |
| OpenCode | _version TBD_ | coding agent harness | project setup, file authoring, running shell tools |
| deepseek/deepseek-flash | deepseek | coding agent model | reasoning, drafting `AGENTS.md` and `AI_WORKFLOW.md` |

---

## 3. Prompts, reusable instructions & configuration

- **Repository rules file:** [`AGENTS.md`](./AGENTS.md)
- **Key prompts / instructions** that materially shaped the output
  (verbatim or faithful summaries; redact secrets):

```text
Set up agents.md. You have to instruct all agents to work on AI_WORKFLOW.md
file according to the rules presented in the challenge instruction
<challenge PDF URL>.
```

- **Relevant configuration** (agent config, MCP config, skills, commands).
  Reference the path and quote only the parts that shaped behavior:

```text
<!-- Add relevant config excerpts here. -->
```

---

## 4. Development workflow

Describe the path from **ideation → architecture → implementation → testing →
debugging**. Link decisions to concrete commits or files where useful.

- **Ideation:** _TBD_
- **Architecture:** _TBD_
- **Implementation:** _TBD_
- **Testing:** _TBD_
- **Debugging:** _TBD_

---

## 5. Review, testing & validation of generated output

Explain how AI-generated output was reviewed, tested, and validated — including
which tests/commands were run and any evidence (logs, screenshots, CI).

- _TBD_

---

## 6. AI features (if applicable)

Complete this section **only if the submission ships an AI feature**. Otherwise
state “No runtime AI features” and remove the prompts.

For each AI feature:

- **Model / service:** _TBD_
- **Inference flow:** _TBD_ (inputs, preprocessing, where inference runs,
  outputs, fallbacks)
- **Data handling:** _TBD_
- **Limitations:** _TBD_
- **Validation approach:** _TBD_
- **Privacy considerations:** _TBD_

---

## 7. Limitations, unsuccessful approaches & lessons learned

- _TBD_

---

## 8. Privacy & data handling

- **No secrets policy:** API keys, credentials, and personal data are removed
  from this document and from the repository.
- _TBD — summarize any runtime data collection/transmission and consent._

---

## 9. Chronological work log

Append a dated entry for every significant task, using the template in
[`AGENTS.md` §4](./AGENTS.md#4-entry-template-copy-this-for-every-significant-task).
Newest entries go at the bottom.

<!-- BEGIN WORK LOG -->

### 2026-10-03 11:25 — Set up agent rules and `AI_WORKFLOW.md` scaffold

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** webfetch, shell (`curl`, `pdftotext`, `file`, `ls`, `wc`), read, write, edit
- **Goal:** Create `AGENTS.md` instructing all agents to maintain
  `AI_WORKFLOW.md` according to the hackathon challenge rules, and seed the
  `AI_WORKFLOW.md` file itself.
- **Prompt(s) / instructions that mattered:**
  > “Set up agents.md. You have to instruct all agents to work on
  > AI_WORKFLOW.md file according to the rules presented in the challenge
  > instruction <challenge PDF URL>.”
- **Approach:** Fetched and text-extracted the challenge PDF, isolated the
  “Use of AI” and “Required Deliverables” sections, then:
  1. Created `AGENTS.md` as the canonical instruction file (OpenCode loads
     `AGENTS.md` by convention; the user’s “agents.md” was interpreted as this
     file). It declares the prime directive to maintain `AI_WORKFLOW.md`, the
     required contents (development-tool docs + AI-feature docs), secret rules,
     an entry template, a pre-flight checklist, and platform context.
  2. Created `AI_WORKFLOW.md` with the required section skeleton
     (tools, prompts/config, workflow, validation, AI features, limitations,
     privacy, chronological log).
- **Files / areas touched:** `AGENTS.md` (new), `AI_WORKFLOW.md` (new)
- **Output review & validation:** Re-read the challenge PDF text and mapped each
  “Use of AI” bullet to a section in `AGENTS.md` and `AI_WORKFLOW.md`; verified
  both files exist and counted lines. No automated tests apply to docs.
- **Problems / failures / dead ends:** `webfetch` rejected the PDF
  (“Unsupported fetched file content type: application/pdf”). Resolved by
  downloading with `curl` and extracting text with `pdftotext -layout`.
- **Known limitations:** Tool/model version fields are still placeholders; the
  project idea, architecture and any runtime AI feature are undecided, so
  sections 1, 4, 5 and 6 remain to be filled in.
- **Lessons learned:** Agent-harness `webfetch` may not parse PDFs; fall back to
  shell download + text extraction. OpenCode’s instruction file is `AGENTS.md`
  (uppercase).
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 11:40 — Explored deliverables for a system-component submission

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** websearch (web), shell (`find`, `ls`), read, write, edit
- **Goal:** Determine how the hackathon deliverables change if the submission
  is a system component rather than a plain app, and capture it as a planning
  document.
- **Prompt(s) / instructions that mattered:**
  > “Explore the deliverables. If we were to add a system component, how would
  > the deliverables look?”
- **Approach:** Confirmed the repo is greenfield (only `AGENTS.md` and
  `AI_WORKFLOW.md`). Researched OpenHarmony/HarmonyOS packaging and component
  models via web search, then mapped each of the 7 required deliverables to a
  system-component variant. Produced `docs/DELIVERABLES.md` covering: the
  baseline deliverables; a spectrum of "system component" options (app + system
  APIs, ExtensionAbility, native NAPI, privileged/system app, true
  SystemAbility); a deliverable-by-deliverable delta table; a concrete artifact
  tree; signing/ACL/full-SDK prerequisites; verification evidence; a submission
  checklist; and open decisions.
- **Files / areas touched:** `docs/DELIVERABLES.md` (new), `AI_WORKFLOW.md`
- **Output review & validation:** Cross-checked every deliverable against the
  challenge text extracted earlier. Verified the key technical claims against
  OpenHarmony documentation sources: `ServiceExtensionAbility` is system-app
  only (full SDK + `AllowAppUsePrivilegeExtension`),
  `AppServiceExtensionAbility` is third-party-implementable from API 20 but
  needs ACL `ohos.permission.SUPPORT_APP_SERVICE_EXTENSION`, true SystemAbility
  depends on `sa_profile`/`samgr` and system image build, and HAP/HSP/HAR are
  the installable/shared package types. No automated tests apply to a planning
  doc. No code was modified.
- **Problems / failures / dead ends:** No functional failures. Some search
  results were in Chinese; used the official English OpenHarmony docs mirrors
  to confirm details.
- **Known limitations:** The document is a plan, not a validated build.
  Emulator-vs-device capability differences and exact signing-profile
  requirements still need hands-on confirmation with the target SDK.
- **Lessons learned:** A true SystemAbility requires rebuilding the system
  image and therefore conflicts with the challenge's “without modifying the
  system itself”; the compliant path is an installable HAP using
  ExtensionAbility and/or a native NAPI module, with system signing only as a
  documented stretch goal.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 11:36 — HarmonyOS/OpenHarmony CLI toolchain + emulator setup (Arch Linux)

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** shell (`curl`, `aria2c`, `unzip`, `pacman`, `qemu-system-x86_64`,
  `hvigorw`, `ohpm`, `hdc`), websearch, webfetch, read, write, edit
- **Goal:** Provision a working HarmonyOS/OpenHarmony development environment on
  this Arch Linux machine (the DevEco Studio IDE is not available on Linux),
  build a real `.hap`, and find a way to see a GUI (previewer or emulator).
- **Prompt(s) / instructions that mattered:**
  > “Set up harmony os development enviroment on this computer.”
  > “Do not pull open harmony to my dotfiles. Let's start now!”
  > “Can we run the emulator. Research what Oniro is.”
  > “Can I at least see the GUI?”
- **Approach:**
  1. **Reconnaissance.** Confirmed Arch Linux x86_64, AMD Ryzen 7 260, 30 GB RAM,
     744 GB free, Java + Node present; `/dev/kvm` available. Huawei's official
     DevEco Studio IDE ships for Windows/macOS (a community Arch repack exists),
     but the **HarmonyOS Command Line Tools for Linux** are available.
  2. **Toolchain install (no Huawei account).** Downloaded the official
     `commandline-tools-linux-x64-5.1.0.840.zip` from the public Huawei mirror
     `repo.huaweicloud.com/harmonyos/ohpm/5.1.0/`, verified its SHA-256, extracted
     to `~/ohos/command-line-tools`, and repaired the Mac-style 0700/0500
     permissions. Wrote a self-contained `~/ohos/env.sh` (per the user's request,
     **no shell dotfiles were modified**) plus `~/ohos/npmrc.template` and
     `~/ohos/README.md`. Installed system deps `jdk-openjdk` and
     `libxcrypt-compat` via pacman.
  3. **Verified the toolchain.** `ohpm 5.1.3`, `hvigor 5.18.5`, `hdc 3.1.0e`,
     `codelinter 5.1.140`, bundled Node v18.20.1; SDK = HarmonyOS 5.1.0,
     API 18 (includes `openharmony` + `hms`).
  4. **Built a `.hap`.** Scaffolded a minimal API-18 Stage-model ArkTS app
     (`~/ohos/projects/HelloWorld`) and built
     `entry/build/default/outputs/default/entry-default-unsigned.hap`
     (`BUILD SUCCESSFUL`). Discovered hvigor requires a project-local `.npmrc`
     mapping the `@ohos` scope to `https://repo.harmonyos.com/npm/`.
  5. **GUI investigation — previewer (dead end).** Found a native Linux
     `Previewer` binary in the SDK; supplied a compatibility shim for the missing
     `libshared_libz.so` and reverse-engineered its CLI args. The `-d`/run path
     is a compile-time stub returning `Linux is not supported`; the non-`d` path
     creates a real Window + RS surface + render thread but then dies with
     `std::system_error: Owner died`. Conclusion: Huawei's Linux previewer is an
     unfinished build and is not usable without IDE orchestration.
  6. **GUI investigation — Oniro emulator.** Researched **Eclipse Oniro**: a
     vendor-neutral, open-source **downstream distribution of OpenHarmony**
     (Eclipse Foundation + OpenAtom Foundation; members incl. Huawei, Linaro,
     Bosch). Its emulator is QEMU/x86_64/KVM with prebuilt images. Downloaded
     `oniro_emulator.zip` (1.45 GB) from
     `github.com/eclipse-oniro4openharmony/device_board_oniro` (GitHub throttled
     `curl` to ~740 KB/s; switched to `aria2c -x16` which hit ~54 MiB/s),
     extracted to `~/ohos/emulator/oniro/images`, and installed
     `qemu-system-x86`, `qemu-ui-gtk`, `qemu-ui-sdl`,
     `qemu-hw-display-virtio-gpu-pci`, `qemu-audio-pipewire`.
  7. **Emulator debugging (in progress).** KVM and the guest kernel both work
     (serial boot observed). QEMU 11.1.1 segfaults when instantiating
     `virtio-gpu-pci`; isolated this to the missing base module package
     `qemu-hw-display-virtio-gpu` (the shipped `-pci` module is only a thin
     wrapper). Awaiting that install to retry the SDL window.
- **Files / areas touched:** `~/ohos/` (env.sh, README.md, npmrc.template,
  command-line-tools/, samples/HelloWorld, projects/HelloWorld, emulator/),
  `AI_WORKFLOW.md`. No changes inside this git repository except this entry.
- **Output review & validation:** SHA-256 of the toolchain zip verified; all
  tools ran with `--version`; a real `.hap` was produced by `hvigorw
  assembleHap` (exit 0); the Oniro kernel boot was observed on the QEMU serial
  console; the `virtio-gpu-pci` segfault was reproduced deterministically.
- **Problems / failures / dead ends:** (a) DevEco IDE unavailable on Linux;
  (b) Linux previewer unusable (missing lib + unsupported run path + crash);
  (c) unused/unsupported previewer data loss on a partial extraction (re-extracted
  and verified); (d) GitHub release throttling (solved with `aria2c`);
  (e) Arch's split QEMU packaging caused a hard-to-diagnose segfault.
- **Known limitations:** The emulator window is not yet confirmed on screen. The
  bundled SDK is **API 18**, whereas the challenge requires **minimum API 20** —
  a newer SDK (HarmonyOS 6.x / OpenHarmony 6.1+) will be needed before real app
  development. HAPs are currently **unsigned**; installing on retail Huawei
  devices or publishing requires a Huawei developer account and AGC signing.
- **Lessons learned:** The official HarmonyOS CLI tools are obtainable from a
  public Huawei mirror without an account; hvigor needs a project-local
  `.npmrc` for the `@ohos` npm scope; Oniro is the practical open, account-free
  route to a running OpenHarmony GUI; Arch splits QEMU device models into
  separate packages so a `-device` can be "listed" yet still crash without its
  base module.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 11:50 — Evaluated Laya as a candidate on-device AI model

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** websearch (web)
- **Goal:** Determine the highest realistic configuration (“level”) for running the
  open-source **Laya** decision model, as a candidate AI feature for the
  submission.
- **Prompt(s) / instructions that mattered:**
  > “What is the highest level I can comfortably run LAYA AI model (if you do not
  > know what it is, search)?”
- **Approach:** Identified Laya as Convai Innovations' Apache-2.0
  *non-autoregressive* “System 1” decision model (ModernBERT-large / mmBERT-base,
  322–421M params; typed `choice`/`score`/`noul` outputs; no text generation).
  Collected the published memory/latency figures across checkpoints and
  precision formats (F16, Q8_0, Q6_K, Q4_K_M) and summarised the highest
  comfortable configuration: **F16 at ~1.1–1.4 GB peak**, which fits a ≥4 GB GPU
  or ~3 GB free RAM, with ~30–40 ms/question on a T4 and ~200–600 ms/question on
  CPU.
- **Files / areas touched:** `AI_WORKFLOW.md` (this entry only; no code)
- **Output review & validation:** Cross-checked checkpoint parameters, sizes and
  latencies against the Hugging Face model card
  (`convaiinnovations/laya`) and the published CPU/GPU benchmark tables. Noted
  that some third-party sites present inflated or inconsistent claims, so the
  official model card and benchmark pages were treated as authoritative.
- **Problems / failures / dead ends:** The user's phrase “highest level” is
  ambiguous (checkpoint vs. quantization); answered both interpretations and
  asked for the target hardware to pin an exact figure.
- **Known limitations:** **Laya is only researched, not yet adopted or
  benchmarked on our hardware.** No official ArkTS/OpenHarmony runtime exists;
  on-device use would require ONNX Runtime / OpenVINO / GGUF with quantization.
  Peak-memory figures are upstream/community measurements, not reproduced here.
- **Lessons learned:** Laya is small enough that the highest-fidelity F16 weights
  are the comfortable default on workstation-class hardware; quantization is a
  speed/space trade-off rather than a hard requirement. Any decision to use it
  must also account for the lack of a native HarmonyOS runtime.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 12:05 — Correction: clarified “highest level” means APL, not quantization

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** websearch (web), edit
- **Goal:** Record that the earlier Laya question (entry 11:50) was misunderstood,
  and capture the actual question: the **highest application privilege level
  (APL)** at which Laya can be exposed as a running service.
- **Prompt(s) / instructions that mattered:**
  > “I was not asking about the hardware limitations and quantization. What is
  > the highest **APP** level on which we can provide the LAYA model as a
  > running service?”
- **Approach / findings:** Interpreted “APP level” as OpenHarmony **Ability
  Privilege Level** (`normal` / `system_basic` / `system_core`), configured in
  the HarmonyAppProvision signing profile (`bundle-info.apl`). Established:
  `system_core` is the highest defined level but is reserved for core/preinstalled
  system apps; `system_basic` is the highest realistically self-signable level
  (debug profile edit + `app-feature: hos_system_app` +
  `AllowAppUsePrivilegeExtension` + full SDK) and unlocks
  `ServiceExtensionAbility`; `normal` is the ship-anywhere ceiling, where the
  API-20 cross-app service path is `AppServiceExtensionAbility` (needs the
  enterprise-only ACL `ohos.permission.SUPPORT_APP_SERVICE_EXTENSION`).
  `ServiceExtensionAbility` installation additionally requires an entry in the
  device's `install_list_capability.json`.
- **Files / areas touched:** `AI_WORKFLOW.md` (this correction entry)
- **Output review & validation:** Cross-checked against OpenHarmony AccessToken
  and app-provision-structure documentation, and the app-privilege configuration
  guide. No code changed.
- **Known limitations:** The `system_basic` path is debug-only and requires
  device configuration, which is in tension with the challenge's “without
  modifying the system itself.” Not yet validated on the Oniro emulator.
- **Lessons learned:** “Level” in this project context means APL, not model
  precision; keep the two axes distinct when documenting the planned AI service.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 11:41 — Oniro/OpenHarmony emulator boots with GUI

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** shell (`pacman`, `qemu-system-x86_64`, `hdc`), read, edit
- **Goal:** Finish bringing up the Oniro (OpenHarmony) QEMU emulator so the GUI
  is usable, after the earlier `virtio-gpu-pci` segfault.
- **Prompt(s) / instructions that mattered:**
  > “Done” (confirming the `qemu-hw-display-virtio-gpu` install),
  > following “Can we run the emulator. Research what Oniro is.”
- **Approach:** Confirmed the base QEMU module `hw-display-virtio-gpu.so` was now
  present alongside `-pci`/`-vga`. Re-probed the exact `virtio-gpu-pci`
  properties that previously segfaulted (`xres=360,yres=720,max_outputs=1`) —
  now exits only on timeout (no crash). Relaunched the Oniro `run.sh`
  (`qemu-system-x86_64`, KVM, SDL window) in the background.
- **Files / areas touched:** `~/ohos/emulator/` (image dir, emulator.log),
  `AI_WORKFLOW.md`
- **Output review & validation:** QEMU process alive; guest kernel `6.6.101`
  booted (serial log); `hdc tconn 127.0.0.1:55555` → `Connect OK`;
  `hdc list targets` → `127.0.0.1:55555`; `hdc shell "uname -a"` →
  `Linux localhost 6.6.101 ... x86_64 Toybox`; `ps -A | wc -l` → 231; and
  `render_service`, `foundation`, `ohos.launcher` are running (i.e. the
  OpenHarmony UI stack is up). Confirmed the fix by rerunning the failing probe.
- **Problems / failures / dead ends:** Root cause of the earlier crash was Arch's
  split QEMU packaging: `qemu-hw-display-virtio-gpu-pci` loads the QOM base type
  `virtio-gpu-base` from the separate `qemu-hw-display-virtio-gpu` package, so
  instantiating the device without it segfaulted.
- **Known limitations:** We have not yet installed our own `.hap` on it. Our
  current SDK is **API 18** while the challenge requires **minimum API 20**; and
  the build targets `runtimeOS: HarmonyOS` (needs Huawei signing), whereas this
  emulator is OpenHarmony/Oniro. Installing our app will require building with
  `runtimeOS: OpenHarmony`, signing with the SDK's OpenHarmony debug material,
  and ideally moving to an API-20 SDK.
- **Lessons learned:** The Oniro emulator is a viable, no-Huawei-account route to
  a running OpenHarmony GUI on Linux, and `hdc` over `127.0.0.1:55555` works with
  the SDK toolchain we installed.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 11:53 — Hello World app running on the Oniro/OpenHarmony emulator

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** `@oniroproject/oniro-app` 0.11.0 (Oniro App Builder CLI),
  `hvigorw`, `hdc`, `hap-sign-tool.jar`, `qemu-system-x86_64`, `openssl`,
  `keytool`; read tool to view the screenshot
- **Goal:** Build, sign, install and launch a minimal Hello World OpenHarmony
  app on the already-running Oniro emulator, and prove the GUI.
- **Prompt(s) / instructions that mattered:**
  > “Do that, I want you to run a hello world app.”
- **Approach:**
  1. Installed the Oniro CLI locally: `npm install -g --prefix ~/.local
     @oniroproject/oniro-app` (needs Node ≥ 20; the SDK's bundled Node 18
     shadowed system Node 26 and crashed it with `ReferenceError: File is not
     defined`, so Node-18 was kept off `PATH`).
  2. `oniro-app sdk list` showed `6.1 = API 23`, `6.0 = API 20`; the emulator
     reports **API 23**. To avoid a fresh download, linked our existing API-18
     SDK into the layout the CLI expects:
     `~/setup-ohos-sdk/linux/18 → ~/ohos/command-line-tools/sdk/default/openharmony`.
  3. Scaffolded a canonical OpenHarmony project with
     `oniro-app create --name HelloOniro --bundle com.example.hellooniro
     --sdk 18 --template EmptyAbility`. Its `build-profile.json5` uses
     `runtimeOS: "OpenHarmony"`, `compileSdkVersion: 18`,
     `compatibleSdkVersion: 18`.
  4. `oniro-app sign` generated the offline OpenHarmony signing material: a
     `signatures/app1-profile.p7b` provision profile signed with
     `hap-sign-tool` from the SDK's `OpenHarmony.p12` (default password
     `123456`), plus `signingConfigs` written into `build-profile.json5`.
  5. Added a project-local `.npmrc` (`@ohos` → `repo.harmonyos.com/npm/`) and ran
     `oniro-app build` → `entry/build/default/outputs/default/entry-default-signed.hap`
     (243 KB), with the `SignHap` task completing.
  6. `oniro-app app install` → `install bundle successfully`;
     `oniro-app app launch` → `start ability successfully`.
  7. Captured `oniro-app screenshot` → `screenshot.jpeg` (941×1176), which shows
     the ArkUI “Hello World” screen with status/navigation bars.
- **Files / areas touched:** `~/ohos/projects/HelloOniro/` (new project,
  `signatures/`, signed HAP, `screenshot.jpeg`), `~/setup-ohos-sdk/linux/18`
  (symlink), `AI_WORKFLOW.md`. Nothing in this git repo except this entry.
- **Output review & validation:** `ps -A` shows the running process
  `mple.hellooniro`; `aa dump -l` reports mission
  `com.example.hellooniro:entry:EntryAbility`; and the captured screenshot
  visually confirms the “Hello World” text rendering. Evidence:
  `~/ohos/projects/HelloOniro/screenshot.jpeg`.
- **Problems / failures / dead ends:** (a) `oniro-app` is incompatible with the
  bundled Node 18; solved by using system Node 26. (b) `oniro-app sign` failed
  until the SDK was exposed at `~/setup-ohos-sdk/linux/18`. (c) The unmodified
  stock debug profile is device-locked (UDID unavailable on the emulator), so we
  used the CLI's offline `profile-release` flow instead.
- **Known limitations:** The app currently targets **API 18**; the challenge
  requires **minimum API 20**, so installing the OpenHarmony **6.0 (API 20)** or
  **6.1 (API 23)** SDK should be the next step. The emulator is API 23 but the
  build SDK is API 18. This is still only a Hello World smoke test — no hackathon
  feature yet, and the project lives outside the submission repo.
- **Lessons learned:** `@oniroproject/oniro-app` is the supported, fully
  offline, no-Huawei-account inner loop for OpenHarmony (create → sign → build →
  install → launch → screenshot). It expects SDKs under
  `~/setup-ohos-sdk/linux/<api>` and JDK `java`/`keytool` on `PATH`.
- **Secrets check:** confirmed no credentials/PII added (the `sign`-generated
  keystore passwords are obfuscated values in a local, non-repo project)

### 2026-10-03 11:58 — Created `run-openharmony-app` OpenCode skill

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** OpenCode `skill` tool (loaded the built-in OpenCode guide),
  webfetch of the V2 Skills docs, write, edit, shell (`chmod`, script runs)
- **Goal:** Persist the working “build → sign → install → launch → screenshot”
  workflow for running the OpenHarmony app on the Oniro emulator as a reusable
  OpenCode skill.
- **Prompt(s) / instructions that mattered:**
  > “It works, save the workflow on how to run the app somewhere (a skill?)”
- **Approach:** Confirmed the V2 skill format/locations from
  `https://opencode.ai/v2/docs/skills/` (project skills live in
  `.opencode/skills/<id>/SKILL.md`). Created a directory-form skill with a
  `SKILL.md` plus helpers:
  - `.opencode/skills/run-openharmony-app/SKILL.md` — fixed paths/versions,
    required env exports (and the “don’t put bundled Node 18 on PATH” rule),
    detached emulator start, the `oniro-app` loop, observation commands, and
    pitfalls (`.npmrc`, SDK layout, split QEMU packages, unusable Linux
    previewer, device-locked debug profile, emulator lifecycle/screenshot timing).
  - `scripts/env.sh` — PATH/exports for `oniro-app`, `hvigorw`, `hdc`.
  - `scripts/emulator.sh` — `start|stop|status|connect|log` for QEMU.
  - `scripts/run-app.sh` — build → install → launch → screenshot.
- **Files / areas touched:** `.opencode/skills/run-openharmony-app/**`,
  `AI_WORKFLOW.md`
- **Output review & validation:** The harness advertised the new skill
  (`id: run-openharmony-app`) right after creation. Ran
  `scripts/emulator.sh status` → `running` and `connect` → `Connect OK`. Ran
  `scripts/run-app.sh ~/ohos/projects/HelloOniro` end-to-end: hvigor
  `BUILD SUCCESSFUL`, `SignHap` ok, `install bundle successfully`,
  `start ability successfully`, screenshot written (941×1176). Read the
  screenshot and confirmed the “Hello World” ArkUI screen (the app’s mission
  showed `state #FOREGROUND`).
- **Problems / failures / dead ends:** (a) The first `env.sh` omitted the SDK
  `toolchains` dir, so `hdc` was not found — fixed by adding it. (b)
  `run-app.sh` originally called `oniro-app emulator connect`, which left `hdc`
  with a stale target and produced `need connect-key` errors for install/launch
  — replaced with a direct `hdc tconn` guarded by `hdc list targets`. (c) The
  emulator process had died earlier (SDL window closed/reaped) and a screenshot
  taken immediately after launch captured the launcher instead of the app; added
  a 3s settle delay and documented both behaviours.
- **Known limitations:** The skill hardcodes this machine’s absolute paths
  (`~/ohos`, `~/setup-ohos-sdk`). It assumes the emulator images are already
  installed. It does not yet cover upgrading to an API 20+ SDK.
- **Lessons learned:** OpenCode V2 discovers project skills at
  `.opencode/skills/<id>/SKILL.md` (ID = directory name) and advertises them via
  the `description` frontmatter; helper files are resolved relative to
  `SKILL.md`.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 12:05 — Validated on-device AI feasibility on frontier Huawei phones

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** websearch, webfetch, shell (inspected the installed SDK’s `.d.ts`
  declarations), write, edit
- **Goal:** Determine whether a Huawei phone can run inference **locally** — both
  small “classical ML” models and small LLMs / decision models such as LAYA — and
  document the relevant device capabilities.
- **Prompt(s) / instructions that mattered:**
  > “Let's be real, the whole idea is based for Huawei mobile devices. Let's
  > validate frontier Huawei phones for running local inference (both for small,
  > dedicated models of classical ML and for small LLMs/ models *like* LAYA),
  > what are the device capabilities”
- **Approach:**
  1. Researched current flagships: Mate 80 / 80 Pro / 80 Pro Max / RS (Nov 2025,
     HarmonyOS 6), Pura 90 (2026), Mate X7; SoCs Kirin 9020 / 9030 / 9030 Pro;
     12–16 GB RAM.
  2. Confirmed the NPU is Huawei **Da Vinci**; Kirin 9030 changed the NPU block
     from *Lite + Tiny* to *Lite + two Tiny* (SemiAnalysis). Huawei publishes no
     TOPS figures.
  3. Established the developer stack: **MindSpore Lite** (`@ohos.ai.mindSporeLite`)
     with **NNRt** (`NNRTDeviceType.CPU/GPU/ACCELERATOR`) to the Kirin NPU, plus
     the **HiAI DDK** for NPU; `.ms` models converted from ONNX/TF/TFLite/Caffe.
  4. Found MindSpore Lite advertises a **device-side LLM inference module for the
     Kirin NPU** with a model zoo (Qwen2/2.5/3/3.5 0.5B–9B, VLMs, ASR/TTS,
     embeddings/rerankers, YOLO/SAM).
  5. Inspected the locally installed SDK (API 18) to verify the available API
     surface: `@kit.MindSporeLiteKit`, `@ohos.data.intelligence` (on-device
     text/image embeddings), `MultimodalAwarenessKit`, and the HMS-only AI kits
     (`NaturalLanguageKit`, `SpeechKit`, `VisionKit`, `CoreVisionKit`,
     `IntentsKit`, `@hms.ai.*`).
  6. Identified **LAYA** as `convaiinnovations/laya`, a non-autoregressive
     decision/routing model (ms-scale), i.e. small-dedicated-model class.
- **Files / areas touched:** `docs/ONDEVICE_AI_VALIDATION.md` (new),
  `AI_WORKFLOW.md`
- **Output review & validation:** Grounded the API claims in the **primary
  source** — the installed SDK’s `@kit.*.d.ts` and `@ohos.ai.*` declarations —
  and cross-checked the runtime claims against MindSpore Lite’s official docs and
  README. Explicitly marked unverified items (Kirin NPU TOPS, exact RAM of the
  Pro Max, LAYA’s parameter count/runtime). No code executed; this is desk
  validation, since no physical Huawei device is attached.
- **Problems / failures / dead ends:** The Huawei developer-forum page for
  MindSpore Lite did not fetch (empty response); relied on the official
  MindSpore docs and the local SDK instead. Huawei does not publish NPU TOPS, so
  performance cannot be validated without hardware.
- **Known limitations:** No hardware benchmark (tokens/s, ms/inference) was
  possible. The emulator is CPU-only and lacks HMS AI kits, so an NPU-class demo
  needs a real Huawei phone. NPU/HiAI access may require a Huawei developer
  account. Model conversion/operator support is model-dependent.
- **Lessons learned:** On-device small-LLM inference on Huawei silicon is a
  first-class, documented path (MindSpore Lite + Kirin NPU), not a hack. The
  strongest split is: OpenHarmony = MindSpore Lite + embeddings (works on the
  emulator, CPU); HarmonyOS = those **plus** the closed HMS AI kits and the
  agent/Intents framework.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 12:29 — Diagnosed and fixed Firefox right-click (context menu) on Hyprland/Wayland

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** shell (`hyprctl`, `pgrep`, `grim`, `strings`, `sqlite3`/session DB
  inspection), grep, read, write, edit, websearch. No MCP servers or skills used.
- **Goal:** Find out why right-click / the context menu does not work in Firefox
  on this machine and fix it.
- **Prompt(s) / instructions that mattered:**
  > “Right mouse click on firefox does not work, check my system try to fix this”
- **Approach:**
  1. Profiled the environment: Arch Linux, Hyprland 0.56.2 on Wayland, Firefox
     156.0.1 running **native Wayland** (`xwayland: 0`, `MOZ_ENABLE_WAYLAND=1`),
     hybrid NVIDIA RTX 5050 + AMD iGPU (driver 615.71.09), single active output
     `eDP-1` 1920×1200 @ scale 1.
  2. Ruled out the obvious local causes: no plain (modifier-less) mouse bind in
     `~/.config/hypr/hyprland.lua` (only `SUPER + mouse:272/273`), no input
     remappers (`keyd`/`xremap`/`input-remapper`), no Firefox extensions,
     `policies.json`, `userChrome.css`, or `dom.event.contextmenu.enabled=false`.
  3. Read the Firefox profile at `~/.config/mozilla/firefox/h9zymoq0.default-release/`
     (note: **not** `~/.mozilla`) — `prefs.js` had no `widget.wayland.*` override.
  4. A screenshot showed a **previous session had been changing the monitor scale
     live** (`~/.config/hypr/scale.sh` cycles the focused monitor through
     1.0 → 1.2 → 1.5 via `hyprctl eval` to fix “overly large UI scaling”).
  5. Searched the Mozilla bug tracker and confirmed the match:
     - Firefox **146 enabled `widget.wayland.fractional-scale.enabled` by default**
       (Bug 1997907) — so it is `true` on this 156 build.
     - Fractional-scale support breaks **menus and context menus** on
       Wayland/Hyprland (Bugs 1849109, 1881086, 1891405), and Firefox does **not**
       handle scale changes that happen mid-session (Bug 2049137) — it needs a
       Firefox restart / new window. Multiple reports: “When I disable
       `widget.wayland.fractional-scale.enabled` everything is working correct.”
     - Logically: the prior scale changes left Firefox’s popups mis-computed, so
       right-click appeared to do nothing.
  6. Applied the documented workaround: created
     `~/.config/mozilla/firefox/h9zymoq0.default-release/user.js` setting
     `widget.wayland.fractional-scale.enabled = false`, then gracefully restarted
     Firefox (`pkill -TERM`; relaunched with `MOZ_ENABLE_WAYLAND=1`).
- **Files / areas touched:**
  `~/.config/mozilla/firefox/h9zymoq0.default-release/user.js` (new),
  `AI_WORKFLOW.md`.
- **Output review & validation:** After restart, `prefs.js` contains
  `user_pref("widget.wayland.fractional-scale.enabled", false);`, confirming
  Firefox read `user.js`; `hyprctl clients` shows Firefox running on Wayland and a
  `grim` screenshot confirms the window and restored tabs render. **Caveat:** the
  machine has no input-injection tool (`ydotool`/`wtype`/`evtest` absent, no
  sudo), so I could not synthesise a right-click myself — the user must confirm
  the menu now appears. Note the panel is currently at scale 1.0, where the pref
  has no visual effect.
- **Problems / failures / dead ends:** (a) `sudo` is password-protected and
  `libinput`/`evtest`/`ydotool` are not installed, so direct input observation and
  synthetic clicks were impossible. (b) `hyprctl dispatch exec firefox` failed —
  this Hyprland build’s `dispatch` expects Lua syntax; launched Firefox directly
  with the Wayland environment instead. (c) `/home/.../.mozilla` does not exist;
  the profile lives under `~/.config/mozilla` on this system.
- **Known limitations:** At non-integer Hyprland scales (1.2/1.5) Firefox will now
  render at an integer scale and be downscaled, i.e. slightly softer than native
  fractional scaling. `user.js` overrides `about:config` on every start; to
  re-enable crisp fractional scaling, remove the pref and instead **restart
  Firefox after each `scale.sh` change**. No `about:support` dump was captured.
- **Lessons learned:** On Wayland, a Firefox context-menu failure can be a
  **scale/protocol** problem rather than an input or compositor-bind problem. The
  `scale.sh` helper plus Firefox 146+ default fractional scaling is a known-bad
  combination; the reliable cure is to disable
  `widget.wayland.fractional-scale.enabled` or restart Firefox after scale
  changes.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 13:36 — Validated real on-device inference (MindSpore Lite) on the emulator

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** `oniro-app` CLI, `hvigorw`, `hdc`, webfetch (OpenHarmony docs +
  model), shell, write, read (viewed the screenshot)
- **Goal:** Validate the core premise locally — run **real model inference
  on-device** in an OpenHarmony app on this machine’s CPU-only emulator — before
  committing the Windows/DevEco/account path for the final NPU demo.
- **Prompt(s) / instructions that mattered:**
  > “We could have the windows dedicated environment with an account somewhere.
  > but we need to validate the idea here.”
- **Approach:**
  1. Probed the emulator: `syscap.json` contains
     **`SystemCapability.AI.MindSporeLite`** and
     **`SystemCapability.AI.NeuralNetworkRuntime`**; `DataIntelligence` is
     **absent**, and there is no NPU accelerator (CPU only).
  2. Confirmed the SDK ships `libmindspore_lite_ndk.so` for **x86_64-linux-ohos**
     *and* aarch64 — so both the ArkTS kit and a native N-API path work on the
     emulator.
  3. Followed the official “Using MindSpore Lite for Image Classification
     (ArkTS)” guide and downloaded `mobilenetv2.ms` (11 MB) from the MindSpore
     model zoo.
  4. Scaffolded the project **in the repo** at `app/`
     (`oniro-app create --name app --bundle com.hackyeah.ondevice --sdk 18`),
     added `entry/src/main/syscap.json` declaring `SystemCapability.AI.MindSporeLite`,
     put the model in `entry/src/main/resources/rawfile/`, and wrote
     `entry/src/main/ets/pages/Index.ets` — a probe that loads the model from the
     rawfile, feeds a synthetic `[1,224,224,3]` float input, calls `predict`, and
     renders the timing + top-1 on screen.
  5. `oniro-app sign` → `build` → `app install` → `app launch`, then captured
     `hilog` and a screenshot.
- **Files / areas touched:** `app/**` (new HarmonyOS project),
  `~/ohos/models/mobilenetv2.ms`, `AI_WORKFLOW.md`
- **Output review & validation:** `hilog` shows the full stack working —
  `LoadModelAndCompileByBuf: Successfully loaded model from buffer`,
  `Has successfully compiled the graph`, and the app’s own
  `A0ff00/AIProbe: predict success in 191 ms, outLen 500, top1 349`. The
  screenshot (`app/probe.jpeg`) shows **“INFERENCE OK (191 ms)”** with
  `in=[1,224,224,3] out=500`. **This is direct evidence that on-device inference
  works on the emulator.**
- **Problems / failures / dead ends:** The emulator process had died/disconnected
  between sessions again and was restarted (documented in the skill).
  `@ohos.data.intelligence` is not implemented on this Oniro image, so the
  built-in embedding API is not available here. Build emitted expected
  ArkTS warnings that `predict`/`getData` are “not supported on all devices”
  (they are gated by the syscap we declared).
- **Known limitations:** Inference is **CPU-only** on the emulator (no NPU);
  input is synthetic (not a real image); the project targets **API 18** while the
  challenge requires **≥ 20**; and mobilenetv2 is a generic CNN, not the actual
  product model. LAYA/small-LLM behaviour is not yet measured.
- **Lessons learned:** The core idea de-risks locally: MindSpore Lite is present
  and functional on the Oniro emulator, and the **same ArkTS code path** selects
  `NNRTDeviceType.ACCELERATOR` (Kirin NPU) on a real Huawei device. We can build
  and validate the app architecture here, then flip to NPU on the Windows/HMS
  path.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 14:00 — Pulled newest `main` and validated the Hello World app on the emulator

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** `git` (fetch/merge), `oniro-app` 0.11.0 (`sdk install 6.1`, `sign`,
  `build`, `app install/launch`, `screenshot`), `hdc`, `ohpm`, `npm`, bundled
  `hvigorw` 5.18.5, npm `@ohos/hvigor`/`@ohos/hvigor-ohos-plugin` 6.24.5,
  QEMU Oniro emulator, `read` (viewed the screenshot)
- **Goal:** Pull the newest `main` from the team remote and validate that the
  Hello World app committed there opens on the Oniro/OpenHarmony emulator.
- **Prompt(s) / instructions that mattered:**
  > “Pull the newest main. Validate you can open the hello world app set up
  > there on the emulator.”
  > “Minimal API is API 20” (correction to the earlier “minimum API 23”).
- **Approach:**
  1. Fetched `origin`; discovered a new **unrelated-history** `origin/main`
     commit `d7af954 "init"` containing a `HuwaweiChallenge/` Stage-model ArkTS
     project (`com.example.huwaweichallenge`) plus a root `README.md`. The local
     `main` was our earlier baseline `14ceffb`.
  2. Integrated it with `git merge origin/main --allow-unrelated-histories`
     (clean, no conflicts) → merge commit `b3d171c`.
  3. Started the Oniro emulator (QEMU/KVM) and installed the matching **SDK
     6.1 = API 23** via `oniro-app sdk install 6.1` (lands in
     `~/setup-ohos-sdk/linux/23`). Emulator reports API 23; `hdc` over
     `127.0.0.1:55555` connected.
  4. Attempted the team project's build. It repeatedly **deleted the entire
     project directory** and failed at packaging. Reproduced outside git in
     `/tmp/opencode/hc*`, pinpointed it to
     `:entry:default@PackageHap` followed by `entry/oh-package.json5` “File is
     not exist”. The bundled hvigor is **5.18.5 (API 18 era)** while the project
     builds against the API 23 SDK.
  5. Tried to force hvigor 6.x by editing `hvigor/hvigor-config.json5`
     (`@ohos/hvigor-ohos-plugin: 6.24.5`), installing the 6.24.5 engine from
     `repo.harmonyos.com/npm`, and running the engine directly. The build then
     progressed further (correct `modelVersion: 6.0.0` needed) but the
     destructive wipe at packaging **still occurred**, so it is not purely a
     hvigor-version issue.
  6. Tested `app_packing_tool.jar` in isolation (API 23 and API 18 jars) with
     `--force true`: it does **not** delete unrelated files, so the tool itself
     is not what wipes the tree.
  7. **Validation workaround:** built the *same* project source in a scratch copy
     against the known-good **API 18** toolchain (set
     `compileSdkVersion`/`compatibleSdkVersion` to 18), signed, installed and
     launched it on the emulator.
- **Files / areas touched:** `/home/s3r10us3r/hackyeah2026` (merge commit on
  `main`), `/tmp/opencode/hc18` (scratch API-18 build), `/tmp/opencode/hello.jpeg`
  (screenshot), `~/setup-ohos-sdk/linux/23` (SDK install). The repo’s
  `HuwaweiChallenge/` source was restored with `git restore` after each
  destructive build attempt; working tree is clean.
- **Output review & validation:** `oniro-app app install` →
  `install bundle successfully`; `oniro-app app launch` → `start ability
  successfully`; `aa dump -l` shows mission
  `com.example.huwaweichallenge:entry:EntryAbility` with `state #FOREGROUND`.
  The screenshot `hello.jpeg` (941×581) shows the ArkUI **“Hello World”** screen.
  **This validates that the app opens on the emulator**, albeit from an API 18
  compile of the same source.
- **Problems / failures / dead ends:** (a) `origin/main` and local `main` had
  unrelated histories — resolved with `--allow-unrelated-histories` merge.
  (b) The **API 23 build is destructive** with the locally available toolchain
  and does not produce a HAP. (c) The public Huawei mirror only hosts
  command-line-tools **5.1.0 (API 18)**; there is no public Linux
  command-line-tools 6.x, so a matching API 20/23 `hvigor` cannot simply be
  fetched. (d) Forcing npm hvigor 6.24.5 required bypassing the 5.18.5 wrapper
  (which force-links its own engine); it built further but still wiped the tree.
- **Known limitations:** The app was **not** built against API 20/23 locally;
  the running HAP is an **API 18** compile. Root cause of the API 23 wipe is not
  fully identified (hvigor task path resolution, not the packing tool). The
  requirement is now recorded as **minimum API 20**, while the team project
  currently declares `compileSdkVersion`/`compatibleSdkVersion` 23.
- **Lessons learned:** A mismatch between the SDK a project targets (API 23) and
  the bundled build tooling (hvigor 5.18.5, API 18) can cause **silent
  destructive behaviour**, so always keep project sources recoverable
  (git-restore, build in scratch copies). The Oniro emulator + API 18 toolchain
  remains the reliable local inner loop; API 20/23 needs matching 6.x
  command-line tools.
- **Secrets check:** confirmed no credentials/PII added

### 2026-10-03 14:08 — Resolved API 20+ build: root cause was Java 27, fixed with JDK 17

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** `oniro-app` 0.11.0 (`sdk install 6.0/6.1`, `sign`, `build`,
  `app install/launch`, `screenshot`), `ohpm`, bundled `hvigorw` 5.18.5, `hdc`,
  Temurin **JDK 17**, `aria2c`, QEMU Oniro emulator, `read` (viewed screenshot)
- **Goal:** Do everything required to build, sign, install and run the team's
  Hello World project through **API 20+** (instead of the API 18 workaround).
- **Prompt(s) / instructions that mattered:**
  > “Do all the steps required to run it through API 20+.”
  > “Minimal API is API 20.”
- **Approach:**
  1. Installed SDK **6.0 (API 20)** and confirmed a clean API 20 build succeeds
     (`compileSdkVersion`/`compatibleSdkVersion` = 20) — no wipe, HAP produced.
  2. Root-caused the earlier API 23 destruction: instrumented Node `fs`/`fs-extra`
     (no deletes logged) and then reproduced the wipe directly by running the
     API 23 `app_packing_tool.jar` with the exact `PackageHap` args. The tool
     **deletes its own current working directory** on failure; `hvigor` spawns it
     with `cwd = project root`, so the project is destroyed. Running it from a
     sandbox cwd made the same build succeed — confirming the tool (not hvigor)
     is at fault.
  3. Hypothesis: Java 27 incompatibility. The API 23 packing tool uses
     `sun.misc.Unsafe`/fastjson2 and is built for the JDK DevEco bundles. There
     is no JDK 17 on the system (only `java-27-openjdk`), so I downloaded Temurin
     **JDK 17.0.20.1** to `~/ohos/jdk/jdk-17.0.20.1+1` with `aria2c`.
  4. Re-ran the API 23 build with JDK 17 (no wrapper/hack): **BUILD SUCCESSFUL**,
     project intact, `SignHap` ok, `entry-default-signed.hap` (247 KB) produced.
  5. Installed and launched the API 23 HAP on the emulator and captured a
     screenshot.
- **Files / areas touched:** `~/ohos/jdk/jdk-17.0.20.1+1` (new JDK),
  `~/setup-ohos-sdk/linux/20` (new SDK), `HuwaweiChallenge/` (signed HAP built;
  `build-profile.json5` signingConfigs reverted before any commit),
  `.opencode/skills/run-openharmony-app/` (`env.sh` + `SKILL.md` updated to
  require JDK 17), `AI_WORKFLOW.md`. Temporary Node/`fs-extra` instrumentation in
  `~/ohos/command-line-tools` was reverted.
- **Output review & validation:** `oniro-app build` → `BUILD SUCCESSFUL`;
  `oniro-app app install` → `install bundle successfully`; `oniro-app app launch`
  → `start ability successfully`; `aa dump -l` shows
  `com.example.huwaweichallenge:entry:EntryAbility` `state #FOREGROUND`.
  HAP `module.json`: `minAPIVersion: 23`, `targetAPIVersion: 23`,
  `compileSdkVersion: 6.1.0.31`. Screenshot `/tmp/opencode/hello_api23.jpeg`
  shows the ArkUI **“Hello World”** screen. The earlier API 18 build
  (`/tmp/opencode/hello.jpeg`) is superseded.
- **Problems / failures / dead ends:** (a) The exact failure mode was a
  destructive SDK bug, not a config error — misdiagnosed at first as an hvigor
  version mismatch; forcing npm hvigor 6.24.5 did **not** fix it. (b) API 23
  under Java 27 wipes the project; API 20 under Java 27 did **not** (so the bug
  is specific to the API 23 packing tool + Java 27). (c) Stale `oh_modules`
  symlinks from earlier builds broke `CompileArkTS`; fixed with `ohpm install`.
- **Known limitations:** API 20+ builds require JDK 17 on this machine (system
  default is Java 27). The team project remains declared at API 23 (satisfies the
  API 20 minimum); no project source changes were needed. `oniro-app sign`
  writes an (obfuscated) `signingConfigs` block with passwords into
  `build-profile.json5`; that change was **reverted** and must not be committed.
- **Lessons learned:** When a build tool “eats” the project, suspect the
  external packing tool and its **JVM version**, not just hvigor. The API 23
  `app_packing_tool.jar` needs **JDK 17** (DevEco’s bundled JBR), not the latest
  JDK. Keep sources in git and build in scratch copies while diagnosing.
- **Secrets check:** confirmed no credentials/PII added (the obfuscated signing
  passwords were reverted and never committed)

### 2026-10-03 14:23 — Designed the on-device safety copilot (`DESIGN.md`)

- **Agent / model:** OpenCode agent running `deepseek/deepseek-flash`
- **Tooling:** `read` (viewed `init_design.md`), `grep`/`shell` (inspected the
  API 23 SDK `.d.ts` files), `websearch` (DevEco emulator, Live View Kit),
  `question` (iterative design Q&A), `write`, `git` (branch + commits)
- **Goal:** Turn the rough `init_design.md` into a precise design document for a
  HarmonyOS/OpenHarmony app, correcting the on-the-fly decisions and
  inaccuracies.
- **Prompt(s) / instructions that mattered:**
  > “There are several on-the-fly design decisions and inaccuracies that I made
  > here. Ask me questions and we will arrive on a final design.”
  > Selected answers: unified copilot; accessibility service; notification-first
  > with a Live View adapter as stretch; emulator baseline; LAYA + embedding RAG;
  > consent = always-on scams + per-app opt-in + cloud-by-consent; mock apps for
  > the demo; keep CRITICAL/DANGEROUS/SAFE; min/compile **API 20**; name TBD.
- **Approach:**
  1. Read `init_design.md`; listed the concrete inaccuracies (a normal HAP cannot
     silently screenshot/read other apps; overlays and Smart Island are not
     third-party; LAYA is a classifier, not a generative LLM; WhatsApp is absent
     on HarmonyOS NEXT; inconsistent consent; cloud contradicts on-device).
  2. **Grounded every feasibility claim in the installed SDK** (API 23 `.d.ts`):
     `@ohos.application.AccessibilityExtensionAbility` +
     `AccessibilityExtensionContext` (`getWindowRootElement`, `injectGesture`,
     capabilities `retrieve|gesture|keyEventObserver|zoom|touchGuide`) are
     third-party-available; `window.TYPE_FLOAT` needs
     `ohos.permission.SYSTEM_FLOAT_WINDOW`; `NotificationSystemLiveViewContent`
     is documented “Only system applications are supported”;
     `@ohos.data.intelligence` exists in the SDK but is absent on the Oniro
     image.
  3. Researched the DevEco **Windows HarmonyOS emulator** and **Live View Kit**:
     the emulator exists but needs `runtimeOS: HarmonyOS` + AGC signing, and Live
     View on the emulator is unverified — hence notification-first.
  4. Ran a multi-round `question` Q&A to lock scope, content access, alert
     surfaces, model stack, escalation, consent, demo sources, verdict model, API
     level and the Smart-Island strategy.
  5. Wrote `DESIGN.md` (overview, personas, platform feasibility table,
     architecture/data-flow, acquisition/triggers, detection, RAG/escalation,
     alert UX, consent/privacy/threat model, permissions, demo plan, risks,
     milestones, and a LAYA appendix).
- **Files / areas touched:** `DESIGN.md` (new, on branch `design/app-spec`);
  `main` also received `15725a1` (skill + AI_WORKFLOW + project `.npmrc`/lockfile
  commit). `init_design.md` left untracked as the user's working draft.
- **Output review & validation:** The design branch adds **exactly one file**
  relative to `main` (`git diff --stat main..design/app-spec` → `DESIGN.md`);
  every platform claim cross-checked against the API 23 `.d.ts`. No code/build
  tests apply to a design document.
- **Problems / failures / dead ends:** The draft's central UX (Smart Island +
  overlay over another app) is **not achievable by a third-party HAP**; this was
  the main correction. LAYA's exact scam accuracy and `.ms` conversion remain
  assumptions, so the design keeps a model-agnostic `classify()` and a fallback
  classifier.
- **Known limitations:** Product name/bundle id are placeholders; v1 language,
  embedding model, on-device LLM, fine-tuning dataset, and cloud provider are
  open. Live View and NPU paths are device/stretch and unverified.
- **Lessons learned:** On OpenHarmony, "read the screen" is an accessibility
  capability, while "draw over other apps" and Smart Island are system-only —
  verify against the SDK `.d.ts` before designing UX. Keep the model interface
  swappable when the model's HarmonyOS runtime is unproven.
- **Secrets check:** confirmed no credentials/PII added

<!-- END WORK LOG -->
