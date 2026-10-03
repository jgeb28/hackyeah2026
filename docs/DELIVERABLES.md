# Deliverables & System-Component Packaging

Working analysis of the hackathon deliverables and what changes when the
submission is a **system component** instead of a plain app. This is a planning
document, not the final submission.

---

## 1. Baseline: the 7 required deliverables

From the challenge "Required Deliverables":

1. A **public source code repository**.
2. **Reproducible setup, build, installation and launch instructions**.
3. A working **`.hap` package**.
4. A brief **recorded demonstration**.
5. A concise **architecture and implementation description**.
6. **`AI_WORKFLOW.md`** when AI-assisted development tools were used.
7. **Additional AI integration documentation** when the submission includes AI
   features.

Plus the technical requirements: target **HarmonyOS / OpenHarmony / Oniro**,
**API 20+** (declare API 20 as minimum where applicable), run on an
**emulator or compatible device**, and **use/improve at least one platform,
device or system capability**.

---

## 2. What "system component" can mean on OpenHarmony/HarmonyOS

There is a spectrum, from "enhanced app" to "OS-internal service." Only the
first four are compatible with "installable without modifying the system."

| Option | What it is | Packaging | Needs system signing / full SDK? | Runs on stock emulator? | Fits "don't modify the system"? |
| --- | --- | --- | --- | --- | --- |
| **A. App using system APIs** | UIAbility app that consumes platform services | HAP | Sometimes (for restricted APIs) | Yes | Yes |
| **B. ExtensionAbility component** | Form/widget, Accessibility, InputMethod, AppService, WorkScheduler, Share, StaticSubscriber, etc. Provides a system-managed capability | HAP (built from `entry` module) | `AppServiceExtensionAbility` needs ACL `ohos.permission.SUPPORT_APP_SERVICE_EXTENSION` (enterprise-only); otherwise none | Mostly yes | Yes |
| **C. Native NAPI + shared library** | ArkTS app backed by C/C++ `lib*.so` via Node-API, packaged in the HAP | HAP + `.so` | No | Yes | Yes |
| **D. Privileged / system app** | Uses `system_basic`/`system_core` APIs (e.g. `ServiceExtensionAbility`, `DataShareExtensionAbility`) | HAP, system-signed | Yes — full SDK + `AllowAppUsePrivilegeExtension` + system signing profile | Usually no (signing/privilege) | Yes (installable) |
| **E. True SystemAbility (SA)** | C++ service registered with SAMGR via `sa_profile` + `sa_main`, part of the system image | System image component (linux binary) | N/A — it *is* the system | Requires custom image | **No — rejected** |

### Recommendation

- **Build option B + C** (ExtensionAbility-backed component with a native NAPI
  module) as the primary target. It gives real system integration, is
  installable as a HAP, and is reproducible on an emulator.
- Treat **option D** as a stretch goal only if we can obtain a system-scoped
  signing profile and full SDK; document the fallback.
- **Avoid option E** entirely for the graded submission. If we prototype an SA
  to learn, keep it clearly labelled as non-submission and not required to run.

---

## 3. Deliverable-by-deliverable: app vs system component

| Deliverable | Plain app | System component (option B/C, or D) |
| --- | --- | --- |
| **1. Public repo** | `entry/` ArkTS + `AppScope/` | Adds `entry/src/main/cpp/` (NAPI/C++), IDL files, `extensionAbilities` config, possibly `sa_profile/` (only if option E) |
| **2. Setup/build/install/launch** | DevEco Studio + SDK + hvigor + HDC | Also must state **public vs full SDK**, **signing profile / ACL permissions**, `hdc install` steps, and any emulator/device prerequisites |
| **3. `.hap`** | One signed HAP | Signed HAP (maybe system-signed); possibly an **HSP** for shared code, or a **HAR** if delivered as a reusable component |
| **4. Recorded demo** | App UI walkthrough | Show the **system integration**: extension bound/started, service running in background, widget on home screen, accessibility/input-method manager listing it, IPC call from a client app |
| **5. Architecture doc** | Screens, state, data flow | Extension type & lifecycle, ability model, **IPC/RPC (IDL, IRemoteObject)**, NAPI bridge, permissions, why it improves the system vs an app |
| **6. `AI_WORKFLOW.md`** | Same | Same |
| **7. AI integration doc** | If AI feature | If AI feature (e.g. on-device inference exposed as a system capability) |

---

## 4. Concrete artifact tree for a system-component submission

