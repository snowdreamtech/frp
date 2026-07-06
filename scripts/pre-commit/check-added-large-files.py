#!/usr/bin/env python3

import os
import sys

large_files = [f for f in sys.argv[1:] if os.path.isfile(f) and os.path.getsize(f) > 1024 * 1024]
for f in large_files:
    print(f"File too large (>1MB): {f}")
sys.exit(1 if large_files else 0)
