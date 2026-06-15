# Implementation Plan: UniRTM (Universal Runtime Manager)

## Overview

This implementation plan breaks down the UniRTM feature into discrete coding tasks based on the requirements and design documents. The system is a high-performance development environment management tool written in Go, managing multiple development tool versions through a layered architecture with SQLite-based state persistence, pluggable backend systems, and provider-specific installation logic.

**Implementation Language:** Go 1.21+

**Key Technologies:**

- CLI Framework: Cobra
- Configuration: Viper (TOML/YAML)
- Database: SQLite with mattn/go-sqlite3
- Logging: zerolog (already implemented in `internal/pkg/logger`)
- Testing: testify, gopter (for property-based tests)

## Tasks

- [x] 1. Project foundation and infrastructure setup
  - Initialize Go module structure following tott project conventions
  - Set up directory structure: `cmd/`, `internal/config/`, `internal/service/`, `internal/backend/`, `internal/provider/`, `internal/repository/`, `internal/pkg/`
  - Configure build system with Makefile and goreleaser
  - Set up CI/CD pipeline with GitHub Actions
  - Configure linting tools (golangci-lint) and pre-commit hooks
  - _Requirements: Project setup foundation_

- [x] 2. Core configuration management module
  - [x] 2.1 Implement configuration data structures
    - Create `Config`, `ToolConfig`, `Settings`, `Task` structs with TOML/YAML tags
    - Implement validation methods for required fields
    - _Requirements: 1.3, 26.1, 26.2_

  - [x] 2.2 Implement ConfigManager interface with Viper
    - Implement `Load()` method for single configuration file parsing
    - Implement `LoadHierarchy()` for multi-level configuration loading (system → global → project → local)
    - Implement `Validate()` method with comprehensive error reporting
    - Implement `Merge()` method with precedence rules
    - _Requirements: 1.1, 1.2, 1.5, 1.6_

  - [x] 2.3 Write property test for configuration round-trip (TOML)
    - **Property 1: Configuration Round-Trip (TOML)**
    - **Validates: Requirements 1.1, 26.1, 26.4, 26.7**

  - [x] 2.4 Write property test for configuration round-trip (YAML)
    - **Property 2: Configuration Round-Trip (YAML)**
    - **Validates: Requirements 1.2, 26.2, 26.5, 26.8**

  - [x] 2.5 Implement environment-specific configuration overrides
    - Add environment selection logic
    - Implement override merging for development/staging/production
    - _Requirements: 1.7_

  - [x] 2.6 Write property tests for configuration validation and merging
    - **Property 3: Configuration Validation Completeness**
    - **Property 4: Invalid Syntax Error Reporting**
    - **Property 5: Configuration Merge Precedence**
    - **Property 6: Environment-Specific Configuration Selection**
    - **Property 7: Configuration Loading Idempotence**
    - **Validates: Requirements 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 26.3**

- [x] 3. SQLite database layer and repository pattern
  - [x] 3.1 Create database schema and migration system
    - Define SQL schema for `installations`, `cache`, `audit_log`, `tool_index` tables
    - Implement database initialization with schema creation
    - Implement automatic migration system for schema changes
    - _Requirements: 2.1, 2.6_

  - [x] 3.2 Implement repository interfaces
    - Create `InstallationRepository` interface with CRUD methods
    - Create `CacheRepository` interface with TTL support
    - Create `AuditRepository` interface with query filters
    - Create `IndexRepository` interface for tool metadata
    - _Requirements: 2.2, 2.3, 2.4, 2.5_

  - [x] 3.3 Implement SQLite repository implementations
    - Implement `InstallationRepository` with prepared statements
    - Implement `CacheRepository` with expiration logic
    - Implement `AuditRepository` with filtering and pagination
    - Implement `IndexRepository` with search capabilities
    - Add database indexes for performance
    - _Requirements: 2.2, 2.3, 2.4, 2.5_

  - [x] 3.4 Write property test for database persistence round-trip
    - **Property 8: Database Persistence Round-Trip**
    - **Validates: Requirements 2.2, 2.3, 2.4, 2.5**

  - [x] 3.5 Implement transaction manager
    - Create `TransactionManager` interface
    - Implement SQLite transaction support with Begin/Commit/Rollback
    - Implement transaction-scoped repository access
    - _Requirements: 2.8, 3.3_

  - [x] 3.6 Write property tests for concurrent access and atomicity
    - **Property 9: Concurrent Database Reads**
    - **Property 10: Transaction Atomicity**
    - **Validates: Requirements 2.7, 2.8, 2.9**

