#!/usr/bin/env python3

import configparser
import os
import sys

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 1024 * 1024:
        try:
            cp = configparser.ConfigParser()
            cp.read(f, encoding="utf-8")
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed INI: {e}")
sys.exit(1 if errors else 0)
