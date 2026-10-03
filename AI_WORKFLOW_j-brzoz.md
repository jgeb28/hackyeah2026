# AI Workflow — developer `j-brzoz`

Per-developer, AI-assisted development log (rules: [`AGENTS.md`](./AGENTS.md) and
[`HuwaweiChallenge/AGENTS.md`](./HuwaweiChallenge/AGENTS.md)). Entries are
**newest-first**, timestamped, and deliberately compressed. This file holds only
this developer's entries.

---
## Update: 2026-10-03 22:07:24
**Developer:** j-brzoz

#### 3. Development Workflow & Prompts
* **On-device perf (fp32):** worker load succeeded (`model loaded (prefixes=3 maxLen=512)` after
  ~60 s) with the UI responsive — the Worker fix worked. But `predict` exceeded 11 min: the guest was
  **swap-thrashing** (`free -m`: 3894/3931 MB used; `VmSwap: 1.23 GB`; RSS ~1.7 GB). Root cause: the
  1.7 GB fp32 model does not fit alongside the OS in a **4 GB** emulator.
* **Mitigations applied:** raised emulator RAM `4096→6144` in
  `%LOCALAPPDATA%/Huawei/Emulator/deployed/Pura 90v2/{config.ini,hardware-qemu.ini}` and `lists.json`;
  set worker `cpu.threadNum = 4`. Next run to measure `infer ok … latency`.
* **Decision:** continue on a faster host; move the source via a git branch and copy the 1.69 GB `.ms`
  out-of-band (git-ignored, GitHub rejects >100 MB).

#### 4. Review & Validation
* **Evidence:** thread/CPU sampling (`/proc/<pid>/stat`, `/proc/<pid>/task/.../stat`) showed CPU busy
  but `predict` stuck in swap; force-stopped the app to stop thrashing.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** a 421 M-param fp32 model (~1.7 GB) is too large for a 4 GB guest; either give
  the emulator ≥6 GB or ship a smaller artefact (int8 413 MB — still unproven on the x86 MSP runtime).
  Measure guest `free -m`/`VmSwap` before blaming code.

---
## Update: 2026-10-03 21:42:58
**Developer:** j-brzoz

#### 3. Development Workflow & Prompts
* **Compile fixes:** `ThreadWorkerGlobalScope` is a top-level `@kit.ArkTS` type (not `worker.*`);
  cast `Float32Array.buffer as ArrayBuffer` (the `arkts-no-untyped-obj-literals` error was really an
  `ArrayBufferLike`→`ArrayBuffer` mismatch).
* **Install failed again** (`9568288 insufficient disk memory`): bundling the 1.7 GB `.ms` needs
  ~3.4 GB peak *and* the sandbox already holds a 1.69 GB copy. **Externalised the model again:**
  moved `laya_guardian_fp32.ms` out of `rawfile/` into `model/` (git-ignored); `rawfile/` is now only
  meta+tokenizer (~3.5 MB) so the HAP installs in seconds. `ensureReady()` skips the copy when the
  sandbox model already exists.

#### 4. Review & Validation
* **Evidence:** on-device sandbox confirmed
  `/data/app/el2/100/base/com.example.huwaweichallenge/haps/entry/files/laya_guardian_fp32.ms`
  (1686318032 bytes); `/data` 11 GB, 6.8 GB free. Awaiting small-HAP run.

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** don't ship a multi-GB model inside the HAP on this emulator; materialise once
  into the sandbox and keep the HAP small. An app *update* preserves the sandbox, but a full
  uninstall wipes it (re-provision by temporarily rebundling the `.ms`).

---
## Update: 2026-10-03 21:34:43
**Developer:** j-brzoz

#### 2. AI Development Tools Used
* OpenCode agent running `deepseek/deepseek-flash`; diagnostics via Windows `hdc.exe` (`hilog`,
  `cat /data/log/faultlog/faultlogger/*.log`).

