#!/usr/bin/env python3

import os
import sys

try:
    import tomllib as toml
except ImportError:
    try:
        import tomli as toml
    except ImportError:
        sys.exit(0)
errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 2 * 1024 * 1024:
        try:
            with open(f, "rb") as fh:
                toml.load(fh)
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed TOML: {e}")
sys.exit(1 if errors else 0)
