#!/usr/bin/env python3

import csv
import os
import sys

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 5 * 1024 * 1024:
        try:
            with open(f, "r", encoding="utf-8", newline="") as fh:
                reader = csv.reader(fh)
                header = next(reader, None)
                if header:
                    cols = len(header)
                    for i, row in enumerate(reader, 2):
                        if len(row) != cols:
                            errors.append(f"{f}:{i} (expected {cols} columns, got {len(row)})")
                            break
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"CSV/TSV inconsistency: {e}")
sys.exit(1 if errors else 0)