#### 3. Development Workflow & Prompts
* **Diagnosis (appfreeze):** the rawfile-offset fix worked — `AssetLoader: copied 1686318032 bytes`
  into `filesDir`; then the app was killed with `Reason: THREAD_BLOCK_6S` (`processExit:1`). Freeze
  dump showed the **main thread** (`stime=452`) stuck for >6 s right after `Using existing sandbox
  model` — i.e. `mindSporeLite.loadModelFromFile` parsing the 1.7 GB model **synchronously on the UI
  thread** tripped the HarmonyOS watchdog.
* **Fix — offload to an ArkTS Worker:** new `ets/workers/LayaWorker.ets` loads tokenizer/meta/model
  and runs `predict` on a worker thread; `LayaEngineClient` (UI thread) only shuttles messages and
  returns raw logits; `MindSporeLiteEngine` now just materialises the model + decodes logits.
  Registered the worker in `entry/build-profile.json5` → `buildOption.sourceOption.workers`.

#### 4. Review & Validation
* **Evidence:** faultlog (`/data/log/faultlog/faultlogger/appfreeze-…782.log`) confirms reason and
  kill; copy size/magic verified on-device. Worker path validated against SDK `@ohos.worker.d.ts`.
* **Not yet validated:** build + on-device run with the worker (next step).

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** on HarmonyOS, any synchronous call >6 s on the UI thread (e.g. loading a
  1.7 GB MindSpore Lite model) triggers `THREAD_BLOCK_6S` and the process is killed; long model
  work must run in a Worker/TaskPool. Manually-created Workers must be listed in
  `build-profile.json5` `sourceOption.workers`.

---
## Update: 2026-10-03 21:23:09
**Developer:** j-brzoz

#### 2. AI Development Tools Used
* **Agent/Model:** OpenCode agent running `deepseek/deepseek-flash`.
* **Diagnostics:** Windows `hdc.exe` invoked from WSL (`hilog`, `df`, `pidof`, `cat /proc/<pid>/maps`);
  eGPU logs under `%LOCALAPPDATA%/Huawei/Emulator/deployed/Pura 90v2/Log`.

#### 3. Development Workflow & Prompts
* **Debugging on emulator:** app now runs; popup showed `UNKNOWN`. `hilog` (pid 6238) revealed the
  true failure — **not** the tokenizer: `MS_LITE: LoadModelByBuff# Invalid mslite model.` /
  `Build# Init session failed`.
* **Root cause:** `resourceManager.getRawFdSync` returns `{fd, offset, length}` where `fd` is the
  **whole HAP** and the asset starts at a non-zero `offset`. `MindSporeLiteEngine` passed `fd` to
  `loadModelFromFd`, which reads from position 0 (the HAP zip header) → invalid model. Verified the
  built HAP stores the `.ms` uncompressed at `header_offset=106825` (zip `method=0`).
* **Fixes:**
  1. `AssetLoader.copyRawfileTo()`: sequentially seek to `offset`, stream `length` bytes into
     `filesDir/laya_guardian_fp32.ms.part` (async, 8 MiB chunks, magic-byte `MSL2` check,
     atomic `rename`); `MindSporeLiteEngine` then `loadModelFromFile()`.
  2. `AppContainer` probes NNRt once and sets `config.useNpu` from it (emulator is CPU-only, so the
     engine no longer requests an unavailable NNRt delegate).
  3. `BpeTokenizer`: replaced the regex **literal** with `new RegExp(...)` (`arkts-no-regexp-literals`)
     plus an ASCII fallback if `\p{L}` is unsupported; fixed `arkts-limited-throw` (rethrow `Error`).
  4. Added stage logging (`inputs/encode/setData/predict`) + real `error.message` (ArkTS errors
     `JSON.stringify` to `{}`).

#### 4. Review & Validation
* **Evidence:** `MS_LITE` native logs confirm the runtime is present and the model loads; the
  failure was the fd-offset bug. Awaiting rebuild to confirm `predict ok` and a real verdict.
* **Environment:** DevEco HarmonyOS emulator `Pura 90v2` (12 GB data, 4 GB RAM), app sandbox
  `/data/storage/el2/base/haps/entry/files` (unprivileged `hdc`, so no direct push).

