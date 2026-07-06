#!/usr/bin/env python3

import os
import re
import sys

pattern = re.compile(
    r"(test\.txt|tmp\.json|debug\.log|\.DS_Store|Thumbs\.db|\.swp|\.bak|\\.orig|\\.rej|\\.coverage|\\.map|npm-debug\.log|\\.env)$"
)
forbidden = [f for f in sys.argv[1:] if os.path.isfile(f) and pattern.search(f)]
for f in forbidden:
    print(f"Forbidden file detected: {f}")
sys.exit(1 if forbidden else 0)
