# AGENTS.md — Instructions for All AI Agents

This file is the canonical instruction set for **every** AI agent, coding
assistant, subagent, MCP-backed tool, or automated workflow that touches this
repository. Read it before doing any work and follow it for the entire session.

---

## 0. THE PRIME DIRECTIVE — Maintain your `AI_WORKFLOW_<git-username>.md`

> **Every agent MUST keep its own per-developer workflow file up to date.**

This is a mandatory hackathon deliverable. The challenge requires any team that
uses AI tools during development **and/or** ships an AI feature to publish an AI
workflow document. Because this entire project is built with AI agents, that
means **you**.

**AI_WORKFLOW rules** (authoritative source:
[`HuwaweiChallenge/AGENTS.md`](./HuwaweiChallenge/AGENTS.md)):

- **File name:** `AI_WORKFLOW_<git-username>.md`, derived from
  `git config user.name` — lowercased, spaces → hyphens
  (e.g. `AI_WORKFLOW_jane-doe.md`). Do not edit another developer's file.
- **Newest first:** each update is **prepended** at the top of the file.
- **Timestamp every update:** `## Update: [YYYY-MM-DD HH:MM:SS]` immediately
  followed by `**Developer:** <git-username>`.
- **Use the update template in §4.**
- **Be concise:** highlights only — no transcripts, no repetition.
- **No secrets, credentials, or PII**, ever.

Concretely, every agent must:

1. **Before starting a task** — read its per-developer file to understand what
   has already been recorded and avoid contradicting or duplicating it.
2. **During the task** — note the model(s)/service(s) used, the prompts and
   instructions that mattered, the approach taken, and anything that failed.
3. **After completing every significant task** (feature, bug fix, refactor,
   architecture decision, test run, failed experiment) — **prepend** a new
   timestamped update using the §4 template.
4. **Before ending a session or opening a pull request** — run the pre-flight
   checklist in §6 and confirm the workflow file is current.

Updating the workflow file is **part of "done"**. Never delete or rewrite another
developer's entries — append and correct with a clearly marked note if needed.

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

## 2. What `AI_WORKFLOW.md` must contain (challenge rules)

Reproduce these requirements faithfully. The file is scored on **transparency
and reproducibility**, so completeness beats polish.

### A. Development tools — REQUIRED for this project

Because we use AI-assisted development tools, document **all** of the following:

- **All AI models, coding agents, MCP servers, Agent Skills, and other
  AI-assisted tools used.** For each: name, provider/version (or “unknown”),
  and what it was used for.
- **The main prompts, reusable instructions, and relevant configuration.**
  Include the prompts that materially shaped the output, plus any rules files,
  agent configs, skills, or MCP configuration. Paste them verbatim where
  practical (see secret rules in §3/§5).
- **The workflow** from ideation and architecture through implementation,
  testing, and debugging.
- **How generated output was reviewed, tested, and validated** — who/how it was
  checked, what tests or manual verification were run, what evidence exists.
- **Known limitations, unsuccessful approaches, and lessons learned.** Be honest;
  failed attempts are part of the record.

Prompts and tool usage should be documented **as fully as reasonably possible**.

### B. AI features — REQUIRED if the submission includes an AI feature

If any part of the product uses an AI model or service at runtime, additionally
document, per feature:

- **The model or service** used (name, provider, version).
- **The inference flow** (inputs, preprocessing, where inference runs, outputs,
  fallbacks).
- **Data handling** (what data is collected, stored, or transmitted; where).
- **Limitations** (accuracy, latency, language coverage, device constraints).
- **The validation approach** (how correctness and failure modes were tested).
- **Privacy considerations** (on-device vs. remote, consent, retention, PII).

### C. Submissions may also need additional AI integration documentation

If the submission includes AI features, `AI_WORKFLOW.md` alone is not enough —
also maintain the separate, concise architecture/implementation document that
explains the AI integration. Link it from `AI_WORKFLOW.md`.

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

## 4. Update template (prepend for every significant task)

**Prepend** this block to the top of `AI_WORKFLOW_<git-username>.md` (newest
first) for each meaningful unit of work:

```markdown
---
## Update: [YYYY-MM-DD HH:MM:SS]
**Developer:** [git-username]

#### 1. AI Features (skip if none were built this session)
* **Model/Service:** ...
* **Inference Flow:** ...
* **Data Handling & Privacy:** ...
* **Limitations & Validation:** ...

#### 2. AI Development Tools Used
* **Models & Agents:** ...
* **MCP Servers & Skills:** ...
* **Configuration:** ...

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** ...
* **Implementation:** ...
* **Key Prompts:** ...
* **Testing & Debugging:** ...

#### 4. Review & Validation
* **Human Oversight:** ...
* **Security Checks:** ...

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** ...
* **Lessons Learned:** ...
```

Skip any section that does not apply rather than leaving it blank. Keep entries
honest, specific, and heavily compressed.

---

## 5. Configuration & prompt hygiene

- If a tool reads configuration (agent configs, `opencode.jsonc`, MCP config,
  skills), record **the relevant parts** in `AI_WORKFLOW_<git-username>.md` — not
  the whole file if it is large. Reference the path and summarize, then quote the
  parts that shaped behavior.