#### 5. Limitations & Lessons Learned
* **Unsuccessful approaches:** int8 weight-quant `.ms` (413 MB) **fails to load** on the x86 MSP
  runtime (`NNACL matmul prepare failed`), so fp32 remains the only validated artefact. Earlier
  "Emulator Freeze / Guest No Response" was host RAM starvation: 14 GB host + `.wslconfig
  memory=11GB` + 4 GB emulator → guest `hdcd` hung in `__alloc_pages`; lowered to `memory=4GB`.
* **Lessons Learned:** never feed a rawfile `getRawFdSync` `.fd` straight into `loadModelFromFd`;
  always honour `offset`/`length` (or copy to a real path). Log `error.message`, not `JSON.stringify`.

---
## Update: 2026-10-03 18:35:34
**Developer:** j-brzoz

#### 1. AI Features
* **Ship fp32:** the validated `laya_guardian_fp32.ms` (1.69 GB) + `tokenizer.json` +
  `laya_guardian_meta.json` are bundled in `rawfile/`; app wired end-to-end (fp32, offline).

#### 3. Development Workflow & Prompts
* **Key Prompt:** "lets ship fp32 first"; "is it integrated now?".
* **Implementation/Fix:** rewired `MindSporeLiteEngine` to the full-sequence contract
  (meta-driven `input_ids`/`attention_mask` `[3,512]`); category-based verdict; **fixed a
  real tokenizer bug**: `tokenizer.json` `merges` are `["a","b"]` arrays, not strings, so
  the ArkTS `BpeTokenizer` would have thrown at load.

#### 4. Review & Validation
* **Tokenizer algorithm validated:** a Python reimplementation of the exact ArkTS BPE
  logic matches HF `AutoTokenizer` **byte-for-byte** on all 5 sample messages.
* **Not yet validated:** DevEco build/compile, ArkTS `\p{L}` regex support at runtime,
  emulator run, HAP size (1.69 GB).

#### 5. Limitations & Lessons Learned
* **Lessons Learned:** validate the on-device tokenizer against the reference before
  trusting end-to-end results; large model files are git-ignored and must be built locally.

---
## Update: 2026-10-03 18:32:35
**Developer:** j-brzoz

#### 1. AI Features (built)
* **Model/Service:** **LAYA on-device via MindSpore Lite** (`.ms`). No retraining;
  custom PyTorch `DecisionModel` (ModernBERT-large + bespoke option-marker head) exported
  and converted.
* **Inference Flow:** `BpeTokenizer` → build `input_ids`/`attention_mask` `[3,512]`
  (prefix + state + `[SEP]` + pad, from `meta.json`) → `model.predict` → `[1,3,5]`
  temperature-scaled logits → per-question softmax → verdict. Verdict now keys off
  **category** P(scam)+P(harassment) (base `noul` is unreliable).
* **Data Handling & Privacy:** fully offline; no network permission.
* **Limitations & Validation:** fp32 `.ms` (1.69 GB) matches reference `RLAgent`
  (max prob diff **2.5e-3**, all argmax agree). fp16 `.ms` NaNs (open). Base model
  accuracy is weak (fine-tuning needed).

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent `deepseek/deepseek-flash`; a `general` subagent
  for ONNX-Runtime-on-OpenHarmony research.
* **MCP Servers & Skills:** none. Tools: `uv`, `converter_lite` (MindSpore Lite 2.10.0),
  `mindspore_lite` Python runtime, `onnx`, `onnxruntime`, `onnxsim`, `curl`, websearch.
* **Configuration:** deps in `~/tmp/pyproject.toml`; converter via `CONVERTER_LITE`/`MSLITE_HOME`.

#### 3. Development Workflow & Prompts
* **Key Prompts:** "our app is running on openharmony … add laya model … use clean
  architecture"; "security is very important so it must run locally"; "use on device
  acceleration"; "lets ship fp32 first"; "write a python script converter in ~/tmp";
  "research the best way to run models on harmonyos emulator"; "plan your work, dont be chaotic".
* **Ideation & Architecture:** choose the OS-native MindSpore Lite path; wrap Laya's
  custom model in a `GuardianGraph` that bakes Guardian's 3 questions and **re-expresses
  ModernBERT's 4D mask construction with supported ops** (prebuilt mask dict + float-only
  masking + additive `src_mask` + static marker slicing).
