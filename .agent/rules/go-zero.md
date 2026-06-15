# go-zero Microservices Framework Guidelines

> Objective: Define standards for building high-concurrency Go microservices with go-zero — covering project structure, code generation, API/RPC design, dependency injection, resilience, and observability.

## 1. Overview & Philosophy

- **go-zero** is a cloud-native microservices framework with built-in code generation (`goctl`), API gateway integration, service discovery, adaptive circuit-breaking, rate limiting, and load shedding. It is designed for high-concurrency production Go services.
- Core philosophy: **generate boilerplate, focus on business logic.** Use `goctl` for all service scaffolding and route/handler/logic registration. Never write repetitive transport or middleware plumbing by hand.
- Pin the `goctl` version for reproducibility — mismatched `goctl` and `go-zero` library versions can cause generation incompatibilities:

  ```bash
  # Install exact version
  go install github.com/zeromicro/go-zero/tools/goctl@v1.6.6

  # Or via unirtm/.tool-versions
  goctl = "1.6.6"
  ```

- Use `goctl env check --install` to verify and install required dependencies (protoc, protoc-gen-go, etc.) in a single step.

## 2. Project Structure (goctl Generated)

- Use `goctl api new` for HTTP API services and `goctl rpc new` for gRPC services. Adhere to the generated layout — deviations require strong justification and team alignment:

```text

service/
├── api/                        # HTTP API layer
│   ├── service.api             # API DSL spec (source of truth)
│   └── internal/
│       ├── config/             # Config struct (auto-mapped from config.yaml)
│       ├── handler/            # HTTP handlers (generated — DO NOT edit)
│       ├── logic/              # Business logic (YOU write this)
│       │   └── user/
│       │       └── getuserlogic.go
│       ├── middleware/         # Custom HTTP middleware
│       ├── svc/                # ServiceContext (DI root)
│       │   └── servicecontext.go
│       └── types/              # Request/Response types (generated from .api)
└── rpc/                        # gRPC layer
    ├── service.proto           # Protobuf spec (source of truth)
    └── internal/
        ├── config/
        ├── logic/              # Business logic for each RPC method
        └── svc/

```

- Treat generated files (`handler/`, router registration, `types/`) as **read-only** — they are overwritten on regeneration. Write logic only in `logic/` and `svc/`.
- Separate concerns clearly:
  - `handler/` — parse request, call logic, write response (generated; thin)
  - `logic/` — business logic (YOU write; pure Go, no HTTP/gRPC concerns)
  - `svc/ServiceContext` — DI root; initializes DB, Redis, gRPC clients, config

## 3. API & RPC Definition

### HTTP API (.api DSL)

