# AGENTS.md — Instructions for All AI Agents

This file is the canonical instruction set for **every** AI agent, coding
assistant, subagent, MCP-backed tool, or automated workflow that touches this
repository. Read it before doing any work and follow it for the entire session.

---

## 1. Project context (why this matters)

We are building a submission for the hackathon:
**“A standout system feature or an app for a new mobile operating system.”**

- **Target platform:** HarmonyOS, OpenHarmony, or Oniro.
- **Minimum API level:** API 20 or later (declare API 20 as the minimum where
  applicable).
- **Implementation options:** native ArkTS/ArkUI or C/C++ platform APIs; a
  supported cross-platform framework (e.g. React Native for OpenHarmony / RNOH)
  **that includes the OpenHarmony/HarmonyOS target and native bridge**; or
  OpenHarmony/Oniro system frameworks and source-level build tools.
- **Required theme alignment:** the solution must clearly live in one (or more)
  of these three areas:
  1. **Intelligent Experiences** — AI agents, contextual awareness,
     personalization, intelligent interaction, on-device AI.
  2. **Spatial Experiences** — spatial UI, 3D content, immersive media, sensing,
     positioning, new interaction forms.
  3. **Human-Centric Technology** — accessibility, digital wellbeing, inclusive
     design, education, cultural experiences, responsible technology.
- **Must run** on an OpenHarmony/HarmonyOS emulator or compatible physical
  device, with reproducible setup, build, and launch instructions.
- **Must demonstrate** real use or improvement of at least one platform, device,
  or system capability.
- **Deliverables:** public repo; reproducible build/install/launch instructions;
  a working `.hap` package; a recorded demo; a concise architecture and
  implementation description; `AI_WORKFLOW.md`; plus additional AI integration
  documentation if the submission includes an AI feature.

Keep these constraints in mind in every decision. Do not introduce features,
dependencies, or permissions that are not justified.

---

## 2. Reference — what `AI_WORKFLOW.md` should contain (challenge rules)

These are the challenge's requirements for the deliverable. The file is scored
on **transparency and reproducibility**, so completeness beats polish.

### A. Development tools — REQUIRED for this project

Because we use AI-assisted development tools, document **all** of the following:

- **All AI models, coding agents, MCP servers, Agent Skills, and other
  AI-assisted tools used.** For each: name, provider/version (or “unknown”),
  and what it was used for.
- **The main prompts, reusable instructions, and relevant configuration.**
  Include the prompts that materially shaped the output, plus any rules files,
  agent configs, skills, or MCP configuration. Paste them verbatim where
  practical (see secret rules in §3/§4).
- **The workflow** from ideation and architecture through implementation,
  testing, and debugging.
- **How generated output was reviewed, tested, and validated** — who/how it was
  checked, what tests or manual verification were run, what evidence exists.
- **Known limitations, unsuccessful approaches, and lessons learned.** Be honest;
  failed attempts are part of the record.

Prompts and tool usage should be documented **as fully as reasonably possible**.

### B. AI features — documented separately, not in `AI_WORKFLOW.md`

`AI_WORKFLOW.md` covers the **development workflow and tools only**. If any part
of the product uses an AI model or service at runtime, document it in the
project's AI integration document (e.g.
[`AI_INTEGRATION.md`](./AI_INTEGRATION.md))
and link that document from `AI_WORKFLOW.md`. Per feature, document:

- **The model or service** used (name, provider, version).
- **The inference flow** (inputs, preprocessing, where inference runs, outputs,
  fallbacks).
- **Data handling** (what data is collected, stored, or transmitted; where).
- **Limitations** (accuracy, latency, language coverage, device constraints).
- **The validation approach** (how correctness and failure modes were tested).
- **Privacy considerations** (on-device vs. remote, consent, retention, PII).

### C. Linking

`AI_WORKFLOW.md` must link the AI integration document so a reader can find the
feature's model, inference, data handling, limitations, validation and privacy.

---

## 3. Non-negotiable content rules

1. **No secrets. Ever.** Before writing to `AI_WORKFLOW.md` (or committing
   anything), remove API keys, tokens, passwords, credentials, cookies, private
   URLs, `.env` values, personal data, and any other confidential information.
   Replace them with `<REDACTED>` and, where useful, an environment-variable
   name such as `${MODEL_API_KEY}`.
2. **No fabricated entries.** Record only what actually happened. Never claim a
   test passed, a tool was used, or a result was observed unless it is true.
   If something is unknown, write “unknown”.
3. **Attribute tools precisely.** Name the exact model/agent (e.g.
   “OpenCode agent running `deepseek/deepseek-flash`”), not just “the AI”.
4. **Timestamp entries.** Use ISO-8601 dates (`YYYY-MM-DD`). Add the time
   (`YYYY-MM-DD HH:MM`) when multiple entries share a day.
5. **Keep it reproducible.** A reader should be able to follow the recorded
   workflow and reproduce our results.
6. **Append, don’t overwrite.** Preserve history. If an earlier entry is wrong,
   add a correction entry that references it.

---

## 4. Configuration & prompt hygiene

- If a tool reads configuration (agent configs, `opencode.jsonc`, MCP config,
  skills), summarize **the relevant parts** rather than pasting large files.
  Reference the path, then quote the parts that shaped behavior.
- Store secrets in environment variables or a git-ignored local file. Never put
  them in tracked files, prompts, or the workflow file.
- Before committing, run a quick sanity check for accidentally included
  credentials. If one is found, rotate it and remove it from history if needed.

---

## 5. Pre-flight checklist (run before finishing any task / PR)

