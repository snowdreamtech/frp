# Ansible Development Guidelines

> Objective: Define standards for writing idempotent, secure, and maintainable Ansible playbooks and roles.

## 1. Idempotency

- **Virtual Environments**: All development MUST occur within a project-local virtual environment (`.venv` by default). Global `pip install` is PROHIBITED.
- **Tool Localization**: Linters (`ruff`) and other development tools MUST be installed via `requirements-dev.txt` into the virtual environment. Use `unirtm install` to initialize the environment.
- **Configurable VENV**: The virtual environment path SHOULD be configurable via the `VENV` variable in the `Makefile` to support subprojects or specific deployment needs (e.g., `make VENV=.custom_venv setup`).
- Use Ansible **modules** (e.g., `ansible.builtin.file`, `ansible.builtin.template`, `ansible.builtin.systemd`) instead of raw `shell` or `command` tasks whenever an appropriate module exists. Module names MUST be **fully qualified** (`ansible.builtin.*`, `community.general.*`, etc.) — never use short-form names (e.g., `copy`, `template`) to avoid ambiguity with collection shadowing.
- When `shell` or `command` tasks are unavoidable, MUST explicitly set `changed_when: false` for read-only/info-gathering commands. If the task tracks real state changes, define a precise `changed_when` condition — do not blindly set `false`.
- `failed_when` is REQUIRED only when the default non-zero exit code check is insufficient (e.g., success/failure depends on stdout patterns).
- Use `ansible.builtin.stat` to check state before acting, rather than relying on error behavior.
- **Idempotence Verification**: In CI pipelines, playbooks MUST run **twice**. The second run MUST report `changed=0`. Any task reporting `changed` on the second run is considered a bug.
- Use `state: present` (or `latest` where appropriate) for packages. Services MUST define both `enabled` and `state`.

## 2. Structure & Organization

- Organize automation into **roles** using the standard directory layout: `tasks/`, `handlers/`, `defaults/`, `vars/`, `templates/`, `files/`, `meta/`.
- Use **collections** (`ansible-galaxy collection install`) for shared, reusable roles across projects. Pin collection versions in `requirements.yml` — never leave version fields empty.
- **Collections Dual-File Sync**: The `ansible_collections` list in `roles/bootstrap/vars/python/default.yml` and the `collections` list in `requirements.yml` MUST remain in perfect synchronization. `bootstrap/vars/python/default.yml` is the single source of truth. Any change to `ansible_collections` MUST be immediately reflected in `requirements.yml` with a specific version. Both files MUST be committed together in the same commit. Desync causes "couldn't resolve module/action" failures.
- Follow the standard project layout:

  ```text
  inventory/          # Per-environment inventory files or directories
  roles/              # Reusable roles
  playbooks/          # Top-level orchestration playbooks
  group_vars/         # Group-level variable overrides
  host_vars/          # Host-level variable overrides
  requirements.yml    # Galaxy collection and role dependencies
  ```

- **Thin Playbooks**: Playbooks SHOULD be thin — responsible only for host mapping and role orchestration. Complex task logic MUST be encapsulated in independent roles, not inline in playbook `tasks:` blocks (except `debug`/`setup`).
- **Small Files**: Single YAML files SHOULD be under 200 lines. Split complex logic into sub-task files (e.g., `install.yml`, `configure.yml`, `verify.yml`). Avoid "God Files".
- **Task Execution Order**: Tasks MUST follow the logical flow: `Validate → Prepare → Configure → Install → Verify`.
- **Full Lifecycle Awareness**: Roles must handle the full lifecycle, not just initial deployment. Roles SHOULD accept `state: absent` to cleanly remove all created files, users, and service configs.
- **Transactional Atomicity**: Use `block` / `rescue` / `always` for multi-step workflows to ensure rollback and cleanup on failure.

## 3. Variables & Secrets

