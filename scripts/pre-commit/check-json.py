#!/usr/bin/env python3

import json
import os
import sys

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 2 * 1024 * 1024:
        try:
            with open(f, "r", encoding="utf-8") as fh:
                json.load(fh)
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed JSON: {e}")
sys.exit(1 if errors else 0)
