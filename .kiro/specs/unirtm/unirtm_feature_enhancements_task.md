# UniRTM Feature Enhancements Tasks

- `[x]` **Phase 1: 配置模板变量 (Template Variables)**
  - `[x]` Modify `internal/config/manager.go` `viperConfigManager.Load` to render templates before viper parsing.
  - `[x]` Add unit tests in `internal/config/manager_test.go`.
  - `[x]` Atomic commit: "feat(config): add template variables support in toml config".

- `[x]` **Phase 2: 配置热重载 (Hot-Reloading Hooks)**
  - `[x]` Update `internal/service/activation.go` `zsh_hook` and `bash_hook` to include `unirtm.toml` mtime checks.
  - `[x]` Atomic commit: "feat(shell): add config hot-reloading in shell activation hooks".

- `[x]` **Phase 3: `unirtm watch` (任务监控)**
  - `[x]` Add `fsnotify` dependency.
  - `[x]` Create `cmd/28.watch.go` for `unirtm watch <task>`.
  - `[x]` Atomic commit: "feat(cmd): add watch command for auto-running tasks on file changes".

- `[x]` **Phase 4: `unirtm alias` (版本别名)**
  - `[x]` Modify `Config` struct to include `Aliases map[string]map[string]string`.
  - `[x]` Add `cmd/29.alias.go` (list, set, delete).
  - `[x]` Atomic commit: "feat(cmd): add alias management and resolution".

- `[x]` **Phase 5: GPG 签名验证**
  - `[x]` Add `ProtonMail/go-crypto` dependency.
  - `[x]` Implement verification in `Downloader`.
  - `[x]` Atomic commit: "feat(security): add GPG signature verification for downloads".
