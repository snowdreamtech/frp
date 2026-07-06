#!/usr/bin/env python3

import os
import re
import sys

conflicts = []
for f in sys.argv[1:]:
    if os.path.isfile(f):
        with open(f, "r", errors="ignore") as fh:
            for line in fh:
                if re.match(r"^(<<<<<<<|=======|>>>>>>>|\|\|\|\|\|\|\|)", line):
                    conflicts.append(f)
                    break
for f in conflicts:
    print(f"Unresolved merge conflict in lockfile: {f}")
sys.exit(1 if conflicts else 0)
