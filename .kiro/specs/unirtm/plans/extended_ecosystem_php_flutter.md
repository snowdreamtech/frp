# PHP 与 Flutter 原生化扩展实施计划

为了进一步扩大 UniRTM 的工具覆盖面，我们将补齐 PHP 和 Flutter/Dart 的原生支持。

## 目标工具

1. **PHP** (`php`): 涵盖 PHP 运行时及 Composer。
2. **Flutter** (`flutter`): 涵盖 Flutter SDK 及内置的 Dart SDK。

## 变更内容

### [NEW] `internal/provider/php.go`

- 实现 `Provider` 接口。
- 对接预编译二进制源。
- 暴露 `php` 可执行文件。

### [NEW] `internal/provider/flutter.go`

- 实现 `Provider` 接口。
- 对接 Google 官方 Release 源。
- 暴露 `flutter` 和内置的 `dart` 命令。

### [MODIFY] `internal/provider/registry.go`

- 注册 `php` 和 `flutter` Provider。

## 验证计划

- 编写对应的 `_test.go` 文件。
- 验证 `Name()` 和 `DetectVersion()`。
