# Design Document: Performance Testing and Documentation Updates

## Overview

This design establishes a comprehensive performance testing infrastructure and documentation update strategy to validate the recent major refactoring that migrated 45 out of 56 tools to the `install_tool_safe()` pattern. The refactoring reduced code by approximately 2,250 lines across 26 files while introducing binary-first detection, platform-specific binary name handling, and enhanced debugging capabilities.

The design addresses three core objectives:

1. **Performance Validation**: Establish baseline measurements and automated regression detection to ensure setup times haven't degraded
2. **Documentation Accuracy**: Update all tool-specific documentation to reflect the new implementation patterns
3. **Cross-Platform Verification**: Validate performance and functionality across Linux, macOS, and Windows

### Key Capabilities

- Automated performance baseline collection with cold/warm cache measurements
- Binary resolution performance profiling (verify_binary_exists, platform-specific naming)
- CI-integrated regression detection with configurable thresholds
- Documentation completeness checking and code example validation
- Cross-platform performance comparison and analysis
- Historical performance trend tracking

### Design Principles

- **Auditable**: All performance measurements include system metadata (OS, CPU, network conditions) and git commit hashes
- **Overridable**: Performance thresholds and budgets are configurable via JSON files
- **Extensible**: Modular script architecture allows easy addition of new performance metrics
- **Lean**: Performance tests run only on relevant file changes to minimize CI overhead

## Architecture

### System Components

```
┌─────────────────────────────────────────────────────────────────┐
│                     Performance Testing System                   │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│  Measurement  │    │  Comparison   │    │  Reporting    │
│    Layer      │    │     Layer     │    │     Layer     │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        ├─ test-performance.sh│                     │
        ├─ benchmark-binary-  │                     │
        │  resolution.sh      │                     │
        └─ collect-baseline.sh│                     │
                              │                     │
                    ├─ compare-performance.sh       │
                    └─ analyze-performance-trends.sh│
                                                    │
                                          ├─ generate-profile-report.sh
                                          └─ GitHub Actions comments
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌───────────────┐    ┌───────────────┐    ┌───────────────┐
│ Documentation │    │  Validation   │    │  Automation   │
│    Update     │    │     Layer     │    │     Layer     │
└───────────────┘    └───────────────┘    └───────────────┘
        │                     │                     │
        ├─ tool-installation.md                    │
        ├─ alpine-compatibility.md                 │
        └─ API docs (common.sh)                    │
                              │                     │
                    ├─ audit-documentation.sh       │
                    └─ validate code examples       │
                                                    │
                                          ├─ generate-tool-docs.sh
                                          └─ .github/workflows/performance.yml
```

### Data Flow

1. **Baseline Collection**: `collect-baseline.sh` → `benchmarks/baseline.json`
2. **Performance Measurement**: `test-performance.sh` → structured JSON output
3. **Comparison**: `compare-performance.sh` reads baseline + current → generates diff report
4. **CI Integration**: GitHub Actions workflow triggers on `scripts/lib/` changes → posts PR comment
5. **Historical Tracking**: Performance data stored in `benchmarks/history/{commit-sha}.json`
6. **Trend Analysis**: `analyze-performance-trends.sh` reads historical data → generates trend charts

## Components and Interfaces

### 1. Performance Test Script (`scripts/test-performance.sh`)

**Purpose**: Core measurement engine for setup time profiling

**Interface**:

```bash
./scripts/test-performance.sh [OPTIONS]

Options:
  --output-format <json|text>  # Output format (default: text)
  --categories <all|security|linters|formatters|runtimes>
  --verbose                    # Enable detailed timing logs
  --dry-run                    # Preview without actual installation
```

**Output Schema** (JSON):

```json
{
  "timestamp": "2025-01-15T10:30:00Z",
  "commit_sha": "abc123...",
  "system": {
    "os": "linux",
    "arch": "x86_64",
    "cpu_cores": 4,
    "memory_gb": 16,
    "network_type": "github_actions"
  },
  "total_time_seconds": 245.3,
  "categories": {
    "security": {
      "time_seconds": 45.2,
      "tools": ["gitleaks", "osv-scanner", "zizmor"]
    },
    "linters": {
      "time_seconds": 89.1,
      "tools": ["shellcheck", "hadolint", "tflint", ...]
    }
  },
  "slowest_tools": [
    {"name": "golangci-lint", "time_seconds": 32.1},
    {"name": "swiftformat", "time_seconds": 28.5}
  ]
}
```

