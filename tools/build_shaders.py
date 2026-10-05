#!/usr/bin/env python3
"""Compile shaders/src/*.frag into the .qsb files TOMO-TV loads.

Only needed after editing a shader:  python tools/build_shaders.py
Uses pyside6-qsb, which comes with PySide6.
"""

import glob
import os
import shutil
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "shaders", "src")
OUT = os.path.join(ROOT, "shaders")


def find_qsb() -> str:
    candidates = [shutil.which("pyside6-qsb"), os.path.join(os.path.dirname(sys.executable), "pyside6-qsb")]
    for c in candidates:
        if c and os.path.exists(c):
            return c
    sys.exit("pyside6-qsb not found; install PySide6 first.")


def main() -> int:
    qsb = find_qsb()
    with open(os.path.join(SRC, "common.glsl"), encoding="utf-8") as f:
        common = f.read()
    with tempfile.TemporaryDirectory() as tmp:
        for path in sorted(glob.glob(os.path.join(SRC, "*.frag"))):
            name = os.path.basename(path)
            with open(path, encoding="utf-8") as f:
                body = f.read().replace('#include "common.glsl"', common)
            src = os.path.join(tmp, name)
            with open(src, "w", encoding="utf-8") as f:
                f.write(body)
            out = os.path.join(OUT, name + ".qsb")
            cmd = [qsb, "--glsl", "300 es,120,150", "--hlsl", "50", "--msl", "12", "-o", out, src]
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                print(f"FAILED {name}\n{result.stdout}{result.stderr}")
                return 1
            print(f"ok  {name} -> {os.path.relpath(out, ROOT)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
