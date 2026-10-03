# AI Workflow — developer `s3r10us3r`

Per the project's updated agent rules (`HuwaweiChallenge/AGENTS.md`), AI-assisted
development is documented **per developer**. This is the workflow log for git
user **`s3r10us3r`**. Entries are **newest-first**, each starts with a timestamp,
and each is kept deliberately compressed (highlights only — no transcripts).

> Rules: see [`HuwaweiChallenge/AGENTS.md`](./HuwaweiChallenge/AGENTS.md) and the
> repo [`AGENTS.md`](./AGENTS.md). This file holds only this developer's entries.

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
