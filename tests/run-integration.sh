#!/usr/bin/env bash
# On-device integration tests for the Guardian SDK trigger (hypium / ohosTest).
#
# Builds the app + test HAP, installs both on the connected emulator/device and
# runs the `ohosTest` suite. Requires a running OpenHarmony/Oniro emulator.
#
#   tests/run-integration.sh
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
proj="$repo/HuwaweiChallenge"
bundle="com.example.huwaweichallenge"
test_module="entry_test"
runner="OpenHarmonyTestRunner"

# shellcheck disable=SC1091
source "$repo/.opencode/skills/run-openharmony-app/scripts/env.sh"

echo "== connect =="
hdc tconn 127.0.0.1:55555 >/dev/null 2>&1 || true
if ! hdc list targets 2>/dev/null | grep -q '127.0.0.1'; then
  echo "no device on 127.0.0.1:55555 (start the emulator first)" >&2
  exit 2
fi

echo "== build app + test hap =="
oniro-app build "$proj" >&2
oniro-app build "$proj" --module entry@ohosTest --task assembleHap >&2

app_hap="$proj/entry/build/default/outputs/default/entry-default-signed.hap"
test_hap="$proj/entry/build/default/outputs/ohosTest/entry-ohosTest-signed.hap"

echo "== install =="
hdc install -r "$app_hap"
hdc install -r "$test_hap"

echo "== run ohosTest =="
hdc shell "aa test -b $bundle -m $test_module -s unittest $runner -s timeout 60000"
