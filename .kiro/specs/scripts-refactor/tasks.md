# Implementation Plan: Scripts Refactor

## Overview

This implementation refactors `.unirtm.toml` and related modules to provide zero-hang guarantees, robust bin resolution, graceful timeout handling, and high-performance JSON parsing. The implementation follows a modular architecture with separate modules for timeout mechanisms, JSON parsing, process management, and bin resolution.

## Tasks

- [x] 1. Create timeout mechanism module
  - [x] 1.1 Create `scripts/lib/timeout.sh` with `run_with_timeout_robust` function
    - Implement timeout detection (GNU timeout, macOS gtimeout, Bash native fallback)
    - Implement process group management using setsid or subshell fallback
    - Implement SIGTERM → SIGKILL escalation with 2-second grace period
    - Add cleanup for child processes using pkill
    - _Requirements: 2.3.1, 2.3.2, 2.4.1, 2.4.2_

  - [x]\* 1.2 Write unit tests for timeout mechanism in `tests/unit/test_timeout.bats`
    - Test normal command execution returns correct exit code
    - Test timeout triggers and returns exit code 124
    - Test process cleanup after timeout
    - Test subprocess cleanup (no zombie processes)
    - Test signal handling (SIGTERM then SIGKILL)
    - _Requirements: 2.3.1, 2.4.2_

- [x] 2. Create JSON parsing module
  - [x] 2.1 Create Node.js parser `scripts/lib/json-parser.js`
    - Implement JSON.parse with error handling
    - Implement simple JSONPath query evaluation (dot notation)
    - Handle undefined/null values gracefully
    - _Requirements: 2.2.2, 3.1_

  - [x] 2.2 Create Python parser `scripts/lib/json-parser.py`
    - Implement json.loads with error handling
    - Implement query path evaluation for nested objects
    - Handle None values gracefully
    - _Requirements: 2.2.2, 3.1_

  - [x] 2.3 Create Shell wrapper `scripts/lib/json-parser.sh` with `parse_json` function
    - Implement parser selection logic (Node.js → Python → awk fallback)
    - Integrate timeout protection (3 seconds default)
    - Preserve existing awk implementation as fallback
    - _Requirements: 2.2.1, 2.2.2, 3.1_

  - [x]\* 2.4 Write unit tests for JSON parsing in `tests/unit/test_json_parser.bats`
    - Test Node.js parser with simple and nested JSON
    - Test Python parser with simple and nested JSON
    - Test awk fallback when Node.js/Python unavailable
    - Test timeout mechanism triggers correctly
    - Test error handling for malformed JSON
    - _Requirements: 2.2.2, 3.1_

- [x] 3. Create process management module
  - [x] 3.1 Create `scripts/lib/process-manager.sh` with `cleanup_process_tree` function
    - Implement SIGTERM signal sending with validation
    - Implement wait loop with configurable timeout (default 3 seconds)
    - Implement SIGKILL escalation for unresponsive processes
    - Implement child process cleanup using pkill -P
    - _Requirements: 2.4.1, 2.4.2_

  - [x]\* 3.2 Write unit tests for process management in `tests/unit/test_process_manager.bats`
    - Test process cleanup with SIGTERM
    - Test SIGKILL escalation after timeout
    - Test child process cleanup
    - Test zombie process prevention
    - _Requirements: 2.4.1, 2.4.2_

- [x] 4. Create bin resolver module with layered architecture
  - [x] 4.1 Create `scripts/lib/bin-resolver.sh` with layered lookup functions
    - Implement Layer 1: Local cache lookup (venv/bin, node_modules/.bin) - no timeout
    - Implement Layer 2: System PATH lookup with mise shim validation - 1 second timeout
    - Implement Layer 3: mise metadata query with timeout protection - 5 seconds timeout
    - Implement Layer 4: Filesystem search with depth limit and timeout - 10 seconds timeout
    - Implement global cache using associativearray (\_G_BIN_CACHE)
    - _Requirements: 2.1.1, 2.1.2, 3.1, 3.2_

  - [x] 4.2 Implement `resolve_bin_cached` wrapper function
    - Check global cache before executing lookup
    - Store successful results in cache
    - Integrate timeout protection for each layer
    - Add debug logging for each layer attempt and timing
    - _Requirements: 2.1.2, 3.1, 3.2_

  - [x]\* 4.3 Write unit tests for bin resolver in `tests/unit/test_resolve_bin.bats`
    - Test Layer 1 finds binaries in venv and node_modules
    - Test Layer 2 finds binaries in system PATH
    - Test Layer 2 validates and skips invalid mise shims
    - Test Layer 3 queries mise metadata successfully
    - Test Layer 4 performs filesystem search with depth limit
    - Test cache mechanism avoids redundant lookups
    - Test timeout protection triggers for slow operations
    - _Requirements: 2.1.1, 2.1.2, 3.1, 3.2_

- [x] 5. Checkpoint - Verify all modules work independently
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Integrate modules into common.sh
  - [x] 6.1 Update `.unirtm.toml` to source new modules
    - Add source statements for timeout.sh, json-parser.sh, process-manager.sh, bin-resolver.sh
    - Add timeout configuration constants (TIMEOUT_RESOLVE_BIN=5, TIMEOUT_JSON_PARSE=3, etc.)
    - Add debug mode switches (DEBUG_RESOLVE_BIN, VERBOSE levels)
    - _Requirements: 2.3.2, 7.1_

  - [x] 6.2 Update `get_version` function to use new JSON parser
    - Replace awk-based JSON parsing with parse_json function
    - Maintain backward compatibility with existing callers
    - _Requirements: 2.2.1, 2.2.2, 7.1_

  - [x] 6.3 Update `run_mise` function to use timeout mechanism
    - Wrap mise commands with run_with_timeout_robust
    - Use TIMEOUT_MISE_WHICH and TIMEOUT_NETWORK constants
    - _Requirements: 2.3.1, 7.1_

  - [x] 6.4 Update `resolve_bin` function to use new implementation
    - Replace existing implementation with resolve_bin_cached
    - Maintain function signature for backward compatibility
    - Add feature flag support (USE_NEW_RESOLVE_BIN environment variable)
    - _Requirements: 2.1.1, 2.1.2, 7.1, 7.2_

- [x]\* 7. Write integration tests
  - [x]\* 7.1 Create `tests/integration/test_setup_flow.bats`
    - Test complete `make setup` flow executes without hangs
    - Test `make install` flow completes successfully
    - Test `make verify` flow validates installation
    - _Requirements: 5.2, 8.1_

  - [x]\* 7.2 Create `tests/integration/test_ci_simulation.bats`
    - Simulate GitHub Actions environment variables
    - Simulate network timeout scenarios
    - Simulate resource-constrained environments
    - _Requirements: 5.2, 8.1_

- [x] 8. Final checkpoint - Verify complete integration
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP
- Each task references specific requirements for traceability
- The implementation uses Bash/Shell scripting throughout
- Timeout values are configurable via environment variables
- Feature flags allow gradual rollout and easy rollback
- All external command invocations must use timeout protection
- Process cleanup must prevent zombie processes
- Cache mechanisms improve performance for repeated lookups
