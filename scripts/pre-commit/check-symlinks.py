#!/usr/bin/env python3

import os
import sys

broken = [f for f in sys.argv[1:] if os.path.islink(f) and not os.path.exists(f)]
for f in broken:
    print(f"Broken symlink: {f}")
sys.exit(1 if broken else 0)
