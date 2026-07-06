#!/usr/bin/env python3

import os
import sys

found = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) > 3:
        with open(f, "rb") as fh:
            if fh.read(3) == b"\xef\xbb\xbf":
                found.append(f)
for f in found:
    print(f"Illegal UTF-8 BOM detected: {f}")
sys.exit(1 if found else 0)
