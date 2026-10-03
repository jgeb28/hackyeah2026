#!/usr/bin/env bash
# Source this for the OpenHarmony/Oniro toolchain.
#   source .opencode/skills/run-openharmony-app/scripts/env.sh
export PATH="$HOME/.local/bin:$HOME/ohos/command-line-tools/bin:$PATH"
export ONIRO_CMD_TOOLS_PATH="${ONIRO_CMD_TOOLS_PATH:-$HOME/ohos/command-line-tools}"
# API 20+ builds REQUIRE JDK 17. Under Java 27 the API 20/23 SDK's
# app_packing_tool.jar deletes the entire project directory. DevEco bundles 17.
export JAVA_HOME="${JAVA_HOME:-$HOME/ohos/jdk/jdk-17.0.20.1+1}"
export PATH="$JAVA_HOME/bin:$PATH"
# hdc lives in the SDK toolchains, not in the tools' bin/.
export DEVECO_SDK_HOME="${DEVECO_SDK_HOME:-$HOME/ohos/command-line-tools/sdk}"
export PATH="$PATH:$DEVECO_SDK_HOME/default/openharmony/toolchains"
# NOTE: deliberately do NOT add the SDK's bundled Node 18 here.
# oniro-app requires Node >= 20 and crashes on Node 18.