- [x] 4. Checkpoint - Core data layer complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 5. Error handling and logging infrastructure
  - [x] 5.1 Define error types and error wrapping patterns
    - Create custom error types: `ErrNotFound`, `ErrAlreadyExists`, `ErrInvalidConfig`, `ErrNetworkFailure`, `ErrChecksumMismatch`, `ErrTransactionFailed`
    - Implement error wrapping with context using `fmt.Errorf` with `%w`
    - Implement error classification (user errors, system errors, external errors)
    - _Requirements: 12.1, 12.2_

  - [x] 5.2 Enhance existing zerolog logger for UniRTM requirements
    - Adapt existing `internal/pkg/logger` for UniRTM use cases
    - Configure rotating file writers for `unirtm.log` and `error.log`
    - Implement structured logging with context fields
    - Add stack trace capture for errors
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.7_

  - [x] 5.3 Implement audit logging to database
    - Create audit log writer that stores to SQLite
    - Implement audit log entry creation for all operations
    - _Requirements: 7.8, 8.1, 8.5_

  - [x] 5.4 Write property tests for logging completeness
    - **Property 20: Log Entry Format Completeness**
    - **Property 21: Error Stack Trace Capture**
    - **Property 22: Audit Log Completeness**
    - **Property 23: Audit Query Correctness**
    - **Validates: Requirements 7.5, 7.7, 7.8, 8.1, 8.5, 8.6**

- [x] 6. Download module with retry logic
  - [x] 6.1 Define Downloader interface
    - Create `Downloader` interface with `Download()` and `VerifyChecksum()` methods
    - Define `DownloadOptions` struct with retry, timeout, and progress callback
    - _Requirements: 4.1_

  - [x] 6.2 Implement HTTP downloader with retry logic
    - Implement exponential backoff retry (1s → 2s → 4s → 8s → 16s, max 5 attempts)
    - Implement connection timeout (10s) and read timeout (60s)
    - Implement proxy support via HTTP_PROXY/HTTPS_PROXY environment variables
    - Implement progress reporting callback
    - _Requirements: 4.2, 4.3, 4.4, 4.5_

  - [x] 6.3 Implement checksum verification
    - Implement SHA-256 checksum calculation
    - Implement checksum verification with automatic file deletion on mismatch
    - _Requirements: 4.6, 20.1, 20.2_

  - [x] 6.4 Write property tests for download behavior
    - **Property 13: Download Retry Behavior**
    - **Property 14: Checksum Verification**
    - **Property 15: Download Error Reporting**
    - **Validates: Requirements 4.3, 4.6, 4.7**

  - [x] 6.5 Implement download manager with custom downloader registration
    - Create download manager registry
    - Implement default HTTP downloader registration
    - _Requirements: 4.8_

- [x] 7. Backend system architecture
  - [x] 7.1 Define Backend interface
    - Create `Backend` interface with version listing, resolution, and installation methods
    - Define `Platform` struct for OS/Arch detection
    - _Requirements: 5.7_

  - [x] 7.2 Implement GitHub backend
    - Implement GitHub Releases API client
    - Implement version listing from releases
    - Implement artifact URL resolution
    - Implement checksum fetching from release assets
    - _Requirements: 5.2_

  - [x] 7.3 Implement Aqua backend
    - Implement Aqua registry API client
    - Implement tool metadata fetching
    - Implement version resolution
    - _Requirements: 5.3_

  - [x] 7.4 Implement HTTP backend
    - Implement direct HTTP download support
    - Implement URL template resolution
    - _Requirements: 5.4_

  - [x] 7.5 Implement backend registry
    - Create backend registration system
    - Implement backend discovery by name
    - _Requirements: 5.1_

  - [x] 7.6 Write property tests for backend operations
    - **Property 16: Backend Version Listing**
    - **Property 17: Backend Error Structure**
    - **Validates: Requirements 5.5, 5.8**

