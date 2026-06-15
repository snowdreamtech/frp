#!/usr/bin/env sh
# Copyright (c) 2026 SnowdreamTech. All rights reserved.
# Licensed under the MIT License. See LICENSE file in the project root for full license information.
#
# Purpose: Build verification test for Alpine Docker image
# Usage: sh tests/build-verification-alpine.sh
#
# Requirements: 2.1, 2.4, 2.5
# Validates:
#   - Alpine Dockerfile builds successfully
#   - Base image is snowdreamtech/alpine:3.24.0
#   - OCI labels are present and correct

set -eu

# ── Color Output ─────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# ── Logging Functions ────────────────────────────────────────────────────────
log_info() {
  printf "${BLUE}[INFO]${NC} %s\n" "$*"
}

log_success() {
  printf "${GREEN}[✓]${NC} %s\n" "$*"
}

log_warn() {
  printf "${YELLOW}[!]${NC} %s\n" "$*"
}

log_error() {
  printf "${RED}[✗]${NC} %s\n" "$*"
}

# ── Configuration ────────────────────────────────────────────────────────────
TEST_IMAGE_NAME="base-alpine-test"
TEST_IMAGE_TAG="build-verification"
DOCKERFILE_PATH="docker/alpine/Dockerfile"
EXPECTED_BASE_IMAGE="snowdreamtech/alpine:3.24.0"
EXPECTED_VERSION="3.24.0"

# Expected OCI labels
EXPECTED_LABELS="
org.opencontainers.image.authors=Snowdream Tech
org.opencontainers.image.title=Base Image Based On Alpine
org.opencontainers.image.version=3.24.0
org.opencontainers.image.licenses=MIT
org.opencontainers.image.vendor=Snowdream Tech
"

# ── Cleanup Function ─────────────────────────────────────────────────────────
cleanup() {
  log_info "Cleaning up test image..."
  if docker image inspect "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" >/dev/null 2>&1; then
    docker rmi "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" >/dev/null 2>&1 || true
    log_success "Test image removed"
  fi
}

# ── Test Functions ───────────────────────────────────────────────────────────

# Purpose: Verify Docker is available
test_docker_available() {
  log_info "Checking Docker availability..."

  if ! command -v docker >/dev/null 2>&1; then
    log_error "Docker is not installed or not in PATH"
    return 1
  fi

  if ! docker info >/dev/null 2>&1; then
    log_error "Docker daemon is not running"
    return 1
  fi

  log_success "Docker is available"
  return 0
}

# Purpose: Verify Dockerfile exists
test_dockerfile_exists() {
  log_info "Checking Dockerfile existence..."

  if [ ! -f "${DOCKERFILE_PATH}" ]; then
    log_error "Dockerfile not found at ${DOCKERFILE_PATH}"
    return 1
  fi

  log_success "Dockerfile exists at ${DOCKERFILE_PATH}"
  return 0
}

# Purpose: Build the Docker image
test_build_image() {
  log_info "Building Alpine Docker image..."

  if ! docker build -t "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" -f "${DOCKERFILE_PATH}" docker/alpine/ 2>&1; then
    log_error "Docker build failed"
    return 1
  fi

  log_success "Docker image built successfully"
  return 0
}

# Purpose: Verify the image was created
test_image_exists() {
  log_info "Verifying image was created..."

  if ! docker image inspect "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" >/dev/null 2>&1; then
    log_error "Image ${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG} was not created"
    return 1
  fi

  log_success "Image exists"
  return 0
}

# Purpose: Verify base image in Dockerfile
test_base_image_in_dockerfile() {
  log_info "Verifying base image in Dockerfile..."

  if ! grep -q "FROM ${EXPECTED_BASE_IMAGE}" "${DOCKERFILE_PATH}"; then
    log_error "Expected base image '${EXPECTED_BASE_IMAGE}' not found in Dockerfile"
    log_info "Found:"
    grep "^FROM" "${DOCKERFILE_PATH}" || true
    return 1
  fi

  log_success "Base image '${EXPECTED_BASE_IMAGE}' found in Dockerfile"
  return 0
}