```text
hackyeah2026/
├── AGENTS.md
├── AI_WORKFLOW.md
├── README.md                        # setup/build/install/launch (deliverable 2)
├── docs/
│   ├── DELIVERABLES.md              # this file
│   ├── ARCHITECTURE.md              # deliverable 5
│   └── DEMO.md                      # demo script + where to find the recording
├── AppScope/
│   ├── app.json5                    # bundleName, minAPIVersion: 20, targetAPIVersion: 20
│   └── resources/
├── entry/                           # the installable HAP module
│   ├── src/main/
│   │   ├── module.json5             # abilities + extensionAbilities + requestPermissions
│   │   ├── ets/
│   │   │   ├── entryability/
│   │   │   └── <ourability>/        # UIAbility and/or ExtensionAbility
│   │   ├── cpp/                     # native NAPI module (option C)
│   │   │   ├── CMakeLists.txt
│   │   │   ├── napi_init.cpp
│   │   │   └── types/lib<name>/Index.d.ts
│   │   └── resources/
│   └── build/default/outputs/default/*.hap
├── <shared>/                        # optional HSP/HAR if component is reusable
├── signing/                         # profile + cert (NEVER commit secrets/private keys)
└── tests/                           # hypium tests + evidence logs
```

---

## 5. Extra prerequisites a system component introduces

- **Signing privilege.** Restricted/system APIs and ACL permissions require the
  signing profile to grant them (`app-privilege-capabilities` / ACL, and for
  system apps an `apl` of `system_basic` or `system_core`). Normal
  auto-signing works only for normal-privilege APIs.
- **Full SDK.** System APIs are hidden in the public SDK. Option D requires
  downloading/switching to the full SDK in DevEco Studio.
- **ACL permissions.** Example: `AppServiceExtensionAbility` (API 20+) requires
  ACL `ohos.permission.SUPPORT_APP_SERVICE_EXTENSION`, currently limited to
  enterprise apps — confirm eligibility before choosing it.
- **Declared permissions.** Every permission must be justified in
  `requestPermissions` (with `reason` + `usedScene`) and in the architecture doc.
  No unnecessary permissions.
- **Package type choice.** HAP = installable unit. HSP = dynamic shared package
  (installed with host). HAR = static shared library (compiled in). Deliver a
  HAP unless explicitly shipping a reusable library.
- **Emulator limitations.** Some capabilities (sensors, positioning, NFC,
  telephony, real device trust) may not work on the emulator; the challenge
  expects an explicit explanation of how they would work on hardware.

---

## 6. Verification evidence to capture (for deliverable 4/5 and scoring)

- `hvigorw` build log showing `BUILD SUCCESSFUL` and `.hap` output path.
- `hdc install` / `bm install` output and `hdc shell bm dump -n <bundle>` showing
  the installed ability/extension.
- `hidumper` / `aa dump` / `hilog` output proving the component is registered
  and running in the system.
- A client app (or system surface) invoking the component, demonstrating the
  IPC/NAPI path end-to-end.
- Error-path screenshots: permission denied, service unavailable, bad input.
- Test results (`ohosTest` / hypium).

---

## 7. Submission checklist (system component)

- [ ] Component type chosen and justified (B/C, optionally D); option E excluded.
- [ ] `minAPIVersion`/`targetAPIVersion` = 20 in `AppScope/app.json5`.
- [ ] `module.json5` declares abilities/`extensionAbilities`, permissions, and
      `exported` flags correctly.
- [ ] Native module (if any) builds and loads (`lib*.so` present in HAP).
- [ ] Signed HAP produced; signing steps reproducible by a third party.
- [ ] README: environment versions (DevEco, SDK, hvigor, HDC), build, install,
      launch, and uninstall steps.
- [ ] `docs/ARCHITECTURE.md`: integration model, IPC/NAPI, lifecycle,
      permissions, data flow.
- [ ] `docs/DEMO.md` + recording link.
- [ ] `AI_WORKFLOW.md` current; separate AI integration doc if AI feature.
- [ ] No secrets (signing private keys, API keys, tokens) committed.
- [ ] Test/verification evidence captured.
- [ ] Emulator-only limitations explained.

---

## 8. Open decisions

1. Which option (B/C vs D) — depends on signing profile availability.
2. Which ExtensionAbility type fits the idea (widget / accessibility /
   input method / app-service / WorkScheduler / share).
3. Does the idea need an IPC surface (IDL + `IRemoteObject`) exposed to other
   apps, or is it self-contained?
4. Is there a runtime AI feature? If yes, it triggers deliverable 7 and the
   privacy/validation sections.
