#!/usr/bin/env python3

import os
import re
import sys

pattern = re.compile(b"-----BEG" + b"IN .*PRIVATE KEY-----")
found = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 1024 * 1024:
        with open(f, "rb") as fh:
            if pattern.search(fh.read()):
                found.append(f)
for f in found:
    print(f"Private key detected: {f}")
sys.exit(1 if found else 0)
