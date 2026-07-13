#!/usr/bin/env python3

import os
import plistlib
import sys

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 2 * 1024 * 1024:
        try:
            with open(f, "rb") as fh:
                plistlib.load(fh)
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed Plist: {e}")
sys.exit(1 if errors else 0)
