# PHP 与 Flutter 原生化任务清单

## Phase 1: PHP 支持

- `[x]` 实现 `internal/provider/php.go`
- `[x]` 实现 `internal/provider/php_test.go`
- `[x]` 原子化 Commit: `feat(provider): add native php support`

## Phase 2: Flutter 支持

- `[x]` 实现 `internal/provider/flutter.go`
- `[x]` 实现 `internal/provider/flutter_test.go`
- `[x]` 原子化 Commit: `feat(provider): add native flutter support`

## Phase 3: 注册与同步

- `[x]` 在 `registry.go` 中注册 `php` 和 `flutter`
- `[x]` 同步 `.kiro` 文档
- `[x]` 原子化 Commit: `feat(provider): register extended core tools`
