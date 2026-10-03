#!/usr/bin/env bash
# Manage the Oniro/OpenHarmony QEMU emulator.
#   scripts/emulator.sh {start|stop|status|connect|log}
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
IMG_DIR="${ONIRO_EMULATOR_IMAGES:-$HOME/ohos/emulator/oniro/images}"
LOG="${ONIRO_EMULATOR_LOG:-$HOME/ohos/emulator/emulator.log}"
PORT="${ONIRO_HDC_PORT:-55555}"
cmd="${1:-status}"

case "$cmd" in
  start)
    if pgrep -f qemu-system-x86_64 >/dev/null; then
      echo "emulator already running"; exit 0
    fi
    cd "$IMG_DIR"
    setsid nohup ./run.sh "${@:2}" > "$LOG" 2>&1 < /dev/null &
    echo "starting emulator; log: $LOG"
    ;;
  stop)
    if pkill -f qemu-system-x86_64; then echo "stopped"; else echo "not running"; fi
    ;;
  status)
    if pgrep -f qemu-system-x86_64 >/dev/null; then echo "running"; else echo "not running"; exit 1; fi
    ;;
  connect)
    source "$here/env.sh"
    hdc tconn "127.0.0.1:$PORT"
    hdc list targets
    ;;
  log)
    tail -n "${2:-40}" "$LOG"
    ;;
  *)
    echo "usage: $0 {start|stop|status|connect|log}" >&2; exit 2
    ;;
esac
