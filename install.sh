#!/bin/sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# install.sh — UniRTM installer for Linux and macOS
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/snowdreamtech/UniRTM/main/install.sh | sh
#   sh install.sh --version v0.7.0
#
# Environment variables:
#   GITHUB_PROXY  — Optional proxy prefix for GitHub downloads
#                   Default: https://gh-proxy.sn0wdr1am.com/
#   INSTALL_DIR   — Directory to install the binary (default: ~/.unirtm/bin, or /usr/local/bin if root)
#   UNIRTM_VERSION — Target version (overridden by --version flag)

set -eu

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
REPO="snowdreamtech/UniRTM"
BINARY="unirtm"
GITHUB_PROXY="${GITHUB_PROXY:-https://gh-proxy.sn0wdr1am.com/}"
UNIRTM_VERSION="${UNIRTM_VERSION:-}"

# Retry config
CURL_RETRY_COUNT=5
CURL_RETRY_DELAY=2
CURL_CONNECT_TIMEOUT=15
CURL_MAX_TIME=120

QUIET=0
LOG_FILE=""
SKIP_CHECKSUM=0

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
log_msg() {
  level="$1"
  color="$2"
  shift 2

  if [ -n "$LOG_FILE" ]; then
    printf '[%s] %s\n' "$level" "$*" >>"$LOG_FILE"
  fi

  if [ "$QUIET" -eq 1 ] && { [ "$level" = "INFO" ] || [ "$level" = "WARN" ]; }; then
    return
  fi

  if [ "$level" = "ERROR" ]; then
    printf '\033[0;%sm[%s]\033[0m %s\n' "$color" "$level" "$*" >&2
  else
    printf '\033[0;%sm[%s]\033[0m  %s\n' "$color" "$level" "$*" >&2
  fi
}

info() { log_msg "INFO" "32" "$*"; }
warn() { log_msg "WARN" "33" "$*"; }
error() { log_msg "ERROR" "31" "$*"; }
die() {
  error "$*"
  exit 1
}

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Required command not found: $1. Please install it and try again."
  fi
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
    --version | -v)
      shift
      UNIRTM_VERSION="$1"
      ;;
    --install-dir)
      shift
      INSTALL_DIR="$1"
      ;;
    --no-proxy)
      GITHUB_PROXY=""
      ;;
    --quiet | -q)
      QUIET=1
      ;;
    --skip-checksum)
      SKIP_CHECKSUM=1
      ;;
    --log-file)
      shift
      LOG_FILE="$1"
      ;;
    --help | -h)
      printf 'Usage: install.sh [--version <tag>] [--install-dir <dir>] [--no-proxy] [--quiet] [--skip-checksum] [--log-file <path>]\n'
      exit 0
      ;;
    *)
      warn "Unknown argument: $1"
      ;;
    esac
    shift
  done
}

# ---------------------------------------------------------------------------
# Detect OS / Arch
# ---------------------------------------------------------------------------
detect_platform() {
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  case "$OS" in
  Linux) OS_NAME="Linux" ;;
  Darwin) OS_NAME="Darwin" ;;
  *) die "Unsupported operating system: $OS" ;;
  esac

  case "$ARCH" in
  x86_64 | amd64) ARCH_NAME="x86_64" ;;
  aarch64 | arm64) ARCH_NAME="arm64" ;;
  armv7*) ARCH_NAME="armv7" ;;
  armv6*) ARCH_NAME="armv6" ;;
  armv5*) ARCH_NAME="armv5" ;;
  i386 | i686) ARCH_NAME="i386" ;;
  riscv64) ARCH_NAME="riscv64" ;;
  ppc64le) ARCH_NAME="ppc64le" ;;
  loongarch64 | loong64) ARCH_NAME="loong64" ;;
  s390x) ARCH_NAME="s390x" ;;
  *) die "Unsupported architecture: $ARCH" ;;
  esac

  info "Detected platform: ${OS_NAME}/${ARCH_NAME}"
}

# ---------------------------------------------------------------------------
# Resolve target version
# ---------------------------------------------------------------------------
resolve_version() {
  if [ -n "$UNIRTM_VERSION" ]; then
    # Normalize: strip leading 'v' for comparison but keep tag form for URL
    VERSION="$UNIRTM_VERSION"
    # Ensure v-prefix for tag
    case "$VERSION" in
    v*) ;;
    *) VERSION="v${VERSION}" ;;
    esac
    info "Target version: ${VERSION}"
    return
  fi

  info "Fetching latest release from GitHub API..."
  API_URL="https://api.github.com/repos/${REPO}/releases/latest"

  # Try with proxy first, fall back to direct
  LATEST=""
  LATEST="$(curl_with_retry "$API_URL" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')"

  if [ -z "$LATEST" ]; then
    die "Failed to determine latest version. Please specify one with --version."
  fi

  VERSION="$LATEST"
  info "Latest version: ${VERSION}"
}