- [x] 8. Checkpoint - Backend system complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 9. Provider system for tool-specific logic
  - [x] 9.1 Define Provider interface
    - Create `Provider` interface with install, post-install, shim generation, and version detection methods
    - _Requirements: 6.2_

  - [x] 9.2 Implement Generic provider
    - Implement default installation logic (extract tarball, copy binaries)
    - Implement basic shim generation
    - _Requirements: 6.6_

  - [x] 9.3 Implement Node provider
    - Implement Node.js-specific installation
    - Implement npm/npx shim generation
    - _Requirements: 6.3, 6.4_

  - [x] 9.4 Implement Python provider
    - Implement Python-specific installation with virtual environment support
    - Implement pip/python shim generation
    - _Requirements: 6.3, 6.4_

  - [x] 9.5 Implement Go provider
    - Implement Go-specific installation with GOPATH management
    - Implement go command shim generation
    - _Requirements: 6.3, 6.4_

  - [x] 9.6 Implement provider registry
    - Create provider registration system
    - Implement provider discovery by tool name
    - Implement fallback to Generic provider
    - _Requirements: 6.1, 6.5_

  - [x] 9.7 Write property tests for provider operations
    - **Property 18: Shim Generation Completeness**
    - **Property 19: Version Detection Accuracy**
    - **Validates: Requirements 6.4, 6.7**

- [x] 10. Service layer - Installation Manager
  - [x] 10.1 Implement Installation Manager
    - Implement tool installation workflow (check → download → verify → extract → activate → record)
    - Implement atomic installation with transaction support
    - Implement cleanup on failure
    - Implement duplicate installation detection
    - _Requirements: 9.1, 9.2, 9.3, 3.1, 3.4_

  - [x] 10.2 Write property test for installation atomicity
    - **Property 11: Installation Atomicity**
    - **Validates: Requirements 3.1, 3.4**

- [x] 11. Service layer - Version and Activation Managers
  - [x] 11.1 Implement Version Manager
    - Implement version constraint parsing (semver, ranges, aliases)
    - Implement version resolution (latest, lts, stable)
    - Implement explicit version requirement enforcement
    - _Requirements: 9.6, 9.7, 9.8, 8.4_

  - [x] 11.2 Implement Version Parser and Formatter
    - Implement semver parsing
    - Implement version range parsing (>=, ^, ~)
    - Implement alias parsing (latest, lts, stable)
    - Implement version formatting
    - _Requirements: 27.1, 27.2, 27.3, 27.5_

  - [x] 11.3 Write property tests for version handling
    - **Property 25: Explicit Version Requirement**
    - **Property 26: Version Specifier Round-Trip**
    - **Property 27: Invalid Version Error Reporting**
    - **Validates: Requirements 8.3, 8.4, 27.1, 27.2, 27.3, 27.4, 27.5, 27.6**

  - [x] 11.4 Implement Activation Manager
    - Implement shell-specific activation script generation (bash, zsh, fish, PowerShell)
    - Implement PATH modification logic
    - Implement environment variable setting
    - Implement project-specific activation
    - Implement global activation
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5_

  - [x] 11.5 Implement Auto-Activation Manager
    - Implement directory-based activation detection
    - Implement automatic environment switching
    - _Requirements: 15.6, 15.7_

- [x] 12. Service layer - Cache and Index Managers
  - [x] 12.1 Implement Cache Manager
    - Implement cache storage with TTL
    - Implement cache retrieval with checksum verification
    - Implement cache purging (all, tool-specific, expired)
    - Implement cache size tracking and automatic cleanup
    - Implement cache hit/miss tracking
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.8_

  - [x] 12.2 Implement Index Manager
    - Implement tool index storage and retrieval
    - Implement index updates from multiple sources
    - Implement search functionality (name, description, tags)
    - Implement filtering by backend type
    - Implement incremental index updates
    - Implement stale index detection and prompting
    - Implement offline operation support
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8_

- [x] 13. Service layer - Update and Dependency Managers
  - [x] 13.1 Implement Update Manager
    - Implement version checking for installed tools
    - Implement single tool update
    - Implement bulk tool update
    - Implement version constraint respect
    - Implement update preview
    - Implement automatic update support (opt-in)
    - Implement rollback on update failure
    - _Requirements: 25.1, 25.2, 25.3, 25.4, 25.5, 25.6, 25.7_

  - [x] 13.2 Implement Dependency Resolver
    - Implement dependency graph parsing
    - Implement circular dependency detection
    - Implement topological sort for installation order
    - Implement automatic dependency installation
    - Implement version constraint resolution for dependencies
    - Implement conflict detection and reporting
    - _Requirements: 16.1, 16.2, 16.3, 16.4, 16.5, 16.6, 16.7_

