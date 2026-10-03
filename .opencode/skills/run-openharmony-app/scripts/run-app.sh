#!/usr/bin/env bash
# Build, sign, install, launch, and screenshot an OpenHarmony/Oniro project
# on the local emulator.
#   scripts/run-app.sh [project-dir]   (defaults to the current directory)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
source "$here/env.sh"
proj="${1:-$PWD}"
cd "$proj"

# Make sure a device is connected (no-op if already connected).
export ONIRO_HDC_PORT="${ONIRO_HDC_PORT:-55555}"
if ! hdc list targets 2>/dev/null | grep -q '127.0.0.1'; then
  hdc tconn "127.0.0.1:$ONIRO_HDC_PORT" || true
fi

oniro-app sign
oniro-app build
oniro-app app install
oniro-app app launch
sleep 3   # let the ability come to the foreground before capturing
oniro-app screenshot -o "$proj/screenshot.jpeg" || true
echo "running. screenshot: $proj/screenshot.jpeg"
