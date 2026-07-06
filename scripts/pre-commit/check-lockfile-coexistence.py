#!/usr/bin/env python3

import os
import sys

dirs = set(os.path.dirname(f) or "." for f in sys.argv[1:])
conflicts = []
for d in dirs:
    files = os.listdir(d)
    if "package-lock.json" in files and "pnpm-lock.yaml" in files:
        conflicts.append(f"{d} (both package-lock.json and pnpm-lock.yaml found)")
    if "package-lock.json" in files and "yarn.lock" in files:
        conflicts.append(f"{d} (both package-lock.json and yarn.lock found)")
    if "package-lock.json" in files and "bun.lockb" in files:
        conflicts.append(f"{d} (both package-lock.json and bun.lockb found)")
    if "pnpm-lock.yaml" in files and "yarn.lock" in files:
        conflicts.append(f"{d} (both pnpm-lock.yaml and yarn.lock found)")
    if "pnpm-lock.yaml" in files and "bun.lockb" in files:
        conflicts.append(f"{d} (both pnpm-lock.yaml and bun.lockb found)")
    if "yarn.lock" in files and "bun.lockb" in files:
        conflicts.append(f"{d} (both yarn.lock and bun.lockb found)")
for c in conflicts:
    print(f"Conflicting lockfiles detected: {c}")
sys.exit(1 if conflicts else 0)
