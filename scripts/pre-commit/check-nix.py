#!/usr/bin/env python3

import os
import sys

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 1024 * 1024:
        with open(f, "r", encoding="utf-8") as fh:
            content = fh.read()
            if content.count("{") != content.count("}") or content.count("[") != content.count("]"):
                errors.append(f"{f} (unbalanced braces/brackets)")
            if "=" in content and ";" not in content and "{" not in content:
                errors.append(f"{f} (potential missing semicolon)")
for e in errors:
    print(f"Malformed Nix: {e}")
sys.exit(1 if errors else 0)
