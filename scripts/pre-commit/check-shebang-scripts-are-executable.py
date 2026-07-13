#!/usr/bin/env python3

import os
import stat
import sys

if os.name == "nt":
    sys.exit(0)
not_exec = []
for f in sys.argv[1:]:
    if os.path.isfile(f):
        mode = os.stat(f).st_mode
        # Check if any execution bit is set (Owner, Group, or Others)
        if not (mode & (stat.S_IXUSR | stat.S_IXGRP | stat.S_IXOTH)):
            with open(f, "rb") as fh:
                if fh.read(2) == b"#!":
                    not_exec.append(f)
for f in not_exec:
    print(f"Shebang script not executable: {f}")
sys.exit(1 if not_exec else 0)
