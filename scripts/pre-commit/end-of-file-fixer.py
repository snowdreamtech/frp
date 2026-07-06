#!/usr/bin/env python3

import os
import sys

modified = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 2 * 1024 * 1024:
        with open(f, "rb") as fh:
            content = fh.read()
        if not content:
            continue
        stripped = content.rstrip(b"\r\n")
        newline = b"\r\n" if b"\r\n" in content else b"\n"
        new_content = stripped + newline
        if content != new_content:
            with open(f, "wb") as fh:
                fh.write(new_content)
            modified.append(f)
for f in modified:
    print(f"Fixing end of file in: {f}")
sys.exit(1 if modified else 0)