- Use `defaults/main.yml` for role defaults (lowest precedence, easily overridable by `group_vars` or `--extra-vars`).
- Use `vars/main.yml` for role constants that are not intended to be overridden externally.
- **Never store plaintext secrets** in variable files or version control. Use **Ansible Vault** to encrypt sensitive values. Sensitive variable names SHOULD end with `_password`, `_secret`, or `_key` for auditability.
- Store vault-encrypted values in Git. Store the vault password in a secrets manager (HashiCorp Vault, AWS Secrets Manager, etc.) — never commit the vault password itself.
- Use `group_vars/` and `host_vars/` directories for variable management. Avoid defining variables directly inside inventory files (`hosts.ini` / `inventory.yml`).
- **Structured Variable Hierarchy** (`defaults` → `vars` → `group_vars` → `host_vars` → `extra_vars`). All role control variables MUST be namespaced with the role name (e.g., `nginx_port`, `redis_enabled`) to allow clean overrides and avoid collisions.
- **Variable Pollution Prevention**: In task files designed for iterative invocation (loaders, repeating `include_role`), include an explicit variable reset block at the top of the file using `set_fact` to null/empty all functional variables before normalizing them. This prevents values from a previous loop iteration leaking into the next.
- **Naked Variables**: PROHIBITED. Always wrap variables in Jinja2 quotes: `path: "{{ my_path }}"`.

## 4. Naming & Style

- Use `snake_case` for all variable names, task names, tag names, and role names. Ansible variable names MUST use underscores (`_`), never hyphens (`-`). If a system package name contains hyphens (e.g., `my-app`), define a bridge variable (e.g., `my_app_package_name: "my-app"`) and reference it in tasks instead of hardcoding the hyphenated name.
- Give every task a descriptive `name:` field wrapped in double quotes. Never leave a task unnamed — unnamed tasks produce unreadable output. Exception: `include_role`, `import_role`, `include_tasks`, `import_tasks`, and `ansible.builtin.assert` MUST NOT have a `name:`.
- **OS Fingerprint Suffix**: If a task has a `name:`, MUST append the OS fingerprint suffix: `{{ '(' ~ os_fingerprint ~ ')' if os_fingerprint is defined else '' }}`. This ensures task output is traceable to the target OS in multi-platform runs.
- Every task and key variable definition MUST be preceded by an inline comment explaining its purpose or rationale (explain the "Why", not the "What").
- Use `notify` and `handlers` for operations that should run only on change (e.g., reload a service only when its config changes).
- Use **tags** semantically on all tasks. Mandatory standard tags: `install`, `config`, `service`, `security`, `assert`. Use `tags: ["always"]` ONLY for plumbing tasks (facts derivation, environment checks, global skip flags, logging) — NEVER on tasks that modify system state or on routing tasks (`include_role`, `include_tasks`, etc.).
- Organize code with a multi-level commenting hierarchy:
  1. **Section Headers (Banner Style)**: Use a symmetric `# --- Section Name ---` banner to visually isolate major logical sections.
  2. **Task Descriptions (Inline)**: Use single-line comments immediately above a task to explain the design decision.

## 5. Conditional Logic (Type Safety)

- **Existence checks**: Use `var is defined` or `var is not defined`. NEVER use bare `when: var` or `when: not var`.
- **Boolean checks**: Use `when: var | default(false, true) | bool`. NEVER use `when: var == true`.
- **Compound logic**: Avoid `var and other_var`; use explicit expressions like `var is defined and var | bool`.
- **Jinja2 Complexity**: Complex Jinja2 logic (more than 2 conditions in `when:`, complex filter chains) MUST be extracted to a `set_fact` task with a meaningful name (e.g., `should_restart_service: true`) before use. Never embed complex expressions inline in task parameters.
- **Environment Agnostic**: Roles MUST NOT contain logic hardcoded to environment names (e.g., `when: env == 'prod'`). Use **feature flags** (e.g., `monitoring_enabled: true`) controlled by inventory variables instead.

## 6. Execution Safety

- **Privilege Escalation**: Tasks that modify system state, access restricted paths, or involve cross-user operations MUST explicitly define `become`. Avoid setting `become: true` globally on all plays. Never use `sudo` inside `shell`/`command` tasks. `become` is NOT needed for read-only `debug`, `set_fact`, or `stat` on non-restricted paths.
- **Modules requiring `become: true`**: package management (`apt`, `dnf`, `yum`, `apk`, `pip` system-wide), service management (`systemd`, `service`), user/group management, restricted filesystem operations (`/etc`, `/usr`, `/var`, `/opt`), system configuration (`hostname`, `sysctl`, `timezone`), network/firewall (`iptables`, `ufw`, `firewalld`), low-level operations (GPG, cert updates, `mount`, `modprobe`).
- **`delegate_to: localhost`** MUST only be used for control-node operations: probing role structures, reading local files via `lookup`/`stat`, or executing global sync logic. All system-level operations (packages, services, remote path probing like `/etc/`) MUST run on target hosts.
- **`set_fact` with `delegate_to: localhost`**: PROHIBITED — facts MUST be host-bound to prevent variable pollution and race conditions. For global one-off facts, use `run_once: true` explicitly.
- **Local task concurrency**: When using `delegate_to: localhost`, decide `run_once` based on operation type:
  - Global/one-off operations (compiling, sending a notification, encrypting a shared file): MUST use `run_once: true`.
  - Host-specific operations (generating per-host config, removing a specific IP from load balancer): PROHIBITED from using `run_once`.
