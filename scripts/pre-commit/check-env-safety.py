#!/usr/bin/env python3

import os
import re
import sys

errors = []
# Simple regex for high-entropy strings or common secret patterns
SECRET_REGEX = re.compile(r"=[a-zA-Z0-9/\+]{20,}")
for f in sys.argv[1:]:
    if os.path.isfile(f):
        with open(f, "r", encoding="utf-8", errors="ignore") as fh:
            for i, line in enumerate(fh, 1):
                if "=" in line and not line.strip().startswith("#"):
                    val = line.split("=", 1)[1].strip()
                    if val and (
                        SECRET_REGEX.search(line)
                        or any(
                            k in val.lower()
                            for k in [
                                "pk_",
                                "sk_",
                                "key_",
                                "token_",
                                "secret_",
                                "passwd_",
                                "api_key",
                                "access_token",
                                "refresh_token",
                            ]
                        )
                    ):
                        if "your_" not in val.lower() and "<" not in val:
                            errors.append(f"{f}:{i} (potential real secret detected)")
for e in errors:
    print(f"Unsafe Env File: {e}")
sys.exit(1 if errors else 0)
