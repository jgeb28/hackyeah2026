#!/usr/bin/env python3
"""Fetch the LAY A classifier (`laya_en_w8_s256.ms`) into `rawfile/`.

The ~412 MB MindSpore Lite model is **not committed** (over GitHub's 100 MB file
limit). Host it on **Hugging Face** or as a **GitHub Release** asset, then run this
to place it where the app bundles it:

    python tools/fetch_model.py --url https://huggingface.co/<org>/<repo>/resolve/main/laya_en_w8_s256.ms
    # or set GUARDIAN_MODEL_URL in the environment

Stdlib only (urllib). Streams to a `.part` file, then verifies the MindSpore Lite
magic (`MSL2`) and the size before moving it into place. Use `--gz` if you host a
gzip of the model.
"""
from __future__ import annotations

import argparse
import gzip
import os
import shutil
import sys
import urllib.request

MAGIC = b"\x28\x00\x00\x00MSL2"  # MindSpore Lite / MINDIR_LITE file header
DEFAULT_OUT = "HuwaweiChallenge/entry/src/main/resources/rawfile/laya_en_w8_s256.ms"


def download(url: str, dest: str) -> None:
    tmp = dest + ".part"
    req = urllib.request.Request(url, headers={"User-Agent": "guardian-fetch"})
    with urllib.request.urlopen(req) as r, open(tmp, "wb") as f:
        total = int(r.headers.get("Content-Length", 0))
        done = 0
        while True:
            chunk = r.read(1024 * 1024)
            if not chunk:
                break
            f.write(chunk)
            done += len(chunk)
            if total:
                print("\r  %5.1f%%  (%.0f / %.0f MB)" % (100.0 * done / total, done / 1048576, total / 1048576), end="")
    print()
    if total and os.path.getsize(tmp) != total:
        raise SystemExit("size mismatch: got %d, expected %d" % (os.path.getsize(tmp), total))
    shutil.move(tmp, dest)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--url", default=os.environ.get("GUARDIAN_MODEL_URL", ""),
                    help="direct download URL (or set GUARDIAN_MODEL_URL)")
    ap.add_argument("--out", default=DEFAULT_OUT, help="destination .ms path")
    ap.add_argument("--gz", action="store_true", help="the download is gzip-compressed; decompress it")
    args = ap.parse_args()

    if not args.url:
        print("error: pass --url or set GUARDIAN_MODEL_URL", file=sys.stderr)
        return 2

    os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
    print("[fetch] %s" % args.url)
    download(args.url, args.out)

    if args.gz:
        print("[fetch] gunzip")
        with gzip.open(args.out, "rb") as src, open(args.out + ".raw", "wb") as dst:
            shutil.copyfileobj(src, dst, 1024 * 1024)
        shutil.move(args.out + ".raw", args.out)

    with open(args.out, "rb") as f:
        head = f.read(8)
    if head != MAGIC:
        print("error: %s is not a MindSpore Lite model (bad magic)" % args.out, file=sys.stderr)
        return 1

    print("[fetch] ok: %s (%.0f MB)" % (args.out, os.path.getsize(args.out) / 1048576))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