- **Shell/Command hygiene**: MUST use `set -euo pipefail` in `shell` module scripts **IF** the target uses `bash`. If targeting strict POSIX systems (Alpine, Crux) where `/bin/sh` is `dash`/`busybox`, `set -o pipefail` is a Bashism and **will crash the script**. For maximal portability across minimal containers, limit scripts to `set -eu`. When `pipefail` is absolutely necessary, explicitly set `executable: /bin/bash` on the Ansible task.
- **Path robustness**: `shell`/`command` tasks involving tool detection or non-standard binaries MUST explicitly set the `PATH` environment variable to ensure reliability in non-interactive shells where user profiles are not loaded.
- **Loops**: Use `loop:`, NEVER the deprecated `with_items:`.
- **Deprecated modules**: PROHIBITED (`apt-key`, old `include`, `raw include`, etc.).
- **Recursion Protection**: Never include `main.yml` in dynamic `first_found` task resolution lists to prevent infinite recursion.

## 7. File & Template Operations

- **Template over Patch**: Primary configuration files MUST use `ansible.builtin.template`. Abuse of `lineinfile` / `blockinfile` is PROHIBITED (except for files owned by external packages where rendering the full file is unsafe).
- All file tasks MUST explicitly define `mode`, `owner`, and `group`. Use absolute paths only.
- **Single Source of Truth (SSOT)**: Core data definitions (IPs, versions, ports, paths) MUST exist in exactly one place. Never hardcode the same value in multiple locations — reference it via Jinja2 variables.
- **Secure by Default**: All configurations must be closed/private by default: bind services to `127.0.0.1`, default file permissions to `0600`/`0700`, default firewall policy to `DENY`. External exposure requires explicit variable activation (e.g., `expose_service: true`).

## 8. Error Handling & Verification

- `ignore_errors: true` is PROHIBITED unless justified with an inline comment explaining exactly why the error can be safely ignored.
- **Outcome Verification**: After deploying critical services, MUST follow up with `wait_for` (port check) or `uri` (HTTP health check) to verify availability. Do not blindly trust module return codes.
- **Human-Centric Failure Messages**: When using `assert` or `fail`, the `msg` field MUST clearly state the current value, the threshold/requirement, and the resolution path.
  - ❌ `msg: "Check failed."`
  - ✅ `msg: "Memory ({{ ansible_memtotal_mb }}MB) is below the minimum required 2048MB for this role."`
- **Dry Run Safety**: All tasks MUST support `--check` mode. Read-only `command`/`shell` tasks (gathering info, registering variables) MUST set `check_mode: false` to ensure variables are registered even during dry-run.

## 9. Tags & Always Tag

- Use the `always` tag ONLY for critical infrastructure tasks that MUST run regardless of tag filtering:
  - **Required**: OS detection, environment sanity checks, fact derivation, global skip logic, logging/auditing tasks.
  - **Prohibited**: Any task that modifies system state (packages, files, services), business logic tasks, routing tasks (`include_role`, `include_tasks`).
- Use meaningful semantic tags: `install`, `config`, `service`, `security`, `assert`, `validate`.
- Apply tags consistently — every task should have at least one tag.

## 10. Cross-Platform & macOS Compatibility

- AI agents MUST NOT hardcode OS-specific logic in playbooks. Use normalized facts (`os_family`, `os_distribution`, `os_pkg_mgr`) rather than raw `ansible_*` facts for branching logic.
- **Fact Unification**: Before using raw `ansible_*` facts, check for an existing normalized `os_*` variable. If one doesn't exist, define it centrally to maintain a single source of truth.
- **macOS (Darwin) specifics**:
  - Home directories: use `/Users/` (not `/home/`). Prefer `ansible_user_home` fact.
  - Identity management: PROHIBITED from using `getent` on Darwin. Use `dscl` or `id` for checks.
  - Package management: Treat **Homebrew** and **MacPorts** as equal first-class citizens. If a package has different names between them, use a Jinja2 conditional based on `os_pkg_mgr` to select the correct name.
  - Service management: Init system is `launchd`. Use `systemsetup -setremotelogin on` for SSH access control where applicable.
  - Tasks targeting `/proc` (WSL detection, cgroup versioning) MUST be skipped on Darwin: `when: os_family != 'darwin'`.
