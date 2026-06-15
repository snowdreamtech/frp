# Go Development Guidelines

> Objective: Go-specific project conventions covering formatting, project structure, error handling, concurrency patterns, testing, logging, and performance — ensuring production-ready, idiomatic Go code.

## 1. Toolchain, Code Quality & Modules

### Toolchain

- **Formatting**: Format all code with `goimports` before committing (it manages both formatting AND import grouping). Configure as a save-on-format action in IDEs. Reject unformatted code in CI:

  ```bash
  goimports -l ./...   # list unformatted files
  gofmt -l ./...       # for pure formatting (no import management)
  ```

- **Linting**: Use `golangci-lint` as the standard linter aggregator. Run `golangci-lint run ./...` and fail CI on any finding. Commit `.golangci.yml` to the repository:

  ```yaml
  linters:
    enable:
      - errcheck # check all errors are handled
      - govet # vet checks
      - staticcheck # advanced static analysis
      - gosimple # simplification suggestions
      - unused # detect unused code
      - revive # maintainability
      - bodyclose # ensure HTTP response bodies are closed
      - noctx # ensure context is passed for HTTP requests
      - exhaustive # ensure switch exhaustiveness on enums
      - gochecknoglobals # discourage global variables
      - contextcheck # context propagation checks
  ```

- **Build**: Use `go build -trimpath ./...` for reproducible binaries (strips local path prefixes from debug info). Use `go vet ./...` in CI as a lightweight static check.

### Modules

- Use Go modules (`go.mod`). Commit both `go.mod` and `go.sum` — the sum file is a security control, not just a cache. Run `go mod tidy` before every commit to keep them clean and remove unused dependencies.
- **Strict Version Pinning (MANDATORY)**: All dependencies in `go.mod` MUST use **exact version tags** (e.g., `v1.2.3`). Never use pseudo-versions manually or leave dependencies without a pinned tag. The `go.sum` file provides cryptographic integrity verification — always commit it.

  ```
  // ❌ WRONG — pseudo-version or unpinned
  require github.com/some/lib v0.0.0-20231015123456-abcdef123456

  // ✅ CORRECT — exact tagged release
  require (
    github.com/gin-gonic/gin v1.10.0
    github.com/stretchr/testify v1.9.0
  )
  ```

- Pin Go version in `go.mod` and in CI tooling. Use the latest stable release. Set `GONOSUMCHECK` for private modules.
- **Network & Environment Compatibility**:
  - Always respect standard Go environment variables: `GOPROXY`, `GONOPROXY`, `GOPRIVATE`, `GONOSUMCHECK`.
  - For Go SDK installations, support custom download mirrors via `GO_DOWNLOAD_MIRROR` (or `UNIRTM_GO_DOWNLOAD_MIRROR`). Use `https://golang.google.cn/dl` as the primary fallback for restricted networks.
- Manage tooling dependencies (linters, code generators) via `tools.go`:

  ```go
  //go:build tools
  package tools

  import (
    _ "github.com/golangci/golangci-lint/cmd/golangci-lint"
    _ "golang.org/x/tools/cmd/goimports"
  )
  ```

## 2. Project Layout

