#!/usr/bin/env python3

import os
import sys

import yaml

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f):
        try:
            with open(f, "r") as fh:
                for doc in yaml.safe_load_all(fh):
                    if doc and "apiVersion" in doc and "crossplane.io" in doc["apiVersion"]:
                        if "kind" not in doc:
                            errors.append(f"{f} (metadata incomplete)")
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed Crossplane Manifest: {e}")
sys.exit(1 if errors else 0)
