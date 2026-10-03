#!/usr/bin/env bash
# Device-free unit tests for Guardian's pure core + SDK protocol.
#   tests/run.sh
set -euo pipefail
repo="$(cd "$(dirname "$0")/.." && pwd)"
TSC="${TSC:-$HOME/ohos/command-line-tools/hvigor/hvigor/node_modules/typescript/bin/tsc}"
if [ ! -f "$TSC" ]; then
  echo "tsc not found at $TSC; set TSC=/path/to/typescript/bin/tsc" >&2
  exit 2
fi
cd "$repo"
echo "== compile =="
node "$TSC" -p tsconfig.tests.json
echo "== run =="
node --test .test-build/tests/unit/