- Store secrets in environment variables or a git-ignored local file. Never put
  them in tracked files, prompts, or the workflow file.
- Before committing, run a quick sanity check for accidentally included
  credentials. If one is found, rotate it and remove it from history if needed.

---

## 6. Pre-flight checklist (run before finishing any task / PR)

- [ ] I read my `AI_WORKFLOW_<git-username>.md` before working.
- [ ] I prepended a timestamped update for this task using the §4 template.
- [ ] AI models, agents, MCP servers, skills, and tools used are named.
- [ ] The meaningful prompts/instructions and relevant config are recorded.
- [ ] The ideation → architecture → implementation → testing → debugging
      workflow is captured.
- [ ] Generated output review, tests, and validation evidence are described.
- [ ] UI changes were validated on the emulator (screenshot/drive) and iterated
      (see §12), or handed to the developer if requested.
- [ ] After changing the app, the new build was installed on the
      emulator/device (see §13).
- [ ] Known limitations, unsuccessful approaches, and lessons learned are
      included.
- [ ] If an AI feature is involved: model/service, inference flow, data
      handling, limitations, validation, and privacy are documented.
- [ ] No secrets, credentials, or personal data were added anywhere.
- [ ] Only task-relevant files were staged/committed — no editor/IDE configs,
      generated output, large binaries, or unrelated prior work (see §8).
- [ ] My `AI_WORKFLOW_<git-username>.md` renders correctly and links are valid.

---

## 7. General working agreements

- **Prefer the platform.** Use real OpenHarmony/HarmonyOS capabilities
  (system services, APIs, distributed features, on-device AI, sensors,
  accessibility) rather than cross-platform code that would run unchanged
  anywhere.
- **Keep changes modular and readable.** Add reasonable error handling and
  input validation. No unnecessary permissions or risky dependencies.
- **Test the key scenarios** and record the evidence in the per-developer
  workflow file; full
  coverage is not required, but show that you checked your own work.
- **Document reproducibility.** Keep setup/build/launch instructions in the
  README accurate and in sync with the code.
- **When in doubt, record it.** A short honest note is always better than a gap.

---

## 8. Commit & staging hygiene — do not dump files

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
  (`signatures/`, `*.p12`, `*.p7b`, `*.pem`, keys, tokens) — see §3 and §5.
- **Keep commits and PRs scoped.** A PR must contain the work for its stated
  purpose only. If earlier local commits were never pushed, do **not** silently
  publish them as part of an unrelated PR — surface them and ask.
- **When in doubt, ask** before staging anything outside the task's scope.

---

## 9. Feature, comment & script hygiene

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

## 10. Pull requests — humans merge, agents do not

- Agents may create branches, commit, push, and open or update pull requests.
- Agents must **never merge a PR** (nor close one) on their own. Opening a PR
  means **hand it back** to the developer for review and merge.
- Do **not** push directly to `main` (or any protected branch) unless the human
  explicitly instructs it for that specific change.
- After opening a PR, stop and report the PR link plus what was built/tested.

---

## 11. Dev-only backend — keep the remote and on-device paths in parity

The app has a dev-only **"Dev mode"** switch that routes OCR and LAY A to a host
server (`C:\guardian-devserver`, kept **outside** the repo). It exists only to
iterate quickly; the shipping product is on-device and offline.

- **The remote path and the on-device path must implement the same model schema,
  questions, and decision policy before any push/PR.** A change made only on the
  host (e.g. an edited LAY A question set or threshold) is **not "done"** until
  the on-device `.ms` is re-exported to match (`convert_laya.py`, kept out of the
  repo per §9) and re-validated. The LAY A questions are **baked into the graph**,
  so any question change always requires a re-export.
- **Never ship the remote path.** Remove `ohos.permission.INTERNET` and the
  remote/dev code before the submission build; the shipping app stays on-device
  and offline.
- **Record parity status.** Note any schema/policy change and whether the
  on-device model has been re-exported in `AI_WORKFLOW_<git-username>.md` while
  the two paths are temporarily out of parity.

---

## 12. UI validation — the agent validates and iterates

- The agent **may and should** validate visual/UI behaviour itself: build,
  install, drive the emulator, take screenshots, and iterate on visual issues
  until they look right — unless the developer asks to own a specific check.
- Code-level checks (build/compile, unit tests, lint) are still expected and must
  be reported.

---

## 13. Always build & install after changing the app

- After **any** change to the HarmonyOS app, build **and install** the HAP to the
  running emulator/device before handing back — the developer must always be
  testing the newest code.
- Concretely: `hvigorw … assembleHap` (build from the canonical-cased project
  path, see §12/lessons) then `hdc -t <target> install -r <hap>`; relaunch if
  needed (`aa start -a <ability> -b <bundle>`).
- Report the build and install result. Do **not** take screenshots or judge the
  UI — that stays with the developer (§12).

---

_If any instruction here conflicts with the official challenge rules, the
challenge rules win — update this file to match them._
