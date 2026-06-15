#!/usr/bin/env bash
SCRIPT_DIR="$(CDPATH="" cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH="" cd "$SCRIPT_DIR/../../.." && pwd)"

TARGET_VERSION="0.10.2"

if command -v specify >/dev/null 2>&1; then
    CURRENT_VERSION=$(specify --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [ -z "$CURRENT_VERSION" ]; then
        CURRENT_VERSION="0.0.0"
    fi
else
    CURRENT_VERSION="0.0.0"
fi

echo "Current specify version: $CURRENT_VERSION"
echo "Target specify version: $TARGET_VERSION"

LOWEST=$(printf "%s\n%s\n" "$CURRENT_VERSION" "$TARGET_VERSION" | sort -t. -k 1,1n -k 2,2n -k 3,3n | head -n 1)

if [ "$LOWEST" = "$CURRENT_VERSION" ] && [ "$CURRENT_VERSION" != "$TARGET_VERSION" ]; then
    echo "Upgrading specify-cli to version $TARGET_VERSION..."
    if ! uv tool install specify-cli --from "git+https://github.com/github/spec-kit.git@v${TARGET_VERSION}" --force; then
        echo "Error: Failed to upgrade specify-cli to version $TARGET_VERSION." >&2
        exit 1
    fi
fi

cd "$REPO_ROOT" || exit 1
specify init . --force --script sh --integration generic --integration-options="--commands-dir .specify/commands/"
