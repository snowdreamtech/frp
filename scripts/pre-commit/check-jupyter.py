#!/usr/bin/env python3

import json
import os
import sys

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 10 * 1024 * 1024:
        try:
            with open(f, "r", encoding="utf-8") as fh:
                nb = json.load(fh)
                if "cells" not in nb:
                    errors.append(f"{f} (missing cells)")
                for i, cell in enumerate(nb.get("cells", [])):
                    if len(str(cell.get("outputs", []))) > 100000:
                        errors.append(f"{f}:cell {i} (output too large, please strip)")
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed/Heavy Jupyter Notebook: {e}")
sys.exit(1 if errors else 0)