- [ ] UI changes were validated on the emulator (screenshot/drive) and iterated
      (see §11), or handed to the developer if requested.
- [ ] After changing the app, the new build was installed on the
      emulator/device (see §12).
- [ ] If an AI feature is involved: model/service, inference flow, data
      handling, limitations, validation, and privacy are documented (see §2).
- [ ] No secrets, credentials, or personal data were added anywhere.
- [ ] Only task-relevant files were staged/committed — no editor/IDE configs,
      generated output, large binaries, or unrelated prior work (see §7).

---

## 6. General working agreements

- **Prefer the platform.** Use real OpenHarmony/HarmonyOS capabilities
  (system services, APIs, distributed features, on-device AI, sensors,
  accessibility) rather than cross-platform code that would run unchanged
  anywhere.
- **Keep changes modular and readable.** Add reasonable error handling and
  input validation. No unnecessary permissions or risky dependencies.
- **Test the key scenarios** and record the evidence (PR description or docs);
  full coverage is not required, but show that you checked your own work.
- **Document reproducibility.** Keep setup/build/launch instructions in the
  README accurate and in sync with the code.
- **When in doubt, record it.** A short honest note is always better than a gap.

---

## 7. Commit & staging hygiene — do not dump files

Stage **only** the files that belong to the current task. Never sweep the whole
working tree into a commit or PR.

- **Do not use `git add -A` / `git add .` on mixed work.** Add explicit paths,
  or review with `git add -p`, so unrelated or leftover files are not included.
- **Do not commit editor/IDE or local machine config**, e.g. `.vscode/`
  (including `.vscode/settings.json`), `.idea/`, `*.iml`, `local.properties`,
  `.DS_Store`, or shell dotfiles. Put them in `.gitignore` instead.
- **Do not commit generated output or caches**: `build/`, `.hvigor/`,
  `oh_modules/`, `*.hap`, `*.abc`, `*.log`, or screenshots that were only for
  local debugging.
- **Do not commit large binaries or model weights** (e.g. `*.ms`, `*.onnx`,
  large media) unless the task explicitly requires shipping them — **ask
  first**.
- **Secrets stay absolute**: never commit signing material or credentials
  (`signatures/`, `*.p12`, `*.p7b`, `*.pem`, keys, tokens) — see §3 and §4.
- **Keep commits and PRs scoped.** A PR must contain the work for its stated
  purpose only. If earlier local commits were never pushed, do **not** silently
  publish them as part of an unrelated PR — surface them and ask.
- **When in doubt, ask** before staging anything outside the task's scope.

---

## 8. Feature, comment & script hygiene

- **Test before you open a PR.** Every feature or fix must be built **and**
  exercised (automated where possible, plus a manual smoke check) and pass
  **before** a PR is created. The PR must state what was run and the result
  (build status, test counts). Untested work is not "done".
- **Comments stay short.** Use a single one-line file header and terse inline
  notes; explain *why*, not *what*. No large doc blocks, no commented-out dead
  code, and no per-declaration narration.
- **No scripts in the repo.** Do not commit shell scripts, Python, or other
  helper/tooling scripts unless a script is **directly required for the agent to
  run** (i.e. agent infrastructure explicitly in scope). Machine, emulator, and
  build helpers stay **local and git-ignored**. The repo holds project code,
  tests, and docs only.

---

## 9. Pull requests — humans merge, agents do not

- Agents may create branches, commit, push, and open or update pull requests.
- Agents must **never merge a PR** (nor close one) on their own. Opening a PR
  means **hand it back** to the developer for review and merge.
- Do **not** push directly to `main` (or any protected branch) unless the human
  explicitly instructs it for that specific change.
- After opening a PR, stop and report the PR link plus what was built/tested.

---

## 10. Dev-only backend — keep the remote and on-device paths in parity

The app has a dev-only **"Dev mode"** switch that routes OCR and LAY A to a host
server (`C:\guardian-devserver`, kept **outside** the repo). It exists only to
iterate quickly; the shipping product is on-device and offline.

- **The remote path and the on-device path must implement the same model schema,
  questions, and decision policy before any push/PR.** A change made only on the
  host (e.g. an edited LAY A question set or threshold) is **not "done"** until
  the on-device `.ms` is re-exported to match (`convert_laya.py`, kept out of the
  repo per §8) and re-validated. The LAY A questions are **baked into the graph**,
  so any question change always requires a re-export.
- **Never ship the remote path.** Remove `ohos.permission.INTERNET` and the
  remote/dev code before the submission build; the shipping app stays on-device
  and offline.
- **Record parity status.** Note any schema/policy change and whether the
  on-device model has been re-exported while the two paths are temporarily out
  of parity.

---

## 11. UI validation — the agent validates and iterates

- The agent **may and should** validate visual/UI behaviour itself: build,
  install, drive the emulator, take screenshots, and iterate on visual issues
  until they look right — unless the developer asks to own a specific check.
- Code-level checks (build/compile, unit tests, lint) are still expected and must
  be reported.

---

## 12. Always build & install after changing the app

- After **any** change to the HarmonyOS app, build **and install** the HAP to the
  running emulator/device before handing back — the developer must always be
  testing the newest code.
- Concretely: `hvigorw … assembleHap` (build from the canonical-cased project
  path, see §11/lessons) then `hdc -t <target> install -r <hap>`; relaunch if
  needed (`aa start -a <ability> -b <bundle>`).
- Report the build and install result. Per §11, you may also validate the UI
  (screenshots/drive) and iterate, unless the developer asked to own that check.

---

_If any instruction here conflicts with the official challenge rules, the
challenge rules win — update this file to match them._