# ---------------------------------------------------------------------------
# Download with retry and proxy
# ---------------------------------------------------------------------------
curl_with_retry() {
  URL="$1"
  OUTPUT="${2:-}"

  # Apply proxy prefix to github.com URLs
  PROXIED_URL="$URL"
  case "$URL" in
  https://github.com/* | https://objects.githubusercontent.com/* | https://raw.githubusercontent.com/* | https://api.github.com/*)
    if [ -n "$GITHUB_PROXY" ]; then
      PROXIED_URL="${GITHUB_PROXY}${URL}"
    fi
    ;;
  esac

  # Choose fetcher based on availability
  if command -v curl >/dev/null 2>&1; then
    if [ -n "$OUTPUT" ]; then
      curl \
        --retry "$CURL_RETRY_COUNT" \
        --retry-delay "$CURL_RETRY_DELAY" \
        --retry-connrefused \
        --connect-timeout "$CURL_CONNECT_TIMEOUT" \
        --max-time "$CURL_MAX_TIME" \
        --fail \
        --location \
        --silent \
        --show-error \
        -o "$OUTPUT" \
        "$PROXIED_URL" || {
        # On failure, retry without proxy
        if [ "$PROXIED_URL" != "$URL" ]; then
          warn "Proxy download failed, retrying without proxy..."
          curl \
            --retry "$CURL_RETRY_COUNT" \
            --retry-delay "$CURL_RETRY_DELAY" \
            --retry-connrefused \
            --connect-timeout "$CURL_CONNECT_TIMEOUT" \
            --max-time "$CURL_MAX_TIME" \
            --fail \
            --location \
            --silent \
            --show-error \
            -o "$OUTPUT" \
            "$URL"
        else
          return 1
        fi
      }
    else
      curl \
        --retry "$CURL_RETRY_COUNT" \
        --retry-delay "$CURL_RETRY_DELAY" \
        --retry-connrefused \
        --connect-timeout "$CURL_CONNECT_TIMEOUT" \
        --max-time "$CURL_MAX_TIME" \
        --fail \
        --location \
        --silent \
        --show-error \
        "$PROXIED_URL" || {
        if [ "$PROXIED_URL" != "$URL" ]; then
          warn "Proxy request failed, retrying without proxy..."
          curl \
            --retry "$CURL_RETRY_COUNT" \
            --retry-delay "$CURL_RETRY_DELAY" \
            --retry-connrefused \
            --connect-timeout "$CURL_CONNECT_TIMEOUT" \
            --max-time "$CURL_MAX_TIME" \
            --fail \
            --location \
            --silent \
            --show-error \
            "$URL"
        else
          return 1
        fi
      }
    fi
  else
    # Fallback to wget
    if [ -n "$OUTPUT" ]; then
      wget \
        --tries="$CURL_RETRY_COUNT" \
        --waitretry="$CURL_RETRY_DELAY" \
        --timeout="$CURL_CONNECT_TIMEOUT" \
        -q -O "$OUTPUT" \
        "$PROXIED_URL" || {
        if [ "$PROXIED_URL" != "$URL" ]; then
          warn "Proxy download failed, retrying without proxy..."
          wget \
            --tries="$CURL_RETRY_COUNT" \
            --waitretry="$CURL_RETRY_DELAY" \
            --timeout="$CURL_CONNECT_TIMEOUT" \
            -q -O "$OUTPUT" \
            "$URL"
        else
          return 1
        fi
      }
    else
      wget \
        --tries="$CURL_RETRY_COUNT" \
        --waitretry="$CURL_RETRY_DELAY" \
        --timeout="$CURL_CONNECT_TIMEOUT" \
        -q -O - \
        "$PROXIED_URL" || {
        if [ "$PROXIED_URL" != "$URL" ]; then
          warn "Proxy request failed, retrying without proxy..."
          wget \
            --tries="$CURL_RETRY_COUNT" \
            --waitretry="$CURL_RETRY_DELAY" \
            --timeout="$CURL_CONNECT_TIMEOUT" \
            -q -O - \
            "$URL"
        else
          return 1
        fi
      }
    fi
  fi
}

# ---------------------------------------------------------------------------
# Download and verify checksum
# ---------------------------------------------------------------------------
download_and_verify() {
  TMP_DIR="$1"
  ARCHIVE_NAME="${BINARY}_${OS_NAME}_${ARCH_NAME}.tar.gz"
  ARCHIVE_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARCHIVE_NAME}"
  CHECKSUM_URL="https://github.com/${REPO}/releases/download/${VERSION}/checksums.txt"

  ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE_NAME}"
  CHECKSUM_PATH="${TMP_DIR}/checksums.txt"

  info "Downloading ${ARCHIVE_NAME}..."
  curl_with_retry "$ARCHIVE_URL" "$ARCHIVE_PATH"

  # Verify file is not empty
  if [ ! -s "$ARCHIVE_PATH" ]; then
    die "Downloaded archive is empty: ${ARCHIVE_PATH}"
  fi

  info "Downloading checksums..."
  if [ "$SKIP_CHECKSUM" -eq 1 ]; then
    warn "Skipping checksum verification due to --skip-checksum flag."
  elif curl_with_retry "$CHECKSUM_URL" "$CHECKSUM_PATH" 2>/dev/null; then
    info "Verifying checksum..."
    # Extract the expected checksum for our archive
    EXPECTED="$(grep -E "[[:space:]]${ARCHIVE_NAME}[[:space:]]*\$" "$CHECKSUM_PATH" | awk '{print $1}')"
    if [ -z "$EXPECTED" ]; then
      warn "Checksum entry not found for ${ARCHIVE_NAME}, skipping verification."
    else
      # Compute actual checksum
      if command -v sha256sum >/dev/null 2>&1; then
        ACTUAL="$(sha256sum "$ARCHIVE_PATH" | awk '{print $1}')"
      elif command -v shasum >/dev/null 2>&1; then
        ACTUAL="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
      else
        warn "No sha256sum or shasum available. Skipping checksum verification."
        ACTUAL="$EXPECTED"
      fi

      if [ "$EXPECTED" != "$ACTUAL" ]; then
        die "Checksum mismatch! Expected: ${EXPECTED}, Got: ${ACTUAL}"
      fi
      info "Checksum verified OK."
    fi
  else
    warn "Could not download checksums.txt. Skipping checksum verification."
  fi
}

