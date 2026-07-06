#!/usr/bin/env python3

import os
import sys

import yaml

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f):
        try:
            with open(f, "r") as fh:
                cfg = yaml.safe_load(fh)
                if "name" not in cfg or "runtime" not in cfg:
                    errors.append(f"{f} (missing name or runtime)")
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed Pulumi Config: {e}")
sys.exit(1 if errors else 0)