* **Implementation:** `~/tmp/convert_laya.py`: HF download → rebuild `DecisionModel`
  (eager attn, MHA fast path off) → ONNX (opset 17) → fp16 → `converter_lite` → `.ms`;
  emits `laya_guardian_meta.json` (prefixes/markers/sep/pad). App: rewrote
  `MindSporeLiteEngine` to the full-sequence contract; copied `fp32.ms` + `tokenizer.json`
  + meta into `rawfile/`; category-based verdict in `AnalyseMessageUseCase`.
* **Testing & Debugging:** equivalence harnesses (`test_equiv.py`, `test_local.py`,
  `validate_ms.py`, `dump_ms.py`). Debugged a chain of op-support gaps (see below) and one
  **input-layout bug** (state padding shifted `[SEP]`).

#### 4. Review & Validation
* **Human Oversight:** same 5 messages (scam/phishing/legit/emergency/misinfo) compared
  `.ms` vs `RLAgent`; all decisions match.
* **Security Checks:** no network permission; large model artefacts git-ignored
  (`*.ms`/`*.onnx`/`*.mindir`); no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** mandatory cloud HF Space (rejected for privacy);
  `onnxsim` (OOM); `--fp16=on` (NaN); sherpa-onnx as a generic runner (impossible —
  speech-task API only).
* **Lessons Learned:** (1) "runs on MSP Lite" ≠ "converts cleanly": `ConstantOfShape`,
  `GatherElements`, and int→bool/int→fp16 `Cast` are runtime gaps; re-express the math.
  (2) Match Laya's exact token layout (`prefix+state+[SEP]+pad`) — padding position changes
  results. (3) For an arbitrary ONNX model on OpenHarmony the alternative is ONNX Runtime
  via NAPI (community OHOS ORT 1.16.3 fits our opset-17 model), not sherpa-onnx.

---
## Update: 2026-10-03 16:14:35
**Developer:** j-brzoz

#### 1. AI Features (reworked)
* **Model/Service:** **LAYA on-device (MindSpore Lite)**. Removed the heuristic
  fallback entirely (user: "we don't want false positives"); removed the cloud
  adapter earlier. Missing model now surfaces an error, never a guess.
* **Inference Flow:** `BpeTokenizer.encodeState` → `state_ids`/`state_mask` int32
  → `model.predict` → `[1,Q,MAX_OPTIONS]` logits (temperature baked in) → softmax
  → verdict. The converter (`~/tmp/convert_laya.py`) bakes Guardian's fixed
  instructions/options/head budget/temperatures into the graph.
* **Data Handling & Privacy:** fully offline; no network permission.
* **Limitations & Validation:** `.ms` not produced yet — **blocked on the
  MindSpore Lite `converter_lite` binary** (not on PyPI; only the cp37 runtime).
  ONNX export path written and to be validated; ArkTS BPE port still un-diffed.

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none. `uv` (0.12.22), Python 3.12, `curl`.
* **Configuration:** deps added to `~/tmp/pyproject.toml` (torch, transformers,
  safetensors, onnx, onnxruntime, huggingface_hub).

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "1. remove the hueristic fallback … 2. write a python script converter in
    ~/tmp there is uv there 3. if you find a blocker, tell me".
* **Ideation & Architecture:** fetched Laya's real source (`rl_common.py`,
  `rl_agent_api.py`) to replicate `DecisionModel.forward` exactly (encoder +
  type emb + 2-layer TransformerEncoder head + per-`[MASK]` option scorer +
  per-option-count temperature/softmax). Decided to bake the fixed Guardian
  schema into the graph so the app only tokenizes the message.
* **Implementation:** removed `LocalHeuristicClassifier` + `allowLocalFallback`;
  added `~/tmp/convert_laya.py` (download → rebuild model in eager attn → trace
  ONNX opset 17 → `converter_lite`); updated `BpeTokenizer.encodeState` and
  `MindSporeLiteEngine` to the `state_ids`/`state_mask` contract.