**Implementation Details**:

- Sources `.unirtm.toml` for consistent logging
- Uses `date +%s` for timing measurements (POSIX-compatible)
- Collects system metadata via `uname`, `/proc/cpuinfo`, `sysctl`
- Groups tools by category based on `scripts/lib/langs/*.sh` structure
- Implements timeout protection (5 minutes per tool, 30 minutes total)

### 2. Baseline Collection Script (`scripts/collect-baseline.sh`)

**Purpose**: Establish performance baselines with cold/warm cache measurements

**Interface**:

```bash
./scripts/collect-baseline.sh [OPTIONS]

Options:
  --cache-mode <cold|warm|both>  # Cache state (default: both)
  --output <path>                # Output file (default: benchmarks/baseline.json)
  --platform <linux|macos|windows>
```

**Workflow**:

1. **Cold Cache Run**:
   - Clear mise cache: `rm -rf ~/.local/share/mise/installs/*`
   - Run `scripts/setup.sh` with timing
   - Record total time + per-tool breakdown
2. **Warm Cache Run**:
   - Run `scripts/setup.sh` again (cache populated)
   - Record total time + per-tool breakdown
3. **Calculate Metrics**:
   - Cache hit rate: `(warm_time / cold_time) * 100`
   - Speedup percentage: `((cold_time - warm_time) / cold_time) * 100`
   - Tools with poor cache effectiveness: `speedup < 20%`

**Output Schema**:

```json
{
  "baseline_version": "1.0",
  "collected_at": "2025-01-15T10:30:00Z",
  "commit_sha": "abc123...",
  "platform": "linux",
  "cold_cache": {
    "total_time_seconds": 312.5,
    "categories": {...}
  },
  "warm_cache": {
    "total_time_seconds": 156.2,
    "categories": {...}
  },
  "cache_effectiveness": {
    "speedup_percentage": 50.0,
    "poorly_cached_tools": ["tool1", "tool2"]
  }
}
```

### 3. Performance Comparison Script (`scripts/compare-performance.sh`)

**Purpose**: Compare current measurements against baseline and detect regressions

**Interface**:

```bash
./scripts/compare-performance.sh [OPTIONS]

Options:
  --baseline <path>              # Baseline file (default: benchmarks/baseline.json)
  --current <path>               # Current measurements (default: stdin or latest run)
  --threshold-warning <percent>  # Warning threshold (default: 20)
  --threshold-error <percent>    # Error threshold (default: 50)
  --output-format <text|markdown|json>
```

**Regression Detection Logic**:

```bash
# For each tool category:
baseline_time = baseline.categories[category].time_seconds
current_time = current.categories[category].time_seconds
diff_percent = ((current_time - baseline_time) / baseline_time) * 100

if diff_percent > threshold_error:
  status = "REGRESSION (FAIL)"
  exit_code = 1
elif diff_percent > threshold_warning:
  status = "REGRESSION (WARNING)"
  exit_code = 0
else:
  status = "OK"
  exit_code = 0
```

**Output Format** (Markdown for PR comments):

```markdown
## Performance Comparison Report

### Summary
- **Total Time**: 245.3s (baseline: 312.5s) ✅ **21.5% faster**
- **Platform**: Linux x86_64
- **Commit**: abc123...

### Category Breakdown

| Category | Baseline | Current | Diff | Status |
|----------|----------|---------|------|--------|
| Security | 45.2s | 48.1s | +6.4% | ⚠️ WARNING |
| Linters | 89.1s | 85.3s | -4.3% | ✅ OK |
| Formatters | 67.8s | 65.2s | -3.8% | ✅ OK |
| Runtimes | 110.4s | 46.7s | -57.7% | ✅ IMPROVED |

### Top 5 Slowest Tools
1. golangci-lint: 32.1s
2. swiftformat: 28.5s
3. spectral: 24.3s
4. tflint: 21.7s
5. hadolint: 18.9s

### Regressions Detected
- ⚠️ Security category: +6.4% (threshold: 20%)
```

### 4. Binary Resolution Benchmark (`scripts/benchmark-binary-resolution.sh`)

**Purpose**: Measure performance of binary-first detection and platform-specific name resolution

**Test Cases**:

1. **Standard Binary**: `shfmt` (exact name match)
2. **Platform-Specific**: `ec-linux-amd64`, `ec-darwin-arm64` (editorconfig-checker)
3. **Windows Binary**: `hadolint.exe`
4. **Versioned Binary**: `shfmt_v3.13.1`
5. **Mise Shim**: `/mise/shims/shellcheck`

