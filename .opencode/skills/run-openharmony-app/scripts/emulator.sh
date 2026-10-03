#!/usr/bin/env bash
# Manage the Oniro/OpenHarmony QEMU emulator.
#   scripts/emulator.sh {start|start-vnc|stop|status|connect|capture|view|log}
#
# Display notes (this host: Wayland + hybrid GPU, QEMU 11.1.1):
#   * WINDOWED works only with the VGA-class "-vga virtio". The stock run.sh
#     uses "-vga none -device virtio-gpu-pci", whose console is never presented
#     here -> the window just shows "Display output is not active.".
#     => `start` uses scripts/start-windowed.sh.
#   * VNC also works and is a fallback: `start-vnc` (127.0.0.1:5900), and
#     `capture shot.png` grabs a PNG with scripts/vnccap.py (dependency-free).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
IMG_DIR="${ONIRO_EMULATOR_IMAGES:-$HOME/ohos/emulator/oniro/images}"
LOG="${ONIRO_EMULATOR_LOG:-$HOME/ohos/emulator/emulator.log}"
PORT="${ONIRO_HDC_PORT:-55555}"
VNC_PORT="${ONIRO_VNC_PORT:-5900}"
cmd="${1:-status}"

qemu_running() { ps -eo args= | grep -q '[q]emu-system-x86_64 -machine q35'; }

case "$cmd" in
  start)
    if qemu_running; then echo "emulator already running"; exit 0; fi
    setsid nohup "$here/start-windowed.sh" > "$LOG" 2>&1 < /dev/null &
    echo "starting emulator (windowed); log: $LOG"
    ;;
  start-vnc)
    if qemu_running; then echo "emulator already running"; exit 0; fi
    cd "$IMG_DIR"
    setsid nohup ./run.sh --headless > "$LOG" 2>&1 < /dev/null &
    echo "starting emulator (headless/VNC :$VNC_PORT); log: $LOG"
    ;;
  stop)
    if ps -eo pid=,args= | awk '/[q]emu-system-x86_64 -machine q35/ {print $1}' | xargs -r kill; then
      echo "stopped"
    else
      echo "not running"
    fi
    ;;
  status)
    if qemu_running; then echo "running"; else echo "not running"; exit 1; fi
    ;;
  connect)
    source "$here/env.sh"
    hdc tconn "127.0.0.1:$PORT"
    hdc list targets
    ;;
  capture)
    python3 "$here/vnccap.py" 127.0.0.1 "$VNC_PORT" "${2:-vnc.png}"
    ;;
  view)
    echo "VNC is on 127.0.0.1:$VNC_PORT"
    if command -v vncviewer >/dev/null; then exec vncviewer "127.0.0.1:0"; fi
    echo "Install a viewer:  sudo pacman -S --needed tigervnc   then: vncviewer 127.0.0.1:0"
    ;;
  log)
    tail -n "${2:-40}" "$LOG"
    ;;
  *)
    echo "usage: $0 {start|start-vnc|stop|status|connect|capture|view|log}" >&2; exit 2
    ;;
esac
