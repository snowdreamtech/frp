#!/bin/sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.

# .devcontainer/init.sh — Devcontainer initialization script
# Purpose: Set up unirtm, GPG, and git configuration for development environment
# Compatibility: POSIX shell (sh, bash, zsh, dash)

set -eu

# Disable unirtm/mise config trust errors in this script
export UNIRTM_IGNORE_MISE_TOML=1
export UNIRTM_WARN_UNTRUSTED=0
export MISE_IGNORE_MISE_TOML=1
export MISE_WARN_UNTRUSTED=0

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verbosity control
VERBOSE="${VERBOSE:-0}"
DEBUG="${DEBUG:-0}" # Use 0 or 1, not 'false'
LOG_FILE="${LOG_FILE:-}"
SKIP_DEPS="${SKIP_DEPS:-0}"

# Convert string booleans to 0/1 for arithmetic comparisons
case "$DEBUG" in true | yes | 1) DEBUG=1 ;; false | no | 0 | "") DEBUG=0 ;; esac
case "$VERBOSE" in true | yes | 1) VERBOSE=1 ;; false | no | 0 | "") VERBOSE=0 ;; esac
case "$SKIP_DEPS" in true | yes | 1) SKIP_DEPS=1 ;; false | no | 0 | "") SKIP_DEPS=0 ;; esac

# Counters for summary
WARNINGS=0
ERRORS=0
START_TIME=$(date +%s)

log_info() {
  echo "${BLUE}ℹ $*${NC}"
  [ -n "$LOG_FILE" ] && echo "INFO: $*" >>"$LOG_FILE" || true
}
log_success() {
  echo "${GREEN}✓ $*${NC}"
  [ -n "$LOG_FILE" ] && echo "SUCCESS: $*" >>"$LOG_FILE" || true
}
log_step() {
  echo "${GREEN}$*${NC}"
  [ -n "$LOG_FILE" ] && echo "STEP: $*" >>"$LOG_FILE" || true
}
log_warning() {
  echo "${YELLOW}⚠ $*${NC}"
  WARNINGS=$((WARNINGS + 1))
  [ -n "$LOG_FILE" ] && echo "WARN: $*" >>"$LOG_FILE" || true
}
log_error() {
  echo "${RED}✗ $*${NC}"
  ERRORS=$((ERRORS + 1))
  [ -n "$LOG_FILE" ] && echo "ERROR: $*" >>"$LOG_FILE" || true
}
log_detail() {
  [ "$VERBOSE" -eq 1 ] && echo "${YELLOW}  $*${NC}" || true
  [ -n "$LOG_FILE" ] && echo "DETAIL: $*" >>"$LOG_FILE" || true
}

echo "${BLUE}=== Initializing Devcontainer ===${NC}"
log_detail "Start time: $(date)"

# Step 0: Trust unirtm configuration early (before any operations)
if command -v unirtm >/dev/null 2>&1; then
  # Try to trust unirtm configurations - retry up to 3 times
  UNIRTM_TRUST_ATTEMPTS=0
  UNIRTM_TRUST_MAX=3
  while [ $UNIRTM_TRUST_ATTEMPTS -lt $UNIRTM_TRUST_MAX ]; do
    UNIRTM_TRUST_ATTEMPTS=$((UNIRTM_TRUST_ATTEMPTS + 1))
    if unirtm trust -a 2>/dev/null; then
      log_detail "unirtm configuration pre-trusted (attempt $UNIRTM_TRUST_ATTEMPTS)"
      break
    elif [ $UNIRTM_TRUST_ATTEMPTS -lt $UNIRTM_TRUST_MAX ]; then
      log_detail "unirtm trust attempt $UNIRTM_TRUST_ATTEMPTS/$UNIRTM_TRUST_MAX failed, retrying..."
      sleep 1
    else
      log_detail "unirtm trust failed after $UNIRTM_TRUST_MAX attempts (continuing anyway)"
    fi
  done || true
fi