**Measurement Points**:

- `verify_binary_exists()` execution time
- `resolve_bin()` execution time
- `mise which` execution time
- `command -v` execution time
- `find` pattern matching time

**Performance Thresholds**:

- Binary verification: < 5 seconds (Requirement 3.1)
- Platform-specific resolution: < 3 seconds (Requirement 3.3)

### 5. CI Integration (`.github/workflows/performance.yml`)

**Trigger Conditions**:

```yaml
on:
  pull_request:
    paths:
      - 'scripts/lib/**/*.sh'
      - 'scripts/setup.sh'
      - '.mise.toml'
      - '.unirtm.toml'
```

**Workflow Steps**:

1. **Setup**: Checkout code, install dependencies
2. **Collect Baseline**: Load from `benchmarks/baseline.json` (committed to repo)
3. **Run Performance Tests**: Execute on matrix (Linux, macOS, Windows)
4. **Compare Results**: Run `compare-performance.sh` for each platform
5. **Post PR Comment**: Aggregate results and post markdown comment
6. **Store Artifacts**: Save performance data to `benchmarks/history/{commit-sha}.json`
7. **Fail Check**: Exit with error if regression exceeds 50% threshold

**Matrix Strategy**:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    include:
      - os: ubuntu-latest
        platform: linux
      - os: macos-latest
        platform: macos
      - os: windows-latest
        platform: windows
```

### 6. Documentation Update Components

#### 6.1 Tool Installation Documentation (`docs/tool-installation.md`)

**Structure**:

```markdown
# Tool Installation Architecture

## Overview
Description of the install_tool_safe() pattern and its benefits

## The Six-Step Installation Process
1. Binary-First Detection
2. Version Verification
3. Installation Decision
4. Cleanup (if needed)
5. Mise Installation
6. Post-Install Verification

## Platform-Specific Binary Handling
- Linux: ec-linux-amd64, ec-linux-arm64
- macOS: ec-darwin-amd64, ec-darwin-arm64
- Windows: ec-windows-amd64.exe

## Debugging and Error Handling
- DEBUG=1 environment variable
- Atomic verification steps
- Common failure scenarios

## Examples
[Code examples from actual implementation]
```

#### 6.2 API Documentation Generator (`scripts/generate-api-docs.sh`)

**Purpose**: Extract function signatures and docstrings from `.unirtm.toml`

**Extraction Pattern**:

```bash
# Extract function signature + comments
grep -B 10 "^install_tool_safe()" .unirtm.toml | \
  sed -n '/^#/,/^install_tool_safe()/p'
```

**Output Format** (Markdown):

```markdown
### `install_tool_safe()`

**Signature**:
```bash
install_tool_safe BIN_NAME PROVIDER DISPLAY_NAME [VERSION_FLAG] [SKIP_FILE_CHECK] [FILE_PATTERNS] [FILE_DIR]
```

**Parameters**:

- `BIN_NAME`: Binary name to verify (e.g., "shfmt")
- `PROVIDER`: Mise provider string (e.g., "github:mvdan/sh")
- `DISPLAY_NAME`: Human-readable name for logging
- `VERSION_FLAG`: Flag to get version (default: "--version")
- `SKIP_FILE_CHECK`: Skip file detection (0=check, 1=skip)
- `FILE_PATTERNS`: Space-separated file patterns (e.g., "*.sh*.bash")
- `FILE_DIR`: Optional directory to search

**Returns**:

- 0: Success or skip (local dev)
- 1: Failure (CI only)

**Example**:

```bash
install_tool_safe "shfmt" "${VER_SHFMT_PROVIDER:-}" "Shfmt" "--version" 0 "*.sh *.bash" ""
```

