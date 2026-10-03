#!/usr/bin/env bash
# Run every Guardian test suite.
#   tests/run-all.sh            # unit only (device-free)
#   tests/run-all.sh --device   # unit + on-device integration (emulator required)
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

bash "$here/run.sh"

if [ "${1:-}" = "--device" ]; then
  bash "$here/run-integration.sh"
else
  echo "skipping on-device integration tests (pass --device to run them)"
fi