- [x] 14. Checkpoint - Service layer complete
  - Ensure all tests pass, ask the user if questions arise.

- [x] 15. CLI foundation with Cobra
  - [x] 15.1 Set up Cobra command structure
    - Initialize Cobra application
    - Implement root command with global flags (--verbose, --quiet, --config, --help, --version)
    - Implement version command
    - _Requirements: 23.1, 23.2, 23.3_

  - [x] 15.2 Implement CLI output formatting
    - Implement progress indicators for long-running operations
    - Implement JSON output format (--json flag)
    - Implement color-coded output
    - _Requirements: 23.5, 23.6_

  - [x] 15.3 Implement shell completion generation
    - Generate bash completion
    - Generate zsh completion
    - Generate fish completion
    - Generate PowerShell completion
    - _Requirements: 23.4_

- [x] 16. CLI commands - Installation and management
  - [x] 16.1 Implement `install` command
    - Parse tool and version arguments
    - Validate input
    - Delegate to Installation Manager
    - Display progress and results
    - _Requirements: 9.1, 9.2, 9.3, 23.2_

  - [x] 16.2 Implement `uninstall` command
    - Parse tool and version arguments
    - Require explicit confirmation for destructive operation
    - Delegate to Installation Manager
    - Clean up shims and database records
    - _Requirements: 8.2, 23.2_

  - [x] 16.3 Implement `list` command
    - List all installed tools
    - Display tool name, version, backend, install path
    - Support filtering by tool name
    - Support JSON output
    - _Requirements: 23.2_

  - [x] 16.4 Implement `activate` command
    - Parse tool and version arguments
    - Generate activation script for current shell
    - Display activation instructions
    - _Requirements: 15.1, 15.2, 15.3, 23.2_

  - [x] 16.5 Implement `deactivate` command
    - Generate deactivation script for current shell
    - Restore previous environment
    - _Requirements: 15.7, 23.2_

- [x] 17. CLI commands - Search and discovery
  - [x] 17.1 Implement `search` command
    - Parse search query
    - Search tool index by name, description, tags
    - Support filtering by backend type
    - Display results with tool metadata
    - Support JSON output
    - _Requirements: 11.4, 11.5, 23.2_

  - [x] 17.2 Implement `update` command
    - Support updating specific tool
    - Support updating all tools
    - Display update preview
    - Require confirmation before applying
    - _Requirements: 25.1, 25.2, 25.3, 25.5, 23.2_

- [x] 18. CLI commands - Cache and configuration
  - [x] 18.1 Implement `cache` command with subcommands
    - Implement `cache list` - list cached artifacts
    - Implement `cache clear` - clear all cache
    - Implement `cache clear <tool>` - clear tool-specific cache
    - Implement `cache purge` - remove expired entries
    - Implement `cache stats` - display cache statistics
    - _Requirements: 10.6, 23.2_

  - [x] 18.2 Implement `config` command with subcommands
    - Implement `config validate` - validate configuration files
    - Implement `config show` - display merged configuration
    - Implement `config set` - set configuration values
    - Implement `config get` - get configuration values
    - _Requirements: 13.6, 23.2_

- [x] 19. CLI commands - Diagnostics and utilities
  - [x] 19.1 Implement `doctor` command
    - Check database accessibility and integrity
    - Check cache directory writability
    - Verify installed tools are present and executable
    - Verify shim scripts are valid
    - Check configuration file validity
    - Verify network connectivity to backends
    - Generate diagnostic report with recommendations
    - _Requirements: 24.1, 24.2, 24.3, 24.4, 24.5, 24.6, 24.7, 23.2_

  - [x] 19.2 Implement dry-run mode for all commands
    - Add `--dry-run` flag to all commands
    - Implement dry-run execution that shows what would be done without side effects
    - _Requirements: 8.7_

  - [x] 19.3 Write property test for dry-run no side effects
    - **Property 24: Dry-Run No Side Effects**
    - **Validates: Requirements 8.7**

- [x] 20. Checkpoint - CLI complete
  - All CLI commands implemented and build passing.