* **Testing & Debugging:** confirmed `converter_lite` absence and PyPI/HF
  reachability with quick checks (a whole-disk `find /` was mistakenly used
  first and killed).

#### 4. Review & Validation
* **Human Oversight:** pending `uv sync` + ONNX validation and a DevEco build.
* **Security Checks:** no network permission; no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** rule-based fallback dropped (false-positive risk);
  a broad `find /` probe was a bad idea — use targeted checks.
* **Lessons Learned:** the one hard blocker is the MindSpore Lite converter;
  everything else (torch/tokenizer/ONNX) is scriptable from public sources.

---
## Update: 2026-10-03 15:52:30
**Developer:** j-brzoz

#### 1. AI Features (reworked to on-device, built)
* **Model/Service:** **LAYA** run **entirely on-device** via **MindSpore Lite**
  (`@kit.MindSporeLiteKit`). The hosted Hugging Face Space adapter and the
  `ohos.permission.INTERNET` declaration were **removed**; the app is offline.
* **Inference Flow:** tap question → `AnalyseMessageUseCase` (questions from
  `GuardianSchema`) → `DecisionRepositoryImpl` → `MindSporeLiteEngine`:
  `BpeTokenizer` → `input_ids`/`attention_mask` int32 → `model.predict` →
  `[1,Q,MAX_OPTIONS]` logits → per-question softmax → verdict.
* **Data Handling & Privacy:** no network path at all; message text processed in
  memory. This was the explicit goal ("security is very important so it must run
  locally").
* **Limitations & Validation:** the on-device `.ms` graph is **not bundled yet**
  (Laya's tokenizer + custom head must be converted with the MindSpore Lite
  converter). Until then a labelled **local heuristic** fallback keeps the app
  working. The ArkTS **ByteLevel BPE tokenizer** port is written but **not yet
  diffed against the Python tokenizer**. Emulator is CPU-only (no NPU).

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** none (web/curl to inspect the HF tokenizer and
  MindSpore Lite docs; `run-openharmony-app` skill deliberately not used).
* **Configuration:** `InferenceConfig` (quantisation, NNRt, threads);
  `GuardianSchema` shared by request and graph decode.

#### 3. Development Workflow & Prompts
* **Key Prompts:**
  * "use on device accelration, security is very imprtent so it must run locally".
* **Ideation & Architecture:** switch from cloud to local-only; introduced
  `GuardianSchema` as the single source of truth for the fixed label space and
  the graph's `[1,Q,MAX_OPTIONS]` output contract.
* **Implementation:** added `AssetLoader`, `BpeTokenizer`,
  `MindSporeLiteEngine`, `NnrtAccelerationProbe`, `LocalHeuristicClassifier`;
  rewrote the repository/DI/`Index`; removed the Space adapter and the INTERNET
  permission; documented the asset + graph contract in `LAYA_INTEGRATION.md`.
* **Testing & Debugging:** inspected the real `tokenizer.json` (confirmed
  `model.type = BPE`, `pre_tokenizer = ByteLevel`, NFC) via `curl`+Python;
  grounded the MindSpore API in the official `js-apis-mindSporeLite.md`
  (`target=['nnrt','cpu']`, `getRawFdSync`, `MSTensor.setData/getData`).

#### 4. Review & Validation
* **Human Oversight:** none yet — **pending a DevEco build + on-device run**; no
  SDK/emulator on this machine.
* **Security Checks:** no `INTERNET` permission and no network adapter; assets
  are read from `rawfile`; no secrets.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** cloud inference was dropped as incompatible with
  the security requirement.
* **Lessons Learned:** Laya is not runnable on-device out of the box — it needs a
  converted `.ms` **and** an on-device ByteLevel BPE tokenizer; the app-side
  machinery is now in place, the model artifact is the remaining external step.

---
## Update: 2026-10-03 15:46:17
**Developer:** j-brzoz

#### 1. AI Features (built)
* **Model/Service:** **LAYA** (`convaiinnovations/laya`) — non-autoregressive
  "System 1" decision model, called via its hosted **Hugging Face Gradio Space**
  (`convaiinnovations/laya-demo`). On-device path targets **MindSpore Lite**
  (`@kit.MindSporeLiteKit`).
* **Inference Flow:** tap question on `Index` → `AnalyseMessageUseCase` builds
  typed questions (`risk` noul, `category` choice, `urgency` score) →
  `DecisionRepositoryImpl` → `LayaSpaceDataSource` (`POST /gradio_api/call/run_playground`
  → `GET …/{event_id}` SSE) → JSON parsed to domain → `risk` probability mapped to
  `SAFE`/`DANGEROUS`/`CRITICAL` → `AnswerPopup` shows verdict, answers and
  probability breakdowns.
* **Data Handling & Privacy:** current build sends the message text to the HF
  Space (remote). On-device adapter sits behind the same `DecisionRepository`
  port for the privacy-first target. No secrets in code; HF token not required
  for the public Space.
* **Limitations & Validation:** remote protocol validated with `curl` against the
  live Space (`run_playground` returned `scam 0.945`, `is_phishing 0.70`,
  latency ~224 ms). On-device Laya is **not runnable yet** (custom tokenizer +
  option-marker head must be compiled to `.ms`); adapter fails loudly rather than
  faking answers. Emulator is CPU-only (no NPU).

#### 2. AI Development Tools Used
* **Models & Agents:** OpenCode agent running `deepseek/deepseek-flash`.
* **MCP Servers & Skills:** no MCP servers. The `run-openharmony-app` (Oniro)
  skill exists in the repo but is **not used** here — the team builds with
  DevEco Studio on other machines; the local box has no SDK/emulator.
* **Configuration:** challenge rules in `AGENTS.md`; API 20+/compileSdk 23,
  `runtimeOS: OpenHarmony`.

#### 3. Development Workflow & Prompts
* **Ideation & Architecture:** user asked for Laya "triggered on click (like the
  popup)", answers in the popup, the question replacing "Hello World", **clean
  architecture**, and whether the OS accelerates AI inference and whether the
  model is quantisation-configurable.
