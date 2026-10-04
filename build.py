#!/usr/bin/env python3
"""Build the Guardian app HAP (the `entry` module only — not the mocks).

Cross-platform (Windows / macOS / Linux). Ensures the on-device models are
present (downloads them from Hugging Face via tools/fetch_model.py when missing),
then runs hvigor's ``assembleHap`` for the ``entry`` module.

Env overrides: DEVECO_HOME, JAVA_HOME, GUARDIAN_SKIP_FETCH=1, GUARDIAN_CLEAN=1.

    python build.py [--deveco PATH] [--java-home PATH] [--clean] [--skip-fetch]
"""
from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT / "HuwaweiChallenge"
RAWFILE = PROJECT / "entry" / "src" / "main" / "resources" / "rawfile"

DEVECO_CANDIDATES = {
    "nt": [r"C:\Program Files\Huawei\DevEco Studio"],
    "darwin": ["/Applications/DevEco-Studio.app/Contents"],
    "linux": ["~/DevEco-Studio", "~/deveco-studio", "/opt/deveco-studio",
              "/opt/DevEco-Studio", "/usr/local/deveco-studio"],
}


def find_deveco(hint: str | None) -> Path | None:
    cands: list[str] = []
    if hint:
        cands.append(hint)
    if os.environ.get("DEVECO_HOME"):
        cands.append(os.environ["DEVECO_HOME"])
    cands.extend(DEVECO_CANDIDATES.get(os.name, []))
    for c in cands:
        p = Path(os.path.expanduser(c))
        if (p / "tools" / "hvigor" / "bin" / "hvigorw.js").is_file():
            return p
    return None


def find_node(deveco: Path) -> str | None:
    for rel in ("tools/node/node.exe", "tools/node/bin/node", "tools/node/node"):
        n = deveco / rel
        if n.is_file():
            return str(n)
    return shutil.which("node")


def run(cmd: list[str], cwd: Path, env: dict) -> None:
    print("[*] " + " ".join(cmd))
    subprocess.run(cmd, cwd=str(cwd), env=env, check=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--deveco", default=os.environ.get("DEVECO_HOME"))
    ap.add_argument("--java-home", default=os.environ.get("JAVA_HOME"))
    ap.add_argument("--clean", action="store_true")
    ap.add_argument("--skip-fetch", action="store_true")
    args = ap.parse_args()

    deveco = find_deveco(args.deveco)
    if deveco is None:
        print("error: DevEco Studio not found. Set DEVECO_HOME or pass --deveco.", file=sys.stderr)
        return 1
    node = find_node(deveco)
    if node is None:
        print("error: node not found (expected under DevEco/tools/node or on PATH).", file=sys.stderr)
        return 1
    hvigor = deveco / "tools" / "hvigor" / "bin" / "hvigorw.js"

    java_home = args.java_home
    if not java_home and (deveco / "jbr").is_dir():
        java_home = str(deveco / "jbr")

    # 1. models
    if not (RAWFILE / "laya_en_w8_s256.ms").is_file() and not args.skip_fetch:
        print("[*] on-device models missing; fetching from Hugging Face...")
        subprocess.run([sys.executable, str(ROOT / "tools" / "fetch_model.py"), "--out-dir", str(ROOT)],
                       check=True)

    # 2. build `entry` only
    env = dict(os.environ)
    env["DEVECO_SDK_HOME"] = str(deveco / "sdk")
    env["NODE_HOME"] = str(deveco / "tools" / "node")
    extra = os.pathsep.join([str(deveco / "tools" / "node"), str(deveco / "tools" / "ohpm" / "bin")])
    env["PATH"] = extra + os.pathsep + env.get("PATH", "")
    if java_home:
        env["JAVA_HOME"] = java_home
        env["PATH"] = os.path.join(java_home, "bin") + os.pathsep + env["PATH"]

    print(f"[*] building entry (DevEco: {deveco})")
    if args.clean:
        run([node, str(hvigor), "--mode", "module", "-p", "module=entry@default",
             "-p", "product=default", "clean", "--no-daemon"], PROJECT, env)
    run([node, str(hvigor), "--mode", "module", "-p", "module=entry@default",
         "-p", "product=default", "-p", "requiredDeviceType=phone",
         "assembleHap", "--no-daemon"], PROJECT, env)

    out = PROJECT / "entry" / "build" / "default" / "outputs" / "default"
    print(f"[+] done. HAP in {out}")
    for hap in sorted(out.glob("*.hap")):
        print(f"    {hap.name:<34} {hap.stat().st_size / 1048576:8.1f} MB")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