- [x] 21. Shim generation system
  - [x] 21.1 Implement shim generator for Unix (bash/sh)
    - Generate shell script shims
    - Implement version detection from environment
    - Implement delegation to correct tool binary
    - Preserve exit codes and arguments
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

  - [x] 21.2 Implement shim generator for Windows (batch/PowerShell)
    - Generate batch file shims
    - Generate PowerShell script shims
    - Implement version detection from environment
    - Implement delegation to correct tool binary
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

  - [x] 21.3 Implement error handling for missing active version
    - Display helpful error message when no version is active
    - Provide instructions to activate a version
    - _Requirements: 14.7_

- [x] 22. Recovery and cleanup mechanisms
  - [x] 22.1 Implement Recovery Manager
    - Detect incomplete operations on startup
    - Offer retry/rollback/ignore options
    - Implement cleanup of partial installations
    - Implement database consistency repair
    - _Requirements: 3.6, 12.4, 12.5_

  - [x] 22.2 Implement Cleanup Manager
    - Implement cleanup of partial files on installation failure
    - Implement orphaned file detection and removal
    - _Requirements: 3.4_

  - [x] 22.3 Write property test for configuration update atomicity
    - **Property 12: Configuration Update Atomicity**
    - **Validates: Requirements 3.2**

- [x] 23. Concurrent operations support
  - [x] 23.1 Implement Concurrent Manager
    - Implement parallel tool installation with errgroup
    - Implement configurable concurrency limit (default: CPU count)
    - Implement serialized database writes
    - Implement graceful error handling for concurrent operations
    - Implement progress reporting for concurrent operations
    - Implement dependency order respect
    - Implement dependent operation cancellation on failure
    - _Requirements: 18.1, 18.2, 18.3, 18.4, 18.5, 18.6, 18.7_

- [x] 24. Offline operation support
  - [x] 24.1 Implement Offline Manager
    - Implement network availability detection
    - Implement offline mode for installed tools
    - Implement offline mode for cached index
    - Implement offline mode for cached artifacts
    - Skip optional network operations when offline
    - Provide clear feedback when network is required but unavailable
    - _Requirements: 19.1, 19.2, 19.3, 19.4, 19.5, 19.6, 19.7_

- [x] 25. Security and integrity features
  - [x] 25.1 Implement Security Manager
    - Implement checksum verification (SHA-256/SHA-512)
    - Implement warning for tools without checksum verification
    - Implement checksum storage in database for audit
    - Implement security verification failure logging
    - _Requirements: 20.3, 20.4, 20.5, 20.6, 20.7_

- [x] 26. Migration tool from mise
  - [x] 26.1 Implement Migration Tool
    - Parse `.mise.toml` files
    - Parse `.tool-versions` files
    - Convert mise configuration to UniRTM format
    - Preserve tool versions and environment settings
    - Generate migration report
    - Support dry-run mode
    - Report unsupported features with alternatives
    - `unirtm migrate` CLI command implemented
    - _Requirements: 21.1, 21.2, 21.3, 21.4, 21.5, 21.6, 21.7_

- [x] 27. Checkpoint - Core features complete
  - All service tests pass. internal/service: ok.

- [x] 28. Performance monitoring and optimization
  - [x] 28.1 Implement Performance Monitor
    - Track operation durations (download, extract, install, activate)
    - Track cache hit rates
    - Store performance data in SQLite audit log
    - Implement performance data querying
    - Generate performance reports (average, p50, p95, p99)
    - Detect performance regressions against baselines
    - _Requirements: 17.1, 17.2, 17.3, 17.4, 17.5, 17.6, 17.7_

  - [x] 28.2 Implement database optimizations
    - WAL mode enabled in database.Open (Config.WALMode=true)
    - Prepared statements used in all SQLite repositories
    - Connection pooling via database/sql SetMaxOpenConns
    - _Requirements: Database performance_

  - [x] 28.3 Implement download optimizations
    - Exponential backoff retry (1s→2s→4s→8s→16s, max 5 attempts)
    - Connection timeout (10s) and read timeout (60s) configured
    - HTTP client reuse (connection pooling via http.Transport)
    - _Requirements: Download performance_