# Purpose: Verify OCI labels are present and correct
test_oci_labels() {
  log_info "Verifying OCI labels..."

  local errors=0
  local label_json
  label_json=$(docker image inspect "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" --format='{{json .Config.Labels}}')

  # Check each expected label using a here-doc to avoid subshell
  while IFS='=' read -r key value; do
    # Skip empty lines
    [ -z "${key}" ] && continue

    # Extract label value from JSON
    local actual_value
    actual_value=$(echo "${label_json}" | grep -o "\"${key}\":\"[^\"]*\"" | cut -d'"' -f4 || echo "")

    if [ -z "${actual_value}" ]; then
      log_error "Label '${key}' is missing"
      errors=$((errors + 1))
      continue
    fi

    if [ "${actual_value}" != "${value}" ]; then
      log_error "Label '${key}' has incorrect value"
      log_info "  Expected: ${value}"
      log_info "  Actual:   ${actual_value}"
      errors=$((errors + 1))
      continue
    fi

    log_success "Label '${key}' is correct: ${value}"
  done <<EOF
${EXPECTED_LABELS}
EOF

  if [ "${errors}" -gt 0 ]; then
    return 1
  fi

  log_success "All OCI labels are present and correct"
  return 0
}

# Purpose: Verify version label matches expected version
test_version_label() {
  log_info "Verifying version label..."

  local version_label
  version_label=$(docker image inspect "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" \
    --format='{{index .Config.Labels "org.opencontainers.image.version"}}')

  if [ "${version_label}" != "${EXPECTED_VERSION}" ]; then
    log_error "Version label mismatch"
    log_info "  Expected: ${EXPECTED_VERSION}"
    log_info "  Actual:   ${version_label}"
    return 1
  fi

  log_success "Version label is correct: ${EXPECTED_VERSION}"
  return 0
}

# Purpose: Verify entrypoint is configured
test_entrypoint_configured() {
  log_info "Verifying entrypoint configuration..."

  local entrypoint
  entrypoint=$(docker image inspect "${TEST_IMAGE_NAME}:${TEST_IMAGE_TAG}" \
    --format='{{json .Config.Entrypoint}}')

  if ! echo "${entrypoint}" | grep -q "docker-entrypoint.sh"; then
    log_error "Entrypoint not configured correctly"
    log_info "  Expected: docker-entrypoint.sh"
    log_info "  Actual:   ${entrypoint}"
    return 1
  fi

  log_success "Entrypoint is configured correctly"
  return 0
}

# ── Main Test Execution ──────────────────────────────────────────────────────
main() {
  local errors=0

  log_info "=== Alpine Docker Image Build Verification Test ==="
  echo ""

  # Set up cleanup trap
  trap cleanup EXIT INT TERM

  # Run tests
  test_docker_available || errors=$((errors + 1))
  echo ""

  test_dockerfile_exists || errors=$((errors + 1))
  echo ""

  test_base_image_in_dockerfile || errors=$((errors + 1))
  echo ""

  test_build_image || errors=$((errors + 1))
  echo ""

  test_image_exists || errors=$((errors + 1))
  echo ""

  test_oci_labels || errors=$((errors + 1))
  echo ""

  test_version_label || errors=$((errors + 1))
  echo ""

  test_entrypoint_configured || errors=$((errors + 1))
  echo ""

  # Summary
  log_info "=== Test Summary ==="
  if [ "${errors}" -eq 0 ]; then
    log_success "All tests passed! Alpine Docker image build verification successful."
    echo ""
    log_info "Verified:"
    printf "  ✓ Dockerfile builds without errors\n"
    printf "  ✓ Base image is %s\n" "${EXPECTED_BASE_IMAGE}"
    printf "  ✓ OCI labels are present and correct\n"
    printf "  ✓ Version label is %s\n" "${EXPECTED_VERSION}"
    printf "  ✓ Entrypoint is configured\n"
    echo ""
    return 0
  else
    log_error "${errors} test(s) failed"
    echo ""
    return 1
  fi
}

# ── Entry Point ──────────────────────────────────────────────────────────────
main "$@"
