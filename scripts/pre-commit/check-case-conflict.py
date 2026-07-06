#!/usr/bin/env python3

import os
import sys

dirs = set(os.path.dirname(f) or "." for f in sys.argv[1:])
clashing = []
for d in dirs:
    files = os.listdir(d)
    freq = {}
    for f in files:
        low = f.lower()
        freq[low] = freq.get(low, 0) + 1
    for f in files:
        if freq[f.lower()] > 1:
            clashing.append(os.path.join(d, f))
for f in sorted(set(clashing)):
    print(f"Case collision: {f}")
sys.exit(1 if clashing else 0)
