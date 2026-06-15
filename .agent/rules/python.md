- **Virtual Environments REQUIRED**: All development and testing MUST be performed within a virtual environment. Use `unirtm install` to create and configure the environment (defaulting to `.venv`).
- **Dependency Management**: Dev dependencies (linters, testers) MUST be locked in `requirements-dev.txt`.

> Objective: Define standards for modern, clean, and maintainable Python code, covering version management, tooling, type hints, code style, async patterns, and testing.

## 1. Version, Environment & Project Structure

- **Package Management Hierarchy**:
  - **unirtm**: Manages the `python` and `uv` **executors** (binary runtimes).
  - **uv**: Manages **project dependencies** (libraries) and **virtual environments** (`.venv`) with O(1) performance.
- Target **Python 3.12+** for new projects. Specify exact version strictly in `.unirtm.toml`.
- Never install project dependencies into the system Python. Always use a virtual environment managed by `uv`.

- **Strict Version Pinning (MANDATORY)**: All dependencies in `pyproject.toml` MUST use **exact version numbers**. Never use range operators (`>=`, `~=`, `^`, `*`). Unpinned versions introduce non-reproducible builds and supply-chain risk.
- Use **`uv lock`** or **`poetry.lock`** for reproducible installs. Always commit the lock file to version control. Use `uv sync --frozen` or `pip install --require-hashes` in CI to guarantee deterministic installs.
- Commit `pyproject.toml` with fully configured tool settings (ruff, mypy, pytest, coverage):

  ```toml
  [project]
  name = "myproject"
  version = "1.0.0"
  requires-python = ">=3.12"
  # ❌ WRONG — version ranges are non-deterministic
  # dependencies = [
  #   "fastapi>=0.115",
  #   "sqlalchemy>=2.0",
  # ]

  # ✅ CORRECT — exact, auditable, reproducible
  dependencies = [
    "fastapi==0.115.2",
    "sqlalchemy==2.0.35",
  ]

  [project.optional-dependencies]
  dev = ["pytest", "pytest-cov", "ruff", "mypy"]

  [tool.ruff]
  target-version = "py312"

  [tool.ruff.lint]
  select = ["E", "W", "F", "I", "UP", "B", "C4", "SIM"]
  ignore = ["E501"]  # E501 = line-too-long, intentionally disabled

  [tool.mypy]
  strict = true
  python_version = "3.12"
  ignore_missing_imports = true

  [tool.pytest.ini_options]
  asyncio_mode = "auto"
  testpaths = ["tests"]
  ```

### Project Layout

```text

myproject/
├── pyproject.toml
├── uv.lock              # pinned dependencies
├── src/
│   └── myproject/       # src-layout (preferred for installable packages)
│       ├── __init__.py
│       ├── models/
│       ├── services/
│       └── api/
└── tests/
    ├── conftest.py
    ├── unit/
    └── integration/

```

Use **src-layout** to prevent accidental imports from the working directory.

## 2. Formatting, Linting & Static Analysis

- Format all code with **`ruff format`** (drop-in Black replacement). Enforce in CI:

  ```bash
  ruff format --check .   # fail CI on unformatted code
  ruff format .           # reformat all files
  ```

- Lint with **`ruff check`** — it replaces `flake8`, `isort`, `pyupgrade`, `pylint` (partially), and more. Enforce in CI with `--no-fix`:

  ```bash
  ruff check .             # lint check
  ruff check --fix .       # auto-fix fixable violations
  ```

- Type-check with **`mypy`** (`--strict`) or **`pyright`** (preferred for VS Code users). Run in CI:

  ```bash
  mypy . --strict
  ```

- Run **`bandit -r src/`** in CI for security linting: detects hardcoded secrets, `subprocess.shell=True`, insecure YAML parsing, and other common Python security issues.
- Set up **`pre-commit`** hooks for `ruff check --fix`, `ruff format`, and `mypy` so formatting and type errors are caught before reaching CI:

  ```yaml
  # .pre-commit-config.yaml
  repos:
    - repo: https://github.com/charliermarsh/ruff-pre-commit
      rev: v0.4.0
      hooks:
        - id: ruff
          args: [--fix]
        - id: ruff-format
  ```

## 3. Type Hints & Type Safety

- Add type annotations to **all** function signatures and class attributes in new code. Backfill annotations as you touch existing code:

  ```python
  def fetch_user(user_id: str, *, active_only: bool = True) -> User | None:
      ...
  ```

- Use **modern union syntax** (Python 3.10+):
  - `X | None` instead of `Optional[X]`
  - `X | Y` instead of `Union[X, Y]`
  - `list[str]` instead of `List[str]`, `dict[str, Any]` instead of `Dict[str, Any]`