# ---------------------------------------------------------------------------
# Install binary
# ---------------------------------------------------------------------------
install_binary() {
  ARCHIVE_PATH="$1"
  TMP_DIR="$2"

  # Determine install directory
  if [ -z "${INSTALL_DIR:-}" ]; then
    if [ "$(id -u)" = "0" ]; then
      INSTALL_DIR="/usr/local/bin"
    else
      INSTALL_DIR="$HOME/.local/bin"
    fi
  fi

  info "Installing to ${INSTALL_DIR}..."
  mkdir -p "$INSTALL_DIR"

  # Extract archive
  tar -xzf "$ARCHIVE_PATH" -C "$TMP_DIR"

  # Find the binary (may be inside a subdirectory)
  BINARY_PATH="$(find "$TMP_DIR" -name "$BINARY" -type f | head -1)"
  if [ -z "$BINARY_PATH" ]; then
    die "Binary '${BINARY}' not found in archive."
  fi

  chmod +x "$BINARY_PATH"

  # Prevent 'Text file busy' error and ensure rollback on failure
  if [ -f "${INSTALL_DIR}/${BINARY}" ]; then
    mv "${INSTALL_DIR}/${BINARY}" "${INSTALL_DIR}/${BINARY}.old" 2>/dev/null || true
  fi

  if ! cp "$BINARY_PATH" "${INSTALL_DIR}/${BINARY}"; then
    error "Failed to copy new binary to ${INSTALL_DIR}"
    if [ -f "${INSTALL_DIR}/${BINARY}.old" ]; then
      mv "${INSTALL_DIR}/${BINARY}.old" "${INSTALL_DIR}/${BINARY}" 2>/dev/null || true
      warn "Rolled back to previous version."
    fi
    exit 1
  fi

  rm -f "${INSTALL_DIR}/${BINARY}.old" 2>/dev/null || true

  info "Installed ${BINARY} to ${INSTALL_DIR}/${BINARY}"
}

# ---------------------------------------------------------------------------
# Update PATH hint
# ---------------------------------------------------------------------------
suggest_path() {
  # Check if INSTALL_DIR is already in PATH
  case ":$PATH:" in
  *":${INSTALL_DIR}:"*) return ;;
  esac

  warn "Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
  # shellcheck disable=SC2016
  printf '  export PATH="%s:$PATH"\n' "$INSTALL_DIR"
}

# ---------------------------------------------------------------------------
# Post-install verification
# ---------------------------------------------------------------------------
verify_install() {
  INSTALLED="${INSTALL_DIR}/${BINARY}"
  if [ ! -x "$INSTALLED" ]; then
    die "Verification failed: binary not found at ${INSTALLED}"
  fi

  INSTALLED_VER="$("$INSTALLED" version 2>/dev/null | grep '^unirtm version' || echo 'unknown')"
  printf '\033[0;32m\n'
  printf '  ==============================\n'
  printf '  UniRTM %s installed!\n' "${VERSION}"
  printf '  Binary : %s/%s\n' "${INSTALL_DIR}" "${BINARY}"
  printf '  Version: %s\n' "${INSTALLED_VER}"
  printf '  ==============================\n'
  printf '\033[0m\n'
  info "Installation complete!"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  parse_args "$@"

  if ! command -v curl >/dev/null 2>&1 && ! command -v wget >/dev/null 2>&1; then
    die "Required command not found: curl or wget. Please install one of them and try again."
  fi
  need_cmd tar

  detect_platform
  resolve_version

  TMP_DIR="$(mktemp -d)"
  # Ensure cleanup on exit
  trap 'rm -rf "$TMP_DIR"' EXIT

  download_and_verify "$TMP_DIR"

  ARCHIVE_NAME="${BINARY}_${OS_NAME}_${ARCH_NAME}.tar.gz"
  ARCHIVE_PATH="${TMP_DIR}/${ARCHIVE_NAME}"

  install_binary "$ARCHIVE_PATH" "$TMP_DIR"
  suggest_path
  verify_install
}

main "$@"
