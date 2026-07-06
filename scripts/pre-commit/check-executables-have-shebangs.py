#!/usr/bin/env python3

import os
import stat
import sys

if os.name == "nt":
    sys.exit(0)
missing = []
for f in sys.argv[1:]:
    if os.path.isfile(f):
        mode = os.stat(f).st_mode
        # Check if any execution bit is set (Owner, Group, or Others)
        if mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH):
            with open(f, "rb") as fh:
                head = fh.read(2)
                if head != b"#!":
                    missing.append(f)
for f in missing:
    print(f"Executable lacks shebang: {f}")
sys.exit(1 if missing else 0)