- Use `from __future__ import annotations` for forward-compatible annotation evaluation on Python < 3.10.
- Use **`Protocol`** for structural subtyping (duck-typing contracts) instead of ABCs when possible:

  ```python
  from typing import Protocol

  class Serializable(Protocol):
      def to_dict(self) -> dict[str, object]: ...

  def serialize(obj: Serializable) -> str:
      return json.dumps(obj.to_dict())
  ```

- Use **`TypeVar`** and `Generic[T]` for reusable generic types. Use `ParamSpec` for forwarding callable signatures and `TypeAlias` for readable type aliases.
- Use **Pydantic v2** or **`@dataclass`** for structured domain models — avoid plain `dict` with string keys for typed data:

  ```python
  from pydantic import BaseModel, EmailStr

  class CreateUserRequest(BaseModel):
      name: str
      email: EmailStr
      role: Literal["admin", "viewer"] = "viewer"
  ```

- Never use `Any` without an explanatory comment. Use `cast()` sparingly — only when the type system genuinely cannot infer the type.

## 4. Code Style, Patterns & Anti-Patterns

### Naming & Style

- Follow **PEP 8** naming: `snake_case` for variables/functions/modules, `PascalCase` for classes, `UPPER_SNAKE_CASE` for module-level constants.
- Prefer **f-strings** for string interpolation: `f"Hello {name!r}"`. Use `f"{value:.2f}"` for number formatting. Avoid `.format()` and `%` formatting in new code.

### Patterns

- Use **`pathlib.Path`** for all file system operations instead of `os.path`:

  ```python
  from pathlib import Path
  config = Path("config") / "settings.json"
  data = config.read_text(encoding="utf-8")
  ```

- Use **context managers** (`with`) for all managed resources (files, DB connections, locks, HTTP sessions):

  ```python
  # ✅ Context manager ensures cleanup on error
  async with aiofiles.open(path, "r") as f:
      content = await f.read()
  ```

- Use `match`/`case` (Python 3.10+ structural pattern matching) for complex conditional logic:

  ```python
  match event.type:
      case "user.created":
          await handle_user_created(event)
      case "order.placed" if event.total > 1000:
          await handle_high_value_order(event)
      case _:
          logger.debug("Unhandled event type: %s", event.type)
  ```

- Use **generators** and lazy evaluation for large data processing. Never load entire large datasets into memory:

  ```python
  def process_records(filepath: Path) -> Iterator[ProcessedRecord]:
      with filepath.open() as f:
          for line in f:
              yield transform(line)
  ```

### Logging

- Use the **`logging`** module for all diagnostic output. Never use `print()` in production:

  ```python
  import logging
  logger = logging.getLogger(__name__)

  logger.info("Processing user %s started", user_id)
  logger.error("Failed to process user %s: %s", user_id, exc, exc_info=True)
  ```

- Use **`structlog`** or `python-json-logger` for structured JSON log output in production services.

## 5. Testing & CI

### pytest

- Use **`pytest`** for all tests. Organize tests under `tests/unit/` and `tests/integration/`:

  ```python
  import pytest

  @pytest.mark.parametrize("email,valid", [
      ("user@example.com", True),
      ("invalid", False),
      ("", False),
  ])
  def test_validate_email(email: str, valid: bool) -> None:
      assert validate_email(email) == valid
  ```

- Use **`pytest.mark.parametrize`** for table-driven tests (multiple input combinations).
- Use `pytest-asyncio` for async tests. Configure `asyncio_mode = "auto"` in `pyproject.toml` so all async tests run automatically.
- Use `pytest-mock` or `unittest.mock` for mocking. Prefer **dependency injection** for testability over patching globals with `monkeypatch.setattr`.

### Coverage & CI

- Enforce minimum coverage with `pytest-cov`:

  ```bash
  pytest --cov=src --cov-fail-under=80 --cov-report=xml --cov-report=term
  ```

- **CI pipeline order** (fail-fast gates first):

  ```bash
  ruff check .                        # linting
  ruff format --check .               # formatting
  mypy . --strict                     # type checking
  bandit -r src/                      # security scan
  pytest --cov --cov-fail-under=80    # tests + coverage
  ```

- Use **`tox`** or **`nox`** to test against multiple Python versions (3.11, 3.12) in isolation for libraries and packages.
- Use **`Testcontainers`** (`testcontainers-python`) for integration tests requiring real PostgreSQL, Redis, or Kafka:

  ```python
  from testcontainers.postgres import PostgresContainer

  @pytest.fixture(scope="session")
  def postgres():
      with PostgresContainer("postgres:16-alpine") as pg:
          yield pg.get_connection_url()
  ```
