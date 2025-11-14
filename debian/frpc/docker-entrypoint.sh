#!/bin/sh
set -e

if [ "$DEBUG" = "true" ]; then echo "→ [ENTRYPOINT] Executing all scripts in /usr/local/bin/entrypoint.d"; fi    

for script in /usr/local/bin/entrypoint.d/*; do
  if [ -x "$script" ]; then
    if [ "$DEBUG" = "true" ]; then echo "→ Running $script"; fi    
    "$script" "$@"
  else
    if [ "$DEBUG" = "true" ]; then echo "⚠️ Skipping $script (not executable)"; fi    
  fi
done


if [ "$DEBUG" = "true" ]; then echo "→ [ENTRYPOINT] Done."; fi    
