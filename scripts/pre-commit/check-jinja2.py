#!/usr/bin/env python3

import os
import sys

try:
    from jinja2 import Environment

    env = Environment()
except ImportError:
    env = None
errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 1024 * 1024:
        with open(f, "r", encoding="utf-8") as fh:
            content = fh.read()
            if env:
                try:
                    env.parse(content)
                except Exception as e:
                    errors.append(f"{f} ({e})")
            else:
                if content.count("{{") != content.count("}}") or content.count("{%") != content.count("%}"):
                    errors.append(f"{f} (unbalanced delimiters)")
for e in errors:
    print(f"Malformed Jinja2: {e}")
sys.exit(1 if errors else 0)
