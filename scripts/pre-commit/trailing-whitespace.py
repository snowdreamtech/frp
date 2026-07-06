#!/usr/bin/env python3

import os
import re
import sys

modified = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 2 * 1024 * 1024:
        with open(f, "rb") as fh:
            content = fh.read()
        new_content = re.sub(b"[ \t]+(?=\r?\n|$)", b"", content)
        if content != new_content:
            with open(f, "wb") as fh:
                fh.write(new_content)
            modified.append(f)
for f in modified:
    print(f"Fixing trailing whitespace in: {f}")
sys.exit(1 if modified else 0)