- Follow [Standard Go Project Layout](https://github.com/golang-standards/project-layout) conventions:

  ```text
  cmd/
  └── server/
      └── main.go          # minimal — parse flags/env, wire dependencies, start
  internal/
  ├── handler/             # HTTP/gRPC handlers (thin)
  ├── service/             # business logic layer
  ├── repository/          # data access layer
  ├── middleware/          # HTTP/gRPC middleware
  └── model/               # domain models, DTOs
  pkg/                     # public libraries for external reuse (use sparingly)
  api/                     # OpenAPI/Protobuf definitions
  scripts/                 # build, migration, dev scripts
  ```

- Use `internal/` to enforce package boundaries — packages in `internal/` cannot be imported by code outside the parent module. This is a compile-time constraint, not a convention.
- Keep `main.go` minimal: parse CLI flags/config, construct dependencies (DB pool, HTTP client), wire them into services and handlers, start the server, handle graceful shutdown. Zero business logic in `main.go`.
- **Package naming**: short, lowercase, no underscores, no stutter. `user.User` is wrong — use `user.Profile` or rename the package. Package name == directory name.
- Prefer **fewer, larger packages** over many small single-file packages. Group code by domain/feature, not by type (avoid `utils/`, `helpers/`, `common/`).

## 3. Error Handling

- Return errors explicitly as the last return value: `return result, err`. **Never use `panic`** for expected error conditions. Reserve `panic` only for programming invariant violations (bugs that should never happen in correct code).
- **Wrap errors with context** using `fmt.Errorf("context: %w", err)`. The `%w` verb enables `errors.Is()` and `errors.As()` unwrapping:

  ```go
  // ✅ Wrapped with context
  user, err := repo.FindByID(ctx, id)
  if err != nil {
    return nil, fmt.Errorf("find user %d: %w", id, err)
  }

  // ✅ Checking specific errors
  if errors.Is(err, ErrNotFound) {
    return nil, echo.ErrNotFound
  }
  ```

- Define **sentinel errors** with `errors.New()` for errors that callers need to distinguish:

  ```go
  var (
    ErrNotFound   = errors.New("not found")
    ErrForbidden  = errors.New("forbidden")
    ErrConflict   = errors.New("conflict")
  )
  ```

- Use **typed errors** for structured error data:

  ```go
  type ValidationError struct {
    Field   string
    Message string
  }
  func (e *ValidationError) Error() string {
    return fmt.Sprintf("validation: %s — %s", e.Field, e.Message)
  }
  ```

- Handle **every returned error**. The `errcheck` linter enforces this. Use `_ = expr` only for documented, intentional ignores with a clear comment (`// explicitly ignoring — always returns nil for this input`).
- Avoid deeply nested error handling. Inject sentinel returns with `if err != nil { return ... }` and keep the happy path at the leftmost indentation level.

## 4. Concurrency

- **Never start a goroutine without knowing how and when it will stop.** Goroutine leaks are undetected memory leaks that accumulate and degrade production services.
- Use **`context.Context`** for cancellation, deadlines, and request-scoped values. Pass context as the **first parameter** of every blocking, I/O-bound, or long-running function:

  ```go
  func (s *UserService) GetByEmail(ctx context.Context, email string) (*User, error) {
    return s.repo.FindByEmail(ctx, email)
  }
  ```

- Use **`errgroup.Group`** (`golang.org/x/sync/errgroup`) for launching goroutines that can fail — it collects the first non-nil error and cancels the shared context:

  ```go
  g, ctx := errgroup.WithContext(ctx)
  g.Go(func() error { return fetchUsers(ctx) })
  g.Go(func() error { return fetchMetrics(ctx) })
  if err := g.Wait(); err != nil {
    return fmt.Errorf("parallel fetch: %w", err)
  }
  ```

- Prefer **channels** for communication between concurrent goroutines. Use `sync.Mutex` / `sync.RWMutex` for simple, local shared-state protection. Use `sync/atomic` for simple counters and booleans requiring atomic updates.
- Use **`-race` flag** in all tests and in CI: `go test -race ./...`. The race detector catches real data races that are otherwise non-deterministic.
- Use **`sync.Pool`** for frequently allocated, short-lived objects to reduce GC pressure in hot paths (e.g., byte buffers, encoder instances).

## 5. Testing, Logging & Performance

### Testing

- Use **table-driven tests** with `t.Run()` for comprehensive input coverage:

  ```go
  func TestParseEmail(t *testing.T) {
    tests := []struct {
      name    string
      input   string
      want    string
      wantErr bool
    }{
      {"valid email", "user@example.com", "user@example.com", false},
      {"empty string", "", "", true},
      {"missing @", "notanemail", "", true},
    }
    for _, tt := range tests {
      t.Run(tt.name, func(t *testing.T) {
        got, err := ParseEmail(tt.input)
        if (err != nil) != tt.wantErr {
          t.Fatalf("wantErr=%v, got err=%v", tt.wantErr, err)
        }
        require.Equal(t, tt.want, got)
      })
    }
  }
  ```

- Use **Testify** (`github.com/stretchr/testify`) for assertions: `require.NoError(t, err)` (fails immediately), `assert.Equal(t, expected, actual)` (continues on failure).
- **Test Sandboxing & Environment Isolation**: Tests **MUST NOT** generate temporary files, config files, or cache data in the project's source code directory, preventing Git index pollution.
  - Always use `t.TempDir()` to create a sandbox directory that is automatically cleaned up by the Go testing framework.
  - Override critical path variables within tests (e.g., `t.Setenv("UNIRTM_DATA_DIR", tmpDir)`) to ensure all test artifacts remain strictly isolated.
- Use **Testcontainers** for integration tests requiring real databases, Redis, Kafka, or other services. Spin up containers per-test-suite, not per-test.
- Use **`net/http/httptest`** for HTTP handler tests without running a real server. Use `httptest.NewServer()` for full-server integration tests.
- Generate mocks with **`mockery`** or **`gomock`** from interface definitions. Avoid hand-written mocks.

### Logging

- Use **`log/slog`** (Go 1.21+) with a JSON handler for structured, leveled production logging:

  ```go
  logger := slog.New(slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
    Level:     slog.LevelInfo,
    AddSource: true,
  }))
  slog.SetDefault(logger)

  // Structured log with context
  slog.Info("user created",
    "userId", user.ID,
    "email", user.Email,
    "requestId", r.Header.Get("X-Request-ID"),
  )
  ```

- Never use `fmt.Println` or the standard `log` package in production code — they produce unstructured, unleveled output.
- Propagate the logger via `context.Context` for per-request log enrichment (request ID, user ID, tenant ID).

### Performance

- Benchmark hot code paths with `go test -bench=. -benchmem ./...`. Use `benchstat` to compare benchmark results between branches.
- Use `go tool pprof` with `-http=:6060` for interactive flamegraph profiling. Expose the `pprof` HTTP handler on a management port in production environments.
- Use `sync.Pool` for frequently allocated temporary objects. Pre-allocate slices and maps with the expected capacity: `make([]T, 0, expectedLen)`.
- Set `GOMAXPROCS` to match the number of available CPU cores in containerized environments (use the `uber-go/automaxprocs` package for automatic adjustment).