- **Variable Hierarchy for Multi-Distribution Support**: `default.yml` → `{family}.yml` → `{distro}.yml` → `{distro}-{version}.yml`. Create distribution-specific files ONLY when configurations genuinely differ. If 90%+ of systems share the same settings, use `default.yml`.
- **Package Name Divergence**: If the same application has inconsistent package names across distributions, explicitly specify the correct `app_packages` in each distribution's configuration file.

## 11. Delivery & Maintenance

- **Dependency Determinism**: External dependencies (collections, roles) MUST be version-pinned in `requirements.yml`. Never leave version fields empty to prevent upstream breakage.
- **Semantic Versioning**: Releases MUST follow SemVer (MAJOR.MINOR.PATCH). Major version increments for breaking changes. Git tags are the sole anchor for releases.
- **Continuous Documentation**: Documentation MUST be updated synchronously with code. Any change to `defaults/` variables MUST be reflected in the role's `README.md` immediately.
- **Architectural Principles (AOEL)**:
  - **Auditable**: Every significant routing or loader decision MUST be traceable (e.g., via audit trail facts or structured log output).
  - **Overridable**: All role control variables MUST follow the variable hierarchy and be namespaced to allow clean `group_vars` overrides.
  - **Extensible**: Logic MUST be decoupled into atomic task files. Use lookup tables and metadata dictionaries instead of hardcoded conditional blocks to enable extension without modifying core role files.
  - **Lean**: Do NOT create configuration files or inject environment variables if the corresponding tool is not installed. Follow the "detect tool presence before applying configuration" principle to minimize side effects.

## 12. Testing & Linting

- Lint all playbooks and roles with **`ansible-lint`** in CI. Fix all warnings and errors before merging. Commit `.ansible-lint` config to enforce custom rules. Global rule suppression via config is PROHIBITED — use local `# noqa` waivers with explanatory comments only.
- Test roles with **Molecule** using Docker or Podman as the driver. Write idempotence tests: run `converge` twice, assert `changed=0` on the second run.
- Use `--check` (dry-run) mode combined with `--diff` in CI to preview changes before applying to production.
- Use `ansible-playbook --syntax-check playbook.yml` as a lightweight pre-flight check in CI before running the full Molecule suite.
- **Zero-Tolerance Linting**: Style is function. All CI lint warnings MUST be fixed. No global suppression.

## 13. App Development Standards (Multi-Distribution)

- **Compatibility-First**: App configurations MUST prioritize maximum system compatibility. Support at minimum: Alpine Linux, Debian/Ubuntu, RHEL/Rocky/AlmaLinux, Fedora, Arch Linux, and macOS (Homebrew + MacPorts).
- **Package Loader Prefix Syntax**: The `package_loader` supports 38+ installation methods via unified prefix syntax. Use the correct prefix for the target ecosystem:

  | Prefix category   | Examples                                             |
  | ----------------- | ---------------------------------------------------- |
  | System packages   | `nginx`, `curl` (no prefix)                          |
  | macOS native      | `.dmg`, `.pkg`, `.app`, `mas:`                       |
  | Universal Linux   | `snap:`, `flatpak:`, `nix:`, `aur:`                  |
  | Language managers | `pip:`, `npm:`, `cargo:`, `go:`, `gem:`, `composer:` |
  | Windows           | `winget:`, `choco:`, `scoop:`                        |

- **Variable Hierarchy**: Follow the loader hierarchical loading order (low → high priority): `default.yml` → `app_name.yml` → `family.yml` → `distro.yml` → `mode.yml` → `mode/distro.yml`.
- **DRY File Strategy**:
  - Same config for 90%+ systems → use `default.yml` only.
  - Same config within an OS family → use `{family}.yml` (e.g., `debian.yml`, `redhat.yml`).
  - Unique config for a distro → create `{distro}.yml` only when necessary.
  - Never create distribution-specific files for identical configurations.
- **Package Name Divergence**: If a package has different names across distributions (e.g., `redis-server` on Debian vs `redis` on Alpine), specify `app_packages` explicitly in each distribution's config file. For version-based package replacement (e.g., Redis → Valkey on RHEL 10+), use Jinja2 version detection:

  ```yaml
  app_packages: >-
    {{
      ['valkey'] if (
        (os_distribution == 'RedHat' and os_distribution_major_version | int >= 10) or
        (os_distribution == 'Fedora' and os_distribution_major_version | int >= 41)
      ) else ['redis']
    }}
  ```

