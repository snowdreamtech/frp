# UniRTM Feature Enhancements Implementation Plan

This plan details the atomic implementation of the 5 major feature suggestions (excluding self-update) to achieve parity with and surpass `mise`. Per your request, these will be executed and committed **atomically** in separate phases.

## User Review Required

> [!IMPORTANT]
> The scope of these features is large. To ensure stability and adhere to atomic commits, we will implement these sequentially. Please review the proposed architecture for each phase. If you approve, I will begin executing **Phase 1** and proceed through the list.

## Open Questions

> [!WARNING]
>
> 1. **GPG Verification Scope**: GPG verification requires maintaining a trusted keyring. Should we use the system's GPG keyring, or should UniRTM maintain its own isolated keyring in `~/.local/share/unirtm/keyring.gpg`? (I recommend an isolated keyring for maximum security and control).
> 2. **Config Storage for Aliases**: I propose storing global aliases in the standard `~/.config/unirtm/config.toml` (managed via Viper) so they can be version-controlled, rather than SQLite. Is this acceptable?

## Proposed Changes

---

### Phase 1: 配置模板变量 (Template Variables)

Enables dynamic evaluation in `unirtm.toml` (e.g., `{{ .Env.HOME }}`).

#### [MODIFY] `internal/config/manager.go`

- Modify `viperConfigManager.Load`.
- Before passing the file content to Viper, read the bytes and process them through Go's `text/template`.
- Inject a context map containing `Env` (from `os.Environ`), `OS` (`runtime.GOOS`), and `Arch` (`runtime.GOARCH`).
- Pass the rendered bytes to `viper.ReadConfig()`.

#### [MODIFY] `internal/config/manager_test.go`

- Add tests validating that template variables are correctly resolved to actual strings during config loading.

---

### Phase 2: 配置热重载 (Hot-Reloading Hooks)

Auto-evaluates the environment when `unirtm.toml` changes, without requiring the user to run `cd` again.

#### [MODIFY] `internal/service/activation.go`

- Modify `GenerateActivationScript` to inject an mtime check in the shell hooks (`zsh_hook`, `bash_hook`, `fish_hook`).
- The shell hook will store the `unirtm.toml`'s last modified time in an environment variable (e.g., `_UNIRTM_CONFIG_MTIME`).
- On every prompt (`precmd`/`PROMPT_COMMAND`), compare the current file mtime with the stored variable. If changed, trigger `unirtm activate`.

---

### Phase 3: `unirtm watch` (任务监控)

Auto-runs a specified task when files in a directory change.

#### [NEW] `cmd/28.watch.go`

- Add the `watch <task>` CLI command.
- Integrate `github.com/fsnotify/fsnotify`.
- Implement a directory watcher (ignoring `.git`, `node_modules`, etc.).
- Add a 500ms debounce logic to prevent double-execution.
- Call the task routing engine (`unirtm run <task>`) upon change detection.

---

### Phase 4: `unirtm alias` (版本别名)

Allows mapping human-readable aliases (like `lts`) to specific versions.

#### [MODIFY] `internal/config/config.go`

- Add an `Aliases map[string]map[string]string` field to the `Config` structure (e.g., `Aliases["node"]["lts"] = "20.11.0"`).

#### [NEW] `cmd/29.alias.go`

- Add `unirtm alias list`, `set`, and `get` subcommands to manipulate the global alias table.

#### [MODIFY] `internal/service/install.go` / `use.go`

- Inject an alias resolution step before querying backends. If a version matches a configured alias, it resolves to the actual version constraint.

---

### Phase 5: 安全与下载机制 (GPG Signature Verification)

Ensures downloaded assets are cryptographically signed by trusted keys.

#### [MODIFY] `go.mod`

- Add `github.com/ProtonMail/go-crypto` (active fork of `golang.org/x/crypto/openpgp`).

#### [MODIFY] `internal/pkg/download/downloader.go`

- After downloading an asset, check if a `.sig` or `.asc` file exists at the same remote path.
- If it exists, download it and verify the signature against the UniRTM keyring.
- If verification fails, delete the asset and return an error.

#### [MODIFY] `internal/database/schema.go`

- Add GPG verification results (Success/Failed/Skipped) to the `audit_log` table.

## Verification Plan

### Automated Tests

- `go test ./internal/config/...` (Templates)
- `go test ./internal/service/...` (Activation Scripts & Hot-Reload)

### Manual Verification

- **Templates**: Add `path = "{{ .Env.HOME }}/custom"` to `unirtm.toml` and run `unirtm config show`.
- **Hot-Reload**: Edit `unirtm.toml` to change a version, save, and verify `node -v` reflects the new version instantly without `cd`.
- **Watch**: Run `unirtm watch test`, edit a file, observe the test task re-running.
- **Alias**: Run `unirtm alias set node lts 20.x`, then `unirtm use node@lts`.
