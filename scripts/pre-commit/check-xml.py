#!/usr/bin/env python3

import os
import sys
import xml.etree.ElementTree as ET

errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 5 * 1024 * 1024:
        try:
            ET.parse(f)
        except Exception as e:
            errors.append(f"{f} ({e})")
for e in errors:
    print(f"Malformed XML: {e}")
sys.exit(1 if errors else 0)