- Define HTTP APIs in `.api` files (go-zero's IDL). Run `goctl api go` to regenerate:

  ```bash
  goctl api go \
    --api service.api \
    --dir . \
    --style gozero   # naming convention: gozero or goZero
  ```

  Example `.api`:

  ```
  type (
    CreateUserRequest {
      Name  string `json:"name" validate:"required,min=1,max=100"`
      Email string `json:"email" validate:"required,email"`
    }
    UserResponse {
      Id    int64  `json:"id"`
      Name  string `json:"name"`
      Email string `json:"email"`
    }
  )

  service user-api {
    @handler CreateUser
    post /users (CreateUserRequest) returns (UserResponse)

    @handler GetUser
    get /users/:id returns (UserResponse)
  }
  ```

- Validate `.api` files in CI before regeneration:

  ```bash
  goctl api validate --api service.api
  ```

### gRPC (.proto)

- Define RPC services in standard Protobuf files. Use `goctl rpc protoc` to generate both gRPC stubs and go-zero RPC wrappers:

  ```bash
  goctl rpc protoc service.proto \
    --go_out=. \
    --go-grpc_out=. \
    --zrpc_out=.
  ```

- Keep `.api` and `.proto` files as the **single source of truth**. Treat them with the same care as database migration files — review changes carefully, as they break client compatibility.

## 4. ServiceContext & Dependency Injection

- The **`ServiceContext`** in `svc/servicecontext.go` is the dependency injection root. Initialize all shared dependencies here — DB connections, caches, Redis clients, downstream RPC clients:

  ```go
  type ServiceContext struct {
    Config       config.Config
    DB           *gorm.DB
    Redis        *redis.Client
    OrderRpc     orderclient.Order     // downstream gRPC client
    UserCache    *redis.String
  }

  func NewServiceContext(c config.Config) *ServiceContext {
    sqlConn := sqlx.NewMysql(c.DataSource)
    rds := redis.MustNewClient(&c.Redis)

    return &ServiceContext{
      Config:     c,
      DB:         gormDB,
      Redis:      rds,
      OrderRpc:   orderclient.NewOrder(zrpc.MustNewClient(c.OrderRpc)),
      UserCache:  redis.NewString(rds, userCacheKey),
    }
  }
  ```

- Pass `*ServiceContext` to every `Logic` struct via the generated constructor: `NewGetUserLogic(ctx, svcCtx)`.
- **Never use global variables** for dependencies — everything flows through `ServiceContext`.
- Use context propagation (`context.Context`) consistently — pass it to all DB, cache, and RPC calls for timeout and cancellation support.
- Load config via `conf.MustLoad(configFile, &c)`. Support environment variable override with `conf.FillDefault(&c)`.

## 5. Resilience, Observability & Testing

### Built-in Resilience

- go-zero provides **adaptive circuit breaking, rate limiting, timeout, and load shedding** via built-in middleware. Configure thresholds in `config.yaml`:

  ```yaml
  # config.yaml
  Timeout: 2000 # HTTP/RPC timeout in milliseconds
  CpuThreshold: 900 # load shedding — CPU usage threshold (0-1000)
  ```

  Never reimplement these mechanisms with third-party libraries — go-zero's implementations are production-hardened for high concurrency.
- Use go-zero's `core/stores/cache` with Redis for **single-flight cache-aside patterns**. This prevents cache stampedes automatically:

  ```go
  // Users are fetched from DB on miss, preventing thundering herd
  val, err := l.svcCtx.UserCache.Take(
    &user,
    fmt.Sprintf("user:%d", req.Id),
    func(v any) error { return l.svcCtx.DB.First(v, req.Id).Error },
  )
  ```

### Observability

- Use `logx` for structured logging. Configure in `main.go` with `logx.SetUp(c.Log)`. Use `logx.WithContext(ctx)` in logic handlers to propagate trace IDs:

  ```go
  logx.WithContext(l.ctx).Infof("processing user request: userId=%d", req.Id)
  ```

- Expose **Prometheus metrics** using go-zero's built-in support. Integrate with Grafana for SLO dashboards:
  - Request latency histograms (`p50`, `p95`, `p99`)
  - Error rate counters by service and method
  - Circuit breaker state changes and rejections
- Integrate **OpenTelemetry** for distributed tracing. Configure the `otlp` exporter in `config.yaml`:

  ```yaml
  Telemetry:
    Name: user-api
    Endpoint: http://jaeger:4317
    Sampler: 1.0 # 100% sampling (reduce in production)
    Batcher: otlpgrpc # or "otlphttp"
  ```

### Testing

- Unit-test `logic/` files with mock `ServiceContext`:

  ```go
  func TestGetUserLogic_GetUser(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()

    mockRepo := mocks.NewMockUserRepo(ctrl)
    mockRepo.EXPECT().FindById(gomock.Any(), int64(1)).Return(&model.User{Id: 1, Name: "Alice"}, nil)

    svcCtx := &svc.ServiceContext{UserRepo: mockRepo}
    l := logic.NewGetUserLogic(context.Background(), svcCtx)

    resp, err := l.GetUser(&types.GetUserRequest{Id: 1})
    assert.NoError(t, err)
    assert.Equal(t, "Alice", resp.Name)
  }
  ```

- Integration-test with **Testcontainers** for MySQL/Redis.
- Run API validation in CI: `goctl api validate --api service.api && go test -race ./...`.

### Performance & Deployment

- Configure **database and Redis connection pools** explicitly in `config.yaml` — go-zero defaults can be too conservative for high-concurrency services:

  ```yaml
  DataSource:
    Host: localhost:3306
    MaxIdleConns: 10
    MaxOpenConns: 50
    ConnMaxLifetime: 1h
  ```

- go-zero includes **built-in graceful shutdown** (SIGTERM handling). Ensure logic handlers release resources within the shutdown window. Set `ShutdownTimeout` in config:

  ```yaml
  Rest:
    Port: 8080
    Timeout: 5000 # request timeout in ms
    MaxConns: 10000 # max concurrent connections
    ShutdownTimeout: 10 # seconds to allow in-flight requests to complete
  ```

- **Docker image**: use multi-stage builds — compile the Go binary in a `golang:alpine` stage, then copy the binary into a `scratch` or `gcr.io/distroless/static-debian12` final image for a minimal attack surface and fast image pulls:

  ```dockerfile
  FROM golang:1.23-alpine AS builder
  WORKDIR /app
  COPY go.mod go.sum ./
  RUN go mod download
  COPY . .
  RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o service ./api/

  FROM gcr.io/distroless/static-debian12
  COPY --from=builder /app/service /service
  ENTRYPOINT ["/service", "-f", "etc/config.yaml"]
  ```
