#!/usr/bin/env python3

import sys, os, re
errors = []
for f in sys.argv[1:]:
    if os.path.isfile(f) and os.path.getsize(f) < 5*1024*1024:
        try:
            with open(f, 'rb') as fh:
                content = fh.read().lower()
                if b'<script' in content or re.search(b' on\w+=', content):
                    errors.append(f'{f} (contains potential script injection)')
        except Exception as e: errors.append(f'{f} ({e})')
for e in errors: print(f'Unsafe SVG detected: {e}')
sys.exit(1 if errors else 0)
