#!/usr/bin/env python3

import os
import sys

errors = []
allowed = {"tap", "brew", "cask", "mas", "vscode", "whalebrew"}
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 1024 * 1024:
        with open(f, "r", encoding="utf-8") as fh:
            for i, line in enumerate(fh, 1):
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                cmd = line.split()[0] if line.split() else ""
                if cmd not in allowed:
                    errors.append(f"{f}:{i} (unknown command: {cmd})")
for e in errors:
    print(f"Malformed Brewfile: {e}")
sys.exit(1 if errors else 0)