* **Implementation:** layered the `HuwaweiChallenge` app into
  `domain/` (model, `DecisionRepository` port, `AnalyseMessageUseCase`),
  `data/` (`InferenceConfig`; `LayaSpaceDataSource`; `MindSporeLiteDataSource`
  + `NnrtAccelerationProbe`; `DecisionRepositoryImpl`), `di/AppContainer`
  (composition root) and `presentation` (`AnswerPopup`, rewritten `Index`).
  Added `ohos.permission.INTERNET` and `internet_reason`.
* **Key Prompts:**
  * "our app is running on openharmony os for huawei, for now add laya model that
    is trigger on click (just like the pop up) and in the popup i want answers,
    and instead of 'Hello word' i want the question, use clean architecture. is
    ai inference accelreated in the os? try using that if yes, is the model
    configurable (quantisation)"
  * "those skills are not for you … we have the deveco" (do not use the Oniro
    emulator skill; deliver code for DevEco).
* **Testing & Debugging:** grounded the on-device API in the official OpenHarmony
  `js-apis-mindSporeLite.md` (`Context.target=['nnrt','cpu']`,
  `CpuDevice.precisionMode`, `getAllNNRTDeviceDescriptions`); verified the Gradio
  HTTP + SSE protocol and a real Laya response with `curl`. ArkTS itself was not
  compiled here (no DevEco/SDK).

#### 4. Review & Validation
* **Human Oversight:** none yet — **pending a DevEco build + emulator/device run**
  by the team; code follows existing ArkUI patterns in `Index.ets` /
  `DynamicIslandAlert.ets`.
* **Security Checks:** no secrets added; `INTERNET` is the only new permission and
  is justified by the remote adapter; `node_modules`/build output not committed.

#### 5. Limitations & Lessons Learned
* **Unsuccessful Approaches:** none this session (no build attempted locally).
* **Lessons Learned:** Laya has no ArkTS runtime and is not a Transformers.js
  architecture, so a TS/ArkTS app must reach it over the Space (or a converted
  `.ms` graph). MindSpore Lite/NNRt is the real OS acceleration path, but it is
  CPU-only on the emulator; quantisation is an offline converter step, not a
  runtime flag.