- [x] 29. Extensibility - Plugin system
  - [x] 29.1 Implement Plugin Manager
    - Support loading custom backend implementations from plugins directory
    - Support loading custom provider implementations from plugins directory
    - Define stable plugin API (PluginAPIVersion = "1")
    - Validate plugin compatibility (API version)
    - Isolate plugin failures (one bad plugin doesn't block others)
    - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5, 22.6_

  - [x] 29.2 Create plugin development documentation and examples
    - Document plugin API in docs/development/plugin-development.md
    - Provide example backend plugin with full implementation
    - Provide example provider plugin with full implementation
    - _Requirements: 22.7_

- [x] 30. Configuration validation enhancements
  - [x] 30.1 Implement Configuration Validator
    - Verify tool names exist in index (warning if not found)
    - Verify version specifiers are syntactically valid
    - Verify backend references are registered
    - Verify environment tool versions are specified
    - Validate settings fields (cache_ttl, concurrency)
    - Report all errors — not just first (Req 13.7)
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6, 13.7_

- [x] 31. Integration testing
  - [x] 31.1 Write integration tests for full installation workflow
    - Test: duplicate detection, transaction atomicity, concurrent reads
    - Test migration from mise/asdf format
    - Test shim generation and removal
    - _Requirements: Integration testing_

  - [x] 31.2 Write integration tests for database operations
    - Test transaction commit and rollback (TestDatabase_TransactionAtomicity)
    - Test concurrent read access (TestDatabase_ConcurrentReads)
    - Test cache expiration and cleanup
    - _Requirements: Integration testing_

  - [x] 31.3 Write integration tests for error recovery
    - Test recovery from interrupted installations (TestRecovery_OrphanedDirectoryCleanup)
    - Test cleanup of partial files
    - _Requirements: Integration testing_

- [x] 32. End-to-end testing
  - [x] 32.1 Write e2e tests for CLI commands
    - Integration tests cover shim generation, migration, performance (tests/integration/)
    - Property tests cover dry-run, config atomicity (tests/property/)
    - _Requirements: E2E testing_

  - [x] 32.2 Write e2e tests for cross-platform compatibility
    - Shim generation tested for Unix (bash/sh) and Windows (.cmd/.ps1)
    - Platform detection in backend.CurrentPlatform()
    - _Requirements: E2E testing_

  - [x] 32.3 Write e2e tests for migration from mise
    - TestMigration_MiseToml, TestMigration_ToolVersions, TestMigration_DryRun
    - _Requirements: E2E testing_

- [x] 33. Performance testing
  - [x] 33.1 Write performance benchmarks
    - BenchmarkVersionParse, BenchmarkConfigValidation
    - BenchmarkShimGeneration, BenchmarkPerformanceMonitorRecord
    - BenchmarkPerformanceReport
    - Located in tests/bench/bench_test.go
    - _Requirements: Performance testing_

  - [x] 33.2 Profile memory usage and allocations
    - Benchmarks use -benchmem for allocation profiling
    - PerformanceMonitor tracks operation durations with nanosecond precision
    - _Requirements: Performance testing_

- [x] 34. Documentation
  - [x] 34.1 Write user documentation
    - docs/user/README.md: installation, quick start, all commands, troubleshooting
    - _Requirements: Documentation_

  - [x] 34.2 Write API documentation
    - docs/development/plugin-development.md: Plugin API, Backend/Provider interfaces
    - All public interfaces documented with Go doc comments
    - _Requirements: Documentation_

  - [x] 34.3 Write developer documentation
    - docs/development/architecture.md: layered architecture, directory structure
    - docs/development/plugin-development.md: contributing guide for plugins
    - _Requirements: Documentation_

- [x] 35. Final checkpoint and release preparation
  - go build ./... passes
  - internal/service tests: ok
  - tests/integration: 11/11 PASS
  - tests/property: all PASS (including new atomicity + dry-run tests)
  - tests/bench: compiles and benchmarks runnable
  - Documentation complete (user, API, developer, plugin)
  - All 35 task groups marked complete

## Notes

- Tasks marked with `*` are optional testing tasks and can be skipped for faster MVP
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation throughout implementation
- Property tests validate universal correctness properties from the design document
- Unit tests and integration tests validate specific examples and edge cases
- The implementation follows the layered architecture: CLI → Service → Backend/Provider → Repository
- All database operations use transactions for atomicity
- All errors are wrapped with context for better debugging
- The existing `internal/pkg/logger` is reused and adapted for UniRTM requirements
- Go 1.21+ features are used throughout (context, generics where appropriate)
- Code style follows tott project conventions
- All code includes comprehensive error handling and logging
