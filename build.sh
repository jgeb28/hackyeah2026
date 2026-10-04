#!/usr/bin/env bash
# build.sh — build the Guardian app HAP (the `entry` module only — not the mocks).
#
# Ensures the on-device models are present (downloads them from Hugging Face via
# tools/fetch_model.py when missing), then runs hvigor's `assembleHap` for `entry`.
#
# Env overrides: DEVECO_HOME (DevEco Studio root), JAVA_HOME (JDK 17),
#                GUARDIAN_SKIP_FETCH=1, GUARDIAN_CLEAN=1.
#
# Usage:  ./build.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT="$ROOT/HuwaweiChallenge"
RAWFILE="$PROJECT/entry/src/main/resources/rawfile"

find_deveco() {
  if [ -n "${DEVECO_HOME:-}" ] && [ -f "$DEVECO_HOME/tools/hvigor/bin/hvigorw.js" ]; then
    printf '%s' "$DEVECO_HOME"; return
  fi
  for c in \
    "/Applications/DevEco-Studio.app/Contents" \
    "$HOME/DevEco-Studio" "$HOME/deveco-studio" \
    "/opt/deveco-studio" "/opt/DevEco-Studio" "/usr/local/deveco-studio"; do
    if [ -f "$c/tools/hvigor/bin/hvigorw.js" ]; then printf '%s' "$c"; return; fi
  done
}

DEVECO="$(find_deveco || true)"
if [ -z "$DEVECO" ]; then
  echo "error: DevEco Studio not found. Set DEVECO_HOME." >&2
  exit 1
fi
HVIGOR="$DEVECO/tools/hvigor/bin/hvigorw.js"

NODE=""
for n in "$DEVECO/tools/node/bin/node" "$DEVECO/tools/node/node"; do
  if [ -x "$n" ]; then NODE="$n"; break; fi
done
if [ -z "$NODE" ]; then NODE="$(command -v node || true)"; fi
if [ -z "$NODE" ]; then
  echo "error: node not found (expected $DEVECO/tools/node or node on PATH)." >&2
  exit 1
fi

if [ -z "${JAVA_HOME:-}" ] && [ -d "$DEVECO/jbr" ]; then
  export JAVA_HOME="$DEVECO/jbr"
fi
if [ -n "${JAVA_HOME:-}" ]; then export PATH="$JAVA_HOME/bin:$PATH"; fi

if [ ! -f "$RAWFILE/laya_en_w8_s256.ms" ] && [ "${GUARDIAN_SKIP_FETCH:-0}" != "1" ]; then
  echo "[*] on-device models missing; fetching from Hugging Face..."
  PY="$(command -v python3 || command -v python || true)"
  if [ -z "$PY" ]; then
    echo "error: python not found; cannot fetch models (or set GUARDIAN_SKIP_FETCH=1)." >&2
    exit 1
  fi
  "$PY" "$ROOT/tools/fetch_model.py" --out-dir "$ROOT"
fi

export DEVECO_SDK_HOME="$DEVECO/sdk"
export NODE_HOME="$DEVECO/tools/node"
export PATH="$DEVECO/tools/node:$DEVECO/tools/ohpm/bin:$PATH"

echo "[*] building entry (DevEco: $DEVECO)"
cd "$PROJECT"
if [ "${GUARDIAN_CLEAN:-0}" = "1" ]; then
  "$NODE" "$HVIGOR" --mode module -p module=entry@default -p product=default clean --no-daemon
fi
"$NODE" "$HVIGOR" --mode module -p module=entry@default -p product=default \
  -p requiredDeviceType=phone assembleHap --no-daemon

OUT="$PROJECT/entry/build/default/outputs/default"
echo "[+] done. HAP in $OUT"
find "$OUT" -maxdepth 1 -name '*.hap' -exec ls -lh {} \; 2>/dev/null || true
