---
name: Run OpenHarmony App on Oniro Emulator
description: Build, sign, install, launch, and screenshot an OpenHarmony/Oniro ArkTS app on the local QEMU emulator using the oniro-app CLI, and start/stop the emulator. Use when asked to run, test, or build an OpenHarmony or Oniro app on the emulator, when asked to see the app's GUI, or when the emulator needs to be brought up or connected.
---

# Run an OpenHarmony app on the Oniro emulator

This machine has a working, **account-free** OpenHarmony development loop. The
emulator is a QEMU x86_64 KVM image of Eclipse Oniro (an OpenHarmony
downstream). Builds and installs go through the `oniro-app` CLI.

## Fixed paths and versions

| Thing | Location / value |
| --- | --- |
| CLI tools (`hvigorw`, `ohpm`, `hdc`, SDK) | `~/ohos/command-line-tools` (HarmonyOS 5.1.0.840, SDK API 18) |
| Toolchain env script | `~/ohos/env.sh` |
| Oniro App Builder CLI | `~/.local/bin/oniro-app` (`@oniroproject/oniro-app` 0.11.0) |
| SDK layout expected by `oniro-app` | `~/setup-ohos-sdk/linux/<api>` |
| Emulator images + launcher | `~/ohos/emulator/oniro/images/` |
| Emulator hdc endpoint | `127.0.0.1:55555` |
| Example project | `~/ohos/projects/HelloOniro` (bundle `com.example.hellooniro`) |

Convenience wrappers for this skill live in `scripts/`:
- `scripts/emulator.sh start|stop|status|connect|log` — manage the emulator.
- `scripts/run-app.sh [project-dir]` — build → install → launch → screenshot.
- `scripts/env.sh` — the environment exports below (source it).

## 0. Environment (required in every shell)

```bash
export PATH="$HOME/.local/bin:$HOME/ohos/command-line-tools/bin:$PATH"
export ONIRO_CMD_TOOLS_PATH="$HOME/ohos/command-line-tools"
```

**Do NOT put the SDK's bundled Node 18 on `PATH`.** `oniro-app` requires
Node >= 20 and crashes on Node 18 with `ReferenceError: File is not defined`.
The system Node 26 is correct. The `ohpm`/`hvigorw` wrappers set their own
`DEVECO_NODE_HOME`, so the bundled Node does not need to be on `PATH`.

## 1. Start the emulator (if not already running)

Check first:

```bash
pgrep -f qemu-system-x86_64 && ss -ltn | grep 55555
```

If not running, start it **detached** so it survives the calling shell:

```bash
cd ~/ohos/emulator/oniro/images
setsid nohup ./run.sh > ~/ohos/emulator/emulator.log 2>&1 < /dev/null &
```

Then wait ~60s for boot and connect:

```bash
source ~/ohos/env.sh
hdc tconn 127.0.0.1:55555          # -> Connect OK
hdc list targets                   # -> 127.0.0.1:55555
hdc shell "param get bootevent.boot.completed"   # -> true
hdc shell "param get const.ohos.apiversion"      # -> 23
```

## 2. Build, sign, install, launch

The `oniro-app` CLI is non-interactive and writes machine-readable results to
stdout. Run from the project directory:

```bash
cd <project-dir>          # e.g. ~/ohos/projects/HelloOniro
oniro-app sign            # offline OpenHarmony signing; rewrites signingConfigs
oniro-app build           # hvigorw assembleHap -> entry-default-signed.hap
oniro-app app install     # hdc install the signed .hap
oniro-app app launch      # start the EntryAbility
```

Or just: `scripts/run-app.sh ~/ohos/projects/HelloOniro`

## 3. Observe / debug

```bash
oniro-app devices                         # list connected targets
oniro-app screenshot -o shot.jpeg         # capture the screen (941x1176)
oniro-app dump layout --json              # normalized on-screen UI tree
oniro-app watch --log 'error|fault' --for 5000
hdc shell "ps -A | grep -i <bundle>"      # confirm the process is running
hdc shell "aa dump -l | grep -i <bundle>" # current mission / ability
```

Read the screenshot with the `read` tool (it renders images) to visually verify.

## Pitfalls and gotchas

- **hvigor needs a project-local `.npmrc`** mapping the `@ohos` npm scope to
  Huawei's mirror (`https://repo.harmonyos.com/npm/`). Copy
  `~/ohos/npmrc.template` to `<project>/.npmrc` if `oniro-app build` fails to
  resolve `@ohos/hvigor-ohos-plugin`.
- **`oniro-app sign` expects the SDK at `~/setup-ohos-sdk/linux/<api>`.** To
  reuse the bundled SDK without downloading, symlink it:
  `ln -sfn ~/ohos/command-line-tools/sdk/default/openharmony ~/setup-ohos-sdk/linux/<api>`.
  To install a proper SDK: `oniro-app sdk install 6.1` (API 23) or `6.0` (API 20).
- **API level:** the challenge requires **API 20+**. `oniro-app sdk list` shows
  `6.1 = API 23`, `6.0 = API 20`. The emulator is API 23; the bundled build SDK
  is API 18 (still runs on the API 23 device). Prefer creating projects with
  `oniro-app create --sdk 20` (or higher) once an SDK is installed.
- **QEMU segfault on startup** means missing Arch split packages. Required:
  `qemu-system-x86 qemu-ui-gtk qemu-ui-sdl qemu-hw-display-virtio-gpu`
  `qemu-hw-display-virtio-gpu-pci qemu-audio-pipewire`.
- **The Linux SDK Previewer is unusable** (Huawei ships it incomplete; its run
  path returns `Linux is not supported`). Always use the emulator for a GUI.
- The stock debug provisioning profile is **device-locked** (needs a UDID the
  emulator does not expose); `oniro-app sign` uses the offline `profile-release`
  flow instead — no Huawei account needed.
- Emulator start is CPU/RAM heavy: defaults are 6 vCPUs / 4096 MB; override with
  `./run.sh -s 4 -m 2048` or `--headless` (VNC :5900, telnet serial :4444).
- The emulator exits when its SDL window is closed (or the process is reaped).
  Check with `scripts/emulator.sh status`; restart with
  `scripts/emulator.sh start` and allow ~60s for boot before reconnecting.
- A screenshot taken immediately after `app launch` can catch the launcher
  before the ability is foregrounded. Allow ~3s (`run-app.sh` does), or re-run
  `oniro-app screenshot` if you see the home screen.
