# Windows Shell Migration Guide

## Overview

This project has simplified its cross-platform support by removing Windows-specific wrapper scripts (`.bat` and `.ps1` files). We now rely on POSIX shell scripts (`.sh`) for all platforms, including Windows.

## Why This Change?

### Before

- 131 `.sh` scripts (core logic)
- 73 `.bat` and `.ps1` wrappers (Windows compatibility)
- **Total: 204 scripts** to maintain

### After

- 131 `.sh` scripts (works on all platforms)
- **Total: 131 scripts** to maintain

### Benefits

1. **Reduced Maintenance**: 36% fewer files to maintain
2. **Single Source of Truth**: No logic duplication between `.sh` and `.ps1`
3. **Consistency**: Same behavior across all platforms
4. **Simpler Testing**: Only need to test one set of scripts
5. **Industry Standard**: Most modern development tools use POSIX shells

## Migration Steps

### For Windows Users

#### Option 1: Git Bash (Recommended)

Git Bash is included with [Git for Windows](https://git-scm.com/download/win) and provides a complete POSIX shell environment.

**Installation**:

1. Download and install Git for Windows
2. During installation, select "Git Bash Here" context menu option
3. Open Git Bash and navigate to your project

**Usage**:

```bash
# All scripts work directly
./scripts/setup.sh
./scripts/test.sh
unirtm run lint
```

#### Option 2: WSL (Windows Subsystem for Linux)

WSL provides a full Linux environment on Windows.

**Installation**:

```powershell
# In PowerShell (Administrator)
wsl --install
```

**Usage**:

```bash
# Navigate to your project in WSL
cd /mnt/c/path/to/project

# Run scripts normally
./scripts/setup.sh
```

#### Option 3: Windows Terminal + Git Bash

Windows Terminal provides a modern terminal experience.

**Installation**:

1. Install Windows Terminal from Microsoft Store
2. Install Git for Windows
3. Add Git Bash profile to Windows Terminal

**Usage**:

```bash
# Select Git Bash profile in Windows Terminal
./scripts/setup.sh
```

### Script Migration Table

| Old Command (PowerShell/CMD) | New Command (Git Bash/WSL) |
| ---------------------------- | -------------------------- |
| `.\scripts\setup.ps1`        | `./scripts/setup.sh`       |
| `scripts\setup.bat`          | `./scripts/setup.sh`       |
| `.\scripts\test.ps1`         | `./scripts/test.sh`        |
| `scripts\test.bat`           | `./scripts/test.sh`        |
| `.\scripts\docs.ps1`         | `./scripts/docs.sh`        |
| `scripts\docs.bat`           | `./scripts/docs.sh`        |

**Pattern**: Replace `.\scripts\<name>.ps1` or `scripts\<name>.bat` with `./scripts/<name>.sh`

### CI/CD Migration

No changes needed! GitHub Actions and most CI systems already use POSIX shells by default.

```yaml
# This already works
- name: Setup
  run: ./scripts/setup.sh
```

### IDE Integration

#### Visual Studio Code

Update your tasks in `.vscode/tasks.json`:

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Setup",
      "type": "shell",
      "command": "./scripts/setup.sh",
      "windows": {
        "command": "bash",
        "args": ["./scripts/setup.sh"]
      }
    }
  ]
}
```

#### JetBrains IDEs

Configure shell path in Settings → Tools → Terminal:

- Shell path: `C:\Program Files\Git\bin\bash.exe` (or your Git Bash path)

## Troubleshooting

### "bash: command not found"

**Solution**: Install Git for Windows or WSL.

### "Permission denied"

**Solution**: Make script executable:

```bash
chmod +x scripts/setup.sh
```

### Line Ending Issues

**Solution**: Configure Git to handle line endings:

```bash
git config --global core.autocrlf input
```

### Path Issues in Git Bash

Git Bash uses Unix-style paths. Windows paths are automatically converted:

```bash
# Windows path: C:\Users\username\project
# Git Bash path: /c/Users/username/project
```

## FAQ

### Q: Why not keep both .sh and .ps1?

**A**: Maintaining duplicate scripts is error-prone and time-consuming. Git Bash provides excellent POSIX compatibility on Windows, making separate Windows scripts unnecessary.

### Q: What if I can't install Git Bash?

**A**: You can use WSL, which is built into Windows 10/11. Alternatively, you can use Docker to run scripts in a Linux container.

### Q: Will this affect performance?

**A**: No. Git Bash performance is comparable to native Windows shells for typical development tasks.

### Q: What about PowerShell-specific features?

**A**: This project doesn't use PowerShell-specific features. All functionality is available through POSIX shell scripts.

### Q: Can I still use PowerShell?

**A**: Yes, you can call shell scripts from PowerShell:

```powershell
bash ./scripts/setup.sh
```

## Rollback (If Needed)

If you need to temporarily use old Windows scripts, they are available in git history:

```bash
# Find the last commit with .ps1/.bat files
git log --all --oneline --follow -- "scripts/*.ps1" | head -1

# Checkout specific script from history
git show <commit-hash>:scripts/setup.ps1 > setup.ps1
```

## Support

If you encounter issues with this migration:

1. Check that Git Bash or WSL is properly installed
2. Verify script permissions: `ls -la scripts/`
3. Review this guide's troubleshooting section
4. Open an issue with details about your environment

## References

- [Git for Windows](https://git-scm.com/download/win)
- [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/)
- [POSIX Shell Scripting](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html)
- [ShellCheck](https://www.shellcheck.net/) - Shell script linter

---

**Migration Date**: 2026-04-16
**Affected Scripts**: 73 files (.bat and .ps1)
**Impact**: Windows users need Git Bash or WSL