# Step 1: Copy host configurations (if available)
log_step "📋 Copying host configurations..."
HOST_HOME="${HOST_HOME:-/host-home}"

# Copy .ssh if available from host (preserve permissions)
if [ -d "$HOST_HOME/.ssh" ]; then
  if cp -r "$HOST_HOME/.ssh" "$HOME/.ssh" 2>/dev/null; then
    chmod 700 "$HOME/.ssh"
    # Set correct permissions for SSH keys
    for key in "$HOME"/.ssh/id_* "$HOME"/.ssh/*_rsa "$HOME"/.ssh/*_ed25519 "$HOME"/.ssh/*_ecdsa; do
      [ -f "$key" ] && [ ! -f "$key.pub" ] && chmod 600 "$key"
    done
    log_detail "Copied .ssh from host"
  else
    log_warning "Failed to copy .ssh"
  fi
else
  # Create empty .ssh directory if host doesn't have one
  mkdir -p "$HOME/.ssh"
  chmod 700 "$HOME/.ssh"
  log_detail "Created empty .ssh directory"
fi

# Copy .gitconfig if available from host
if [ -f "$HOST_HOME/.gitconfig" ]; then
  if cp "$HOST_HOME/.gitconfig" "$HOME/.gitconfig" 2>/dev/null; then
    log_detail "Copied .gitconfig from host"
  else
    log_warning "Failed to copy .gitconfig"
  fi
fi

# Copy .gitconfig.local if available from host
if [ -f "$HOST_HOME/.gitconfig.local" ]; then
  cp "$HOST_HOME/.gitconfig.local" "$HOME/.gitconfig.local" 2>/dev/null && log_detail "Copied .gitconfig.local from host"
fi

# Copy .gnupg if available from host (preserve permissions)
if [ -d "$HOST_HOME/.gnupg" ]; then
  if cp -r "$HOST_HOME/.gnupg" "$HOME/.gnupg" 2>/dev/null; then
    chmod 700 "$HOME/.gnupg"
    log_detail "Copied .gnupg from host"
  else
    log_warning "Failed to copy .gnupg"
  fi
fi

# Step 2: Check prerequisite tools
log_step "🔧 Checking prerequisite tools..."
MISSING_TOOLS=""
for tool in git gpg ssh; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    log_warning "$tool not found in PATH"
    MISSING_TOOLS="$MISSING_TOOLS $tool"
  else
    log_detail "$tool available at $(command -v "$tool")"
  fi
done

# Check Docker availability (optional but recommended)
if command -v docker >/dev/null 2>&1; then
  if [ -S /var/run/docker.sock ]; then
    if docker ps >/dev/null 2>&1; then
      DOCKER_VERSION=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "unknown")
      log_detail "Docker available (server: $DOCKER_VERSION)"
    else
      log_warning "Docker socket exists but not accessible (permission issue?)"
    fi
  else
    log_warning "Docker command found but socket not available at /var/run/docker.sock"
  fi
else
  log_detail "Docker client not installed in container (optional)"
fi

# Step 3: Detect environment
log_step "🔍 Detecting container environment..."
if [ -f /.dockerenv ]; then
  log_detail "Running in Docker container"
elif grep -qi docker /proc/1/cgroup 2>/dev/null; then
  log_detail "Running in containerized environment"
else
  log_detail "Running in standard environment"
fi
CONTAINER_USER="${CONTAINER_USER:-$(whoami)}"
log_detail "Container user: $CONTAINER_USER"
log_detail "Home directory: $HOME"

# Step 4: Verify home directory permissions
log_step "🏠 Verifying home directory..."
if [ ! -d "$HOME" ]; then
  log_error "Home directory not found: $HOME"
elif [ ! -w "$HOME" ]; then
  log_error "Home directory not writable: $HOME"
else
  HOME_PERMS=$(find "$HOME" -maxdepth 0 -ls 2>/dev/null | awk '{print $3}' || echo "unknown")
  log_detail "Home permissions: $HOME_PERMS"
  log_success "Home directory accessible"
fi

# Step 5: Setup unirtm
log_step "📦 Setting up unirtm..."
if ! command -v unirtm >/dev/null 2>&1; then
  log_error "unirtm not found in PATH - skipping"
else
  if unirtm trust -a 2>/dev/null; then
    log_success "unirtm configuration trusted"
  else
    log_warning "Failed to trust unirtm configuration"
  fi
fi

# Step 6: Verify SSH configuration
log_step "🔑 Verifying SSH configuration..."
SSH_KEYS_FOUND=0
if [ -d "$HOME/.ssh" ]; then
  # Count SSH keys
  for key in id_rsa id_ed25519 id_ecdsa id_dsa; do
    [ -f "$HOME/.ssh/$key" ] && SSH_KEYS_FOUND=$((SSH_KEYS_FOUND + 1))
  done
  log_success "SSH configured ($SSH_KEYS_FOUND keys found)"
else
  log_warning "SSH directory not found at $HOME/.ssh"
fi

# Step 7: Configure GPG permissions
log_step "🔐 Configuring GPG permissions..."
GPG_KEYS_FOUND=0
if [ -d "$HOME/.gnupg" ]; then
  chmod 700 "$HOME/.gnupg"
  log_detail ".gnupg directory (700)"

  # Configure GPG agent socket permissions (if exists)
  if [ -S "$HOME/.gnupg/S.gpg-agent" ]; then
    chmod 700 "$HOME/.gnupg/S.gpg-agent"
    log_detail "S.gpg-agent socket (700)"
  fi

  # Configure subdirectories
  for subdir in private-keys-v1.d openpgp-revocs.d crls-d; do
    if [ -d "$HOME/.gnupg/$subdir" ]; then
      chmod 700 "$HOME/.gnupg/$subdir"
      log_detail "$subdir/ (700)"
      if [ "$subdir" = "private-keys-v1.d" ]; then
        # Count key files
        GPG_KEYS_FOUND=$(find "$HOME/.gnupg/$subdir" -type f 2>/dev/null | wc -l)
      fi
    fi
  done

  # Configure key files
  for keyfile in "$HOME"/.gnupg/*.gpg "$HOME"/.gnupg/*.asc "$HOME"/.gnupg/gpg.conf "$HOME"/.gnupg/gpg-agent.conf; do
    if [ -f "$keyfile" ]; then
      chmod 600 "$keyfile"
      log_detail "$(basename "$keyfile") (600)"
    fi
  done

  log_success "GPG directory permissions configured ($GPG_KEYS_FOUND private keys)"
else
  log_warning "GPG directory not found at $HOME/.gnupg"
fi

# Step 8: Configure GPG program path
log_step "🔐 Setting up GPG program path..."
if command -v gpg >/dev/null 2>&1; then
  GPG_PATH="$(command -v gpg)"
  git config --global gpg.program "$GPG_PATH"
  GPG_VERSION=$(gpg --version 2>/dev/null | head -1 || echo "unknown")
  log_success "GPG program: $GPG_PATH ($GPG_VERSION)"

  # Verify GPG functionality
  if [ "${DEBUG:-0}" -eq 1 ]; then
    if gpg --list-secret-keys >/dev/null 2>&1; then
      log_detail "GPG can access private keys"
    else
      log_warning "GPG found but cannot access private keys"
    fi
  fi
else
  log_warning "GPG not found in PATH - signing operations may fail"
fi

# Step 9: Configure git user information
log_step "👤 Configuring git user information..."
if ! command -v git >/dev/null 2>&1; then
  log_error "Git not found in PATH - skipping git configuration"
else
  GIT_USER_NAME="${GIT_USER_NAME:-}"
  GIT_USER_EMAIL="${GIT_USER_EMAIL:-}"

  if [ -z "$GIT_USER_NAME" ]; then
    GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "")
  fi
  if [ -z "$GIT_USER_EMAIL" ]; then
    GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
  fi

  if [ -n "$GIT_USER_NAME" ]; then
    git config --global user.name "$GIT_USER_NAME"
    log_detail "Git user: $GIT_USER_NAME"
  else
    log_warning "Git user name not configured"
  fi

  if [ -n "$GIT_USER_EMAIL" ]; then
    git config --global user.email "$GIT_USER_EMAIL"
    log_detail "Git email: $GIT_USER_EMAIL"
  else
    log_warning "Git email not configured"
  fi

  if [ -n "$GIT_USER_NAME" ] && [ -n "$GIT_USER_EMAIL" ]; then
    log_success "Git user information configured"
  else
    log_warning "Git user info incomplete - configure with: git config --global user.name/email"
  fi
fi

# Step 10: Configure git signing key
log_step "🔑 Configuring git signing..."
if ! command -v git >/dev/null 2>&1; then
  log_error "Git not found - skipping signing configuration"
elif SIGNING_KEY=$(git config --global user.signingkey 2>/dev/null); then
  git config --global user.signingkey "$SIGNING_KEY"

  # Check if GPG can sign with this key only if GPG is available
  if command -v gpg >/dev/null 2>&1; then
    if gpg --list-secret-keys "$SIGNING_KEY" >/dev/null 2>&1; then
      git config --global commit.gpgsign true
      log_success "Git signing enabled with key: $SIGNING_KEY"
    else
      log_warning "Signing key not accessible in GPG: $SIGNING_KEY"
      git config --global commit.gpgsign false || true
    fi
  else
    log_warning "GPG not available - cannot verify signing key"
    git config --global commit.gpgsign false || true
  fi
else
  log_warning "No global signing key found"
  git config --global commit.gpgsign false || true
fi

# Step 11: Install project dependencies (optional)
log_step "📥 Installing project dependencies..."
if [ "$SKIP_DEPS" -eq 1 ]; then
  log_detail "Skipping dependency installation (SKIP_DEPS=1)"
elif ! command -v unirtm >/dev/null 2>&1; then
  log_warning "unirtm command not found - cannot install dependencies"
else
  log_detail "Running: unirtm install"
  if [ -n "$LOG_FILE" ]; then
    if unirtm install 2>&1 | tee -a "$LOG_FILE"; then
      log_success "Dependencies installed successfully"
    else
      log_error "Dependency installation failed - continuing anyway"
    fi
  else
    if unirtm install 2>&1; then
      log_success "Dependencies installed successfully"
    else
      log_error "Dependency installation failed - continuing anyway"
    fi
  fi
fi

# Summary section
echo ""
log_info "========================================="
END_TIME=$(date +%s)
TOTAL_TIME=$((END_TIME - START_TIME))

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  log_success "Devcontainer initialization complete! (${TOTAL_TIME}s)"
elif [ $ERRORS -eq 0 ]; then
  log_success "Devcontainer initialized with $WARNINGS warning(s) (${TOTAL_TIME}s)"
else
  log_error "Devcontainer initialization completed with $ERRORS error(s) and $WARNINGS warning(s) (${TOTAL_TIME}s)"
fi
log_info "========================================="

# Show helpful hints
log_detail "💡 Environment Summary:"
log_detail "  - Container user: $CONTAINER_USER"
log_detail "  - Home directory: $HOME"
log_detail "  - SSH keys found: $SSH_KEYS_FOUND"
log_detail "  - GPG keys found: $GPG_KEYS_FOUND"
log_detail "  - Git user: ${GIT_USER_NAME:-<not configured>}"
log_detail "  - Warnings: $WARNINGS | Errors: $ERRORS"
log_detail ""
log_detail "📖 Useful commands:"
log_detail '  - View git config: git config --global --list'
log_detail "  - Test GPG signing: git config --global commit.gpgsign true"
log_detail "  - Show this script: cat .devcontainer/init.sh"
log_detail "  - Run with logging: LOG_FILE=init.log sh .devcontainer/init.sh"
log_detail "  - Run in debug mode: DEBUG=1 VERBOSE=1 sh .devcontainer/init.sh"
log_detail "  - Skip deps install: SKIP_DEPS=1 sh .devcontainer/init.sh"
