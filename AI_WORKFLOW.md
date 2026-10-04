# AI Workflow — Guardian

**Guardian** is our submission to the HarmonyOS / OpenHarmony hackathon: a
camera-anchored **Smart Island** that reads the text you point it at, classifies
it **on-device**, and warns you about scams and misleading content. It lives in
the *Human-Centric Technology* and *Intelligent Experiences* challenge areas.

This is the team's AI workflow. It describes **how we used AI agents to build
Guardian** — the tools, the process, and the lessons. The product's own on-device
AI (the model, its inference flow, data handling, limitations, validation and
privacy) is a separate concern and is documented in
[`AI_INTEGRATION.md`](./AI_INTEGRATION.md).

## The agents we worked with

We built the whole project with **OpenCode** agents running
`deepseek/deepseek-flash` (DeepSeek V4.1 Flash) — one agent per developer.

- For the model work we ran **three background `general` subagents** in parallel:
  two generated the 40k training and 10k test datasets, and one built the
  fine-tuning, calibration and export pipeline.
- On the device side we relied on the **`run-openharmony-app`** Agent Skill
  (build, sign, install, launch, drive the emulator, capture screenshots) and
  the **`opencode`** skill for configuration questions.
- For hosting/fetching the model we used the **`hf-cli`** Agent Skill (Hugging
  Face Hub CLI) to upload the artefacts and verify the download.
- We used **no MCP servers**.

Every agent worked under the repo's [`AGENTS.md`](./AGENTS.md): commit only
task-relevant files, never put secrets or scripts in the repo, and **never merge a
pull request** — a human always did that.

## How we worked with the agents

**Start from the platform, not from assumptions.** Before proposing any design,
an agent read the design doc and the installed SDK type declarations (`.d.ts`)
and permission tables. Every feasibility claim — screen capture, floating
windows, accessibility, MindSpore Lite — was checked against the SDK or official
documentation first. Several early ideas were dropped this way (for example, a
third-party app cannot read other apps' screens silently).

**Keep the seams clean.** We kept the architecture behind small ports
(`OcrEngine`, `DecisionRepository`, `IngestSource`) so the on-device path and the
dev-only remote path were interchangeable. This let the agents add features
without rewriting the UI, and made the logic testable off-device.

**Build, run, and debug on the real thing.** Agents compiled with `hvigorw
assembleHap`, installed with `hdc`, drove the emulator, and read `hilog` and
crash logs to find the true cause of a failure. Many "code bugs" turned out to be
environment facts — reading the full offset of a bundled file, a 1.7 GB model not
fitting in 4 GB of RAM, or a synchronous model load tripping the 6-second
watchdog.

**A human reviews and merges.** Agents opened pull requests and reported the
build and test results; the developer owned the final call, especially for
anything visual. Device-free unit tests (`tsc` + `node --test`) always ran before
a PR.

## What we asked the agents for

The prompts that shaped the build (compressed):

- **On-device first:** "use on-device acceleration — security is very important, so
  it must run locally."
- **Plan before code:** "plan your work, don't be chaotic" → an agent wrote
  `DESIGN.md` and checked the SDK before implementing.
- **No guessing:** "remove the heuristic fallback" → a real verdict or an honest
  "model unavailable", never a fabricated result.
- **Model work:** "cross-examine the calibration"; "rank checkpoints on the
  leakage-free test set"; "keep large models out of git — host them and fetch."
- **Packaging:** "add Windows / macOS / Linux + Python build scripts that build only
  the main app."

## Who did what

- **`j-brzoz`** brought the model on-device: porting Laya to MindSpore Lite,
  re-expressing unsupported graph ops, porting the ByteLevel-BPE tokenizer to
  ArkTS, and moving the heavy model load into a worker thread.
- **`minerbomb16`** built the Smart Island experience and the emulator run loop,
  and worked through the model's memory, offset and latency limits.
- **`s3r10us3r`** shaped the architecture and the incident knowledge base, built
  the dev-only remote backend, ran the Laya fine-tuning and calibration, and kept
  the docs and reproducibility in sync.

## What went wrong, and what we learned

We recorded our dead ends as carefully as our wins.

- **Rejected or dropped:** cloud inference as the default (privacy), a
  rule-based classifier fallback (false-positive risk), text-level OCR chrome
  stripping (measured, no reliable benefit), `onnxsim` shape-fixing, and
  dynamic-int8 `dyn8` Laya weights (crashed the x86 MindSpore kernel —
  weight-only `w8` works).
- **Platform limits are real:** a normal third-party app cannot start an ability
  from the background or capture the screen silently. We designed around both
  instead of pretending otherwise.
- **Agent lessons:** validate on the real SDK before designing; build from the
  canonical-cased project path; select model checkpoints on a leakage-free test
  split; never let a fallback pretend to be real inference; and keep the remote
  and on-device paths in parity.

## Read more

- [`AI_INTEGRATION.md`](./AI_INTEGRATION.md) — the on-device AI feature
  (model, inference, data handling, validation, privacy).
- [`DESIGN.md`](./DESIGN.md) and [`RUNNING.md`](./RUNNING.md) — architecture and
  the run guide.