```

#### 6.3 Documentation Audit Script (`scripts/audit-documentation.sh`)

**Purpose**: Verify documentation completeness and accuracy

**Checks**:
1. **Tool Coverage**: Every tool using `install_tool_safe()` has documentation
2. **Code Example Validation**: Shell code blocks are syntactically correct
3. **Link Validation**: All internal links resolve correctly
4. **Bilingual Sync**: English and Chinese versions are content-equivalent
5. **API Documentation**: All public functions in `common.sh` are documented

**Implementation**:
```bash
# Extract tools using install_tool_safe
tools=$(grep -r "install_tool_safe" scripts/lib/langs/*.sh | \
        sed -n 's/.*install_tool_safe "\([^"]*\)".*/\1/p' | sort -u)

# Check documentation coverage
for tool in $tools; do
  if ! grep -q "$tool" docs/*.md; then
    echo "❌ Missing documentation for: $tool"
    missing_count=$((missing_count + 1))
  fi
done

# Calculate coverage
total_count=$(echo "$tools" | wc -l)
coverage=$((100 * (total_count - missing_count) / total_count))

if [ "$coverage" -lt 80 ]; then
  echo "ERROR: Documentation coverage is ${coverage}% (minimum: 80%)"
  exit 1
fi
```

## Data Models

### Performance Measurement Record

```typescript
interface PerformanceMeasurement {
  timestamp: string;           // ISO 8601 format
  commit_sha: string;          // Git commit hash
  system: SystemMetadata;
  total_time_seconds: number;
  categories: Record<string, CategoryMetrics>;
  slowest_tools: ToolTiming[];
  cache_metrics?: CacheMetrics;
}

interface SystemMetadata {
  os: "linux" | "macos" | "windows";
  arch: "x86_64" | "arm64";
  cpu_cores: number;
  memory_gb: number;
  network_type: "github_actions" | "local" | "unknown";
}

interface CategoryMetrics {
  time_seconds: number;
  tools: string[];
  tool_timings?: Record<string, number>;
}

interface ToolTiming {
  name: string;
  time_seconds: number;
  phases?: {
    detection: number;
    installation: number;
    verification: number;
  };
}

interface CacheMetrics {
  cold_time_seconds: number;
  warm_time_seconds: number;
  speedup_percentage: number;
  cache_hit_rate: number;
  poorly_cached_tools: string[];
}
```

### Performance Budget

```typescript
interface PerformanceBudget {
  version: string;
  total_time_seconds: number;
  categories: Record<string, number>;
  per_tool_budgets?: Record<string, number>;
  thresholds: {
    warning_percent: number;
    error_percent: number;
  };
}
```

**Example** (`benchmarks/budgets.json`):

```json
{
  "version": "1.0",
  "total_time_seconds": 300,
  "categories": {
    "security": 60,
    "linters": 90,
    "formatters": 70,
    "runtimes": 80
  },
  "per_tool_budgets": {
    "golangci-lint": 35,
    "swiftformat": 30,
    "spectral": 25
  },
  "thresholds": {
    "warning_percent": 20,
    "error_percent": 50
  }
}
```

## Error Handling

### Performance Test Failures

#### Scenario 1: Tool Installation Timeout

- **Detection**: Tool installation exceeds 5-minute timeout
- **Handling**: Mark tool as "TIMEOUT", continue with remaining tools
- **Logging**: Record timeout in performance data with partial timing
- **CI Behavior**: Fail workflow if critical tool times out

#### Scenario 2: Binary Resolution Failure

- **Detection**: `verify_binary_exists()` returns non-zero after installation
- **Handling**: Mark tool as "NOT_EXECUTABLE", log detailed debug info
- **Logging**: Include resolution attempts (mise which, command -v, find)
- **CI Behavior**: Fail workflow (indicates broken installation)

#### Scenario 3: Performance Regression

- **Detection**: Current time exceeds baseline by > threshold
- **Handling**: Generate detailed regression report
- **Logging**: Include category breakdown, slowest tools, system diff
- **CI Behavior**:
  - Warning (20-50%): Post comment, pass workflow
  - Error (>50%): Post comment, fail workflow

### Documentation Validation Failures

#### Scenario 1: Missing Documentation

- **Detection**: Tool using `install_tool_safe()` not found in docs
- **Handling**: List all missing tools in audit report
- **Logging**: Generate coverage report with percentage
- **CI Behavior**: Fail if coverage < 80%

#### Scenario 2: Invalid Code Examples

- **Detection**: Shell code block fails shellcheck validation
- **Handling**: Report file, line number, and shellcheck error
- **Logging**: Include suggested fix from shellcheck
- **CI Behavior**: Fail workflow (broken documentation)

#### Scenario 3: Broken Links

- **Detection**: Internal link returns 404 or file not found
- **Handling**: List all broken links with source location
- **Logging**: Suggest correct path if file exists elsewhere
- **CI Behavior**: Fail workflow

### Cross-Platform Failures

#### Scenario 1: Platform-Specific Performance Difference

- **Detection**: One platform differs by > 30% from others
- **Handling**: Generate cross-platform comparison report
- **Logging**: Highlight platform-specific bottlenecks
- **CI Behavior**: Warning only (expected variation)

#### Scenario 2: Platform-Specific Binary Resolution Failure

- **Detection**: Binary resolution works on Linux but fails on Windows
- **Handling**: Log platform-specific binary names attempted
- **Logging**: Include filesystem listing of install directory
- **CI Behavior**: Fail workflow (broken cross-platform support)

## Testing Strategy

### Unit Testing

This feature focuses on infrastructure and tooling rather than application logic. Traditional unit tests are not applicable. Instead, we use:

1. **Script Validation Tests**:
   - Shellcheck validation for all `.sh` scripts
   - Syntax validation for PowerShell scripts
   - Dry-run mode testing (`--dry-run` flag)

2. **Integration Tests**:
   - Run performance tests in isolated Docker containers
   - Verify JSON output schema with `jq` validation
   - Test baseline collection with mock mise installations

3. **Smoke Tests**:
   - Verify all scripts execute without errors
   - Check that required dependencies are available
   - Validate file permissions and executability

### Performance Test Configuration

**Test Execution**:

- Run on clean CI runners for consistency
- Use matrix builds for cross-platform coverage
- Implement timeout protection (30 minutes total)
- Collect system metadata for result correlation

**Baseline Management**:

- Store platform-specific baselines separately
- Update baselines after verified performance improvements
- Version baselines with git tags
- Document baseline collection methodology

**Regression Thresholds**:

- Warning: 20% slower than baseline
- Error: 50% slower than baseline
- Configurable via `benchmarks/budgets.json`

### Documentation Testing

**Automated Checks**:

- Markdown linting (markdownlint-cli2)
- Link validation (markdown-link-check)
- Code example validation (shellcheck on extracted blocks)
- Bilingual content parity (word count comparison)

**Manual Review**:

- Technical accuracy review by maintainers
- User experience testing (follow documentation steps)
- Cross-reference with actual implementation

### Cross-Platform Validation

**Test Matrix**:

```yaml
platforms:
  - os: ubuntu-latest
    shell: bash
    expected_binaries: ["ec-linux-amd64"]
  - os: macos-latest
    shell: bash
    expected_binaries: ["ec-darwin-amd64", "ec-darwin-arm64"]
  - os: windows-latest
    shell: pwsh
    expected_binaries: ["ec-windows-amd64.exe"]
```

**Validation Steps**:

1. Run setup on each platform
2. Verify binary resolution for platform-specific names
3. Compare performance across platforms
4. Check for platform-specific errors

## Implementation Notes

### Performance Measurement Accuracy

**Timing Precision**:

- Use `date +%s` for second-level precision (POSIX-compatible)
- For sub-second precision, use `date +%s.%N` on Linux (GNU coreutils)
- On macOS, use `gdate +%s.%N` (requires `brew install coreutils`)
- Fallback to second precision if high-resolution unavailable

**System Load Considerations**:

- Run performance tests on dedicated CI runners
- Avoid running during high system load
- Collect multiple samples and use median value
- Document system load in metadata

**Network Variability**:

- Measure network latency before tests
- Separate network time from local processing time
- Use GitHub proxy for consistent download speeds
- Document network conditions in metadata

### Binary Resolution Strategy

The `install_tool_safe()` function uses a layered resolution strategy:

1. **Mise Which** (Primary): `mise which <tool>` - handles platform-specific binaries
2. **Command -v** (Fallback 1): `command -v <tool>` - for tools in PATH
3. **Mise Where + Find** (Fallback 2): Search mise installation directory

**Platform-Specific Patterns**:

- Linux: `ec-linux-amd64`, `ec-linux-arm64`
- macOS: `ec-darwin-amd64`, `ec-darwin-arm64`
- Windows: `ec-windows-amd64.exe`

**Performance Optimization**:

- Cache resolution results during single script execution
- Use `MISE_OFFLINE=1` to avoid network delays
- Implement timeout protection (3 seconds per resolution)

### Documentation Generation

**Automated Updates**:

- Extract function signatures from source code
- Generate API documentation from inline comments
- Update tool lists from `scripts/lib/langs/*.sh`
- Validate generated documentation with linters

**Manual Updates Required**:

- Architecture diagrams
- Design rationale explanations
- Troubleshooting guides
- User-facing examples

### CI Optimization

**Caching Strategy**:

- Cache mise installations between runs
- Cache baseline data (committed to repo)
- Invalidate cache on `.mise.toml` changes
- Use content-addressed cache keys

**Parallel Execution**:

- Run platform tests in parallel
- Run documentation validation in parallel with performance tests
- Aggregate results in final step

**Resource Management**:

- Limit concurrent tool installations
- Implement backoff for network failures
- Clean up temporary files after tests
- Monitor disk space usage

## Dependencies

### External Tools

- **mise**: Tool version manager (already installed)
- **jq**: JSON processing (for schema validation)
- **shellcheck**: Shell script linting
- **markdownlint-cli2**: Markdown linting
- **markdown-link-check**: Link validation

### System Requirements

- **Bash 4.0+**: For associative arrays (if needed)
- **POSIX sh**: For maximum compatibility
- **Git**: For commit hash extraction
- **curl**: For network operations
- **find**: For binary resolution

### CI Requirements

- **GitHub Actions**: Workflow execution
- **Matrix Runners**: Linux, macOS, Windows
- **Artifacts Storage**: For historical performance data
- **PR Comment API**: For posting results

## Security Considerations

### Data Privacy

- **No PII**: Performance data contains no personally identifiable information
- **System Metadata**: Only collect non-sensitive system information (OS, CPU count)
- **Git Commit Hashes**: Public information, safe to store

### Access Control

- **Baseline Updates**: Require maintainer approval
- **Budget Changes**: Require code review
- **CI Workflow**: Read-only access to repository
- **Artifacts**: Stored in GitHub Actions (private to repository)

### Supply Chain Security

- **Script Integrity**: All scripts committed to version control
- **Dependency Pinning**: Pin tool versions in `.mise.toml`
- **Checksum Validation**: Verify downloaded binaries
- **Audit Trail**: Git history provides complete audit trail

## Maintenance and Operations

### Baseline Updates

**When to Update**:

- After verified performance improvements
- After major refactoring (like this one)
- When adding new tools
- When changing CI infrastructure

**Update Process**:

1. Run `scripts/collect-baseline.sh` on all platforms
2. Review baseline data for anomalies
3. Commit updated baselines to `benchmarks/baseline.json`
4. Tag commit with baseline version
5. Update documentation with new baseline

### Performance Budget Adjustments

**Review Frequency**: Quarterly or after major changes

**Adjustment Criteria**:

- Consistent performance improvements
- New tool additions
- Infrastructure upgrades
- User feedback on setup times

### Documentation Maintenance

**Update Triggers**:

- Code changes to `.unirtm.toml`
- New tool migrations to `install_tool_safe()`
- User-reported documentation issues
- Quarterly documentation review

**Maintenance Tasks**:

- Run `scripts/audit-documentation.sh` monthly
- Validate all code examples quarterly
- Update screenshots and diagrams as needed
- Sync English and Chinese versions

### Historical Data Management

**Retention Policy**:

- Keep last 100 performance measurements
- Archive older data to separate repository
- Compress historical data (gzip)
- Document data retention in README

**Data Cleanup**:

```bash
# Keep last 100 measurements
cd benchmarks/history
ls -t *.json | tail -n +101 | xargs rm -f
```

## Future Enhancements

### Phase 2 Improvements

1. **Flame Graph Generation**: Visual representation of tool installation phases
2. **Network Profiling**: Separate network time from local processing
3. **Parallel Installation**: Measure performance of parallel tool installation
4. **Cache Optimization**: Identify and fix poorly cached tools

### Phase 3 Improvements

1. **Machine Learning**: Predict performance regressions before they occur
2. **Automated Baseline Updates**: Auto-update baselines after verified improvements
3. **Real-Time Monitoring**: Dashboard for live performance tracking
4. **A/B Testing**: Compare different installation strategies

### Documentation Enhancements

1. **Interactive Examples**: Runnable code examples in documentation
2. **Video Tutorials**: Screen recordings of setup process
3. **Troubleshooting Chatbot**: AI-powered help for common issues
4. **Community Contributions**: User-submitted tips and tricks

## References

- [Mise Documentation](https://mise.jdx.dev/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ShellCheck Wiki](https://github.com/koalaman/shellcheck/wiki)
- [Markdown Style Guide](https://google.github.io/styleguide/docguide/style.html)
- [Performance Testing Best Practices](https://martinfowler.com/articles/practical-test-pyramid.html)