- **Documentation Annotation**: Every distribution config file MUST have a header comment listing which systems it covers and a `# WHY:` comment for any non-obvious decision.
- **Reference Pattern**: Before developing new app configurations, study `roles/native/tasks/package_loader/` for multi-distribution support strategy and OS loader routing mechanism.

## 14. Scenario Design Patterns

- **Matrix Scenario (Recommended)**: For managing multi-software deployments, use the "Explicit List + Conditional Activation" pattern. List ALL supported applications in `tasks/main.yml` and activate them with boolean facts:

  ```yaml
  - name: "Matrix: Deploy Redis {{ '(' ~ os_fingerprint ~ ')' if os_fingerprint is defined else '' }}"
    ansible.builtin.include_role:
      name: "app"
    vars:
      app_name: "redis"
      app_service_enabled: true
    when: is_redis | default(false, true) | bool or is_db_node | default(false, true) | bool
  ```

- **Benefits**: Configuration is explicitly visible, supporting granular differential config (e.g., enable service for databases, install-only for tools). Avoids implicit activation and hidden dependencies.
- **Role Interface Preference**: MUST prioritize `role: app` unified interface over direct low-level module or native role invocations for software deployment.

## 15. Container Volume Configuration (Cross-Platform)

- **Directory Structure**: Use standardized paths following FHS:
  - Linux/macOS: `/opt/data/containers/volumes/{app_name}`
  - Windows: `C:/data/containers/volumes/{app_name}`
- **Ownership Defaults**: Provide platform-appropriate default ownership:

  | Platform | Owner           | Group            |
  | -------- | --------------- | ---------------- |
  | Linux    | `root`          | `root`           |
  | macOS    | `root`          | `wheel`          |
  | Windows  | `Administrator` | `Administrators` |

- **Volume Strategy**: Prefer named volumes for portability. Use bind mounts only when direct host access is required.
- **Directory Creation Location**: Volume base directories MUST be created in `container_loader` (after engine detection, before engine dispatch), NOT in the `init` role.
- **SELinux Support**: On RHEL-based systems with SELinux enabled, MUST set `container_file_t` SELinux type on volume directories using `ansible.posix.sefcontext`. Apply only when `os_family == 'redhat'` and `ansible_selinux.status == 'enabled'`.
- **Permission Auto-Detection (Zero-Config)**: Container roles SHOULD implement two-stage UID/GID probing:
  1. **Stage 1**: Extract `.Config.User` via `docker inspect`. Use immediately if numeric.
  2. **Stage 2**: If the result is a string name, run a minimal temporary container (`sh -c 'id -u && id -g'`) to resolve the numeric IDs.
- **Image Best Practice**: In `Dockerfile`, prefer numeric `USER UID:GID` (e.g., `USER 1001:1001`) over symbolic names to improve deployment performance and cross-platform compatibility.

## 16. Shell Script Standards (POSIX Compatibility)

All shell scripts (`.sh`) invoked by Ansible MUST be POSIX-compatible unless Bash-specific features are explicitly required. For detailed shell scripting rules (including POSIX patterns, safety flags, and cross-platform wrappers), refer to [shell.md](shell.md).

## 17. Windows Platform Standards

- **Installation Detection**:
  - **MSI/EXE/Winget installers**: PROHIBITED from using `win_stat` on hardcoded paths (e.g., `C:\Program Files`). MUST use `ansible.windows.win_powershell` to query Registry Uninstall keys:

    ```yaml
    - name: "Check if App is installed (Registry)"
      ansible.windows.win_powershell:
        script: |
          $keys = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall'
          )
          $app = $keys | ForEach-Object {
            if (Test-Path $_) {
              Get-ChildItem -Path $_ -ErrorAction SilentlyContinue |
              Get-ItemProperty | Where-Object { $_.DisplayName -match '^AppName' }
            }
          } | Select-Object -First 1
          if ($app) { $ansible.Result = @{ installed = $true } }
          else { $ansible.Result = @{ installed = $false } }
      register: _app_reg_check
    ```

  - **Portable installs (Zip/Direct)**: `win_stat` is permitted, but the path MUST be defined via a variable (e.g., `{{ app_install_dir }}`). Hardcoded absolute paths are PROHIBITED.

- **Execution Safety**: When using `delegate_to: localhost` with a Python-based `ansible_python_interpreter`, MUST explicitly set `vars: ansible_python_interpreter: "{{ ansible_playbook_python }}"` to prevent virtual environment pollution from the managed node.
