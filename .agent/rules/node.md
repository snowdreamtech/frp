# Node.js Development Guidelines

> Objective: Define standards for writing robust, secure, and maintainable Node.js applications, covering package management, environment setup, coding patterns, error handling, security, and quality tooling.

## 1. Package Management

- **Package Management Hierarchy**:
  - **unirtm**: Manages the `node` and `pnpm` **executors** (binary runtimes).
  - **pnpm**: Manages **project dependencies** (libraries) and Node.js-specific scripts.
- **Dependency Classification**:
  - `dependencies`: Runtime requirements only.
  - `devDependencies`: Build tools, linters, test frameworks.
  - `peerDependencies`: When creating plugins or shared libraries.
- **Strict Version Pinning (MANDATORY)**: All dependencies in `package.json` MUST use **exact version numbers**. Never use range operators (`^`, `~`, `>=`, `*`, `latest`). Unpinned versions introduce non-reproducible builds.

  ```jsonc
  // ✅ CORRECT — exact, auditable, reproducible
  { "express": "4.18.2", "lodash": "4.17.21" }
  ```

- **Lockfile**: Always commit `pnpm-lock.yaml`. Use `pnpm install --frozen-lockfile` in CI for deterministic installs.
- **Scripts**: All repeatable actions MUST be defined in `npm scripts` within `package.json`.

## 2. Environment Setup

- **Node Version**: Specify version strictly in `.unirtm.toml`. Use `unirtm` for local version management.
- **Environment Variables**: Never commit `.env` files. Use `.env.example` as a documentation template. Validate all required env vars at startup using a schema validator (e.g., `zod`, `envalid`).

  ```typescript
  // Validate env vars at startup
  import { z } from "zod";
  const env = z.object({
    PORT: z.coerce.number().default(3000),
    DATABASE_URL: z.string().url(),
    NODE_ENV: z.enum(["development", "production", "test"]),
  }).parse(process.env);
  ```

## 3. Tool Execution (Performance First)

- **Anti-npx Policy**: Avoid `npx` for frequently used tools (lint, format, test). Its startup overhead is significant.
- **Preferred Method**: Use direct execution of pre-installed binaries (via `unirtm install` or `npm run <command>`).

## 4. Coding Style

- **Strict Mode**: Always use `"use strict";` or enable it via TypeScript (`"strict": true` in `tsconfig.json`).
- **Async/Await**: Prefer `async/await` over raw Promises or callbacks.
- **Module System**: Use ESM (`import`/`export`) for new code. Set `"type": "module"` in `package.json`.

## 5. Error Handling

- **Never swallow errors silently**. Always handle rejections explicitly:

  ```javascript
  // ❌ Silent failure
  somePromise().catch(() => {});

  // ✅ Explicit handling
  somePromise().catch((err) => {
    logger.error("Operation failed", { error: err.message, stack: err.stack });
    throw err; // or handle gracefully
  });
  ```

- **Use `AsyncLocalStorage`** for request-scoped context (e.g., correlation IDs) instead of passing context through every function call.
- **Typed errors**: Create custom error classes for domain errors:

  ```typescript
  class NotFoundError extends Error {
    readonly statusCode = 404;
    constructor(resource: string, id: string) {
      super(`${resource} with id '${id}' not found`);
      this.name = "NotFoundError";
    }
  }
  ```

- **Global handlers**: Always register `process.on("uncaughtException")` and `process.on("unhandledRejection")` to prevent silent crashes:

  ```javascript
  process.on("unhandledRejection", (reason) => {
    logger.error("Unhandled rejection", { reason });
    process.exit(1);
  });
  ```

## 6. Security

- **Dependency Auditing**: Run `npm audit` in CI. Block builds on `critical` or `high` severity vulnerabilities.
- **Input Validation**: Validate and sanitize all user input before use. Never trust `req.body`, `req.query`, or `req.params` directly.
- **Avoid `eval()`** and `new Function()` — they execute arbitrary code.
- **Helmet**: Use `helmet` middleware in Express/Fastify to set secure HTTP headers.
- **Rate Limiting**: Apply rate limiting to all public API endpoints to prevent abuse.
- **Secrets**: Never log secrets, tokens, or passwords. Use structured logging with field-level redaction.

## 7. Performance

- **Streams**: Use Node.js streams for large data processing instead of loading into memory:

  ```javascript
  // ❌ Loads entire file into memory
  const data = fs.readFileSync("large.csv", "utf8");

  // ✅ Streams data incrementally
  fs.createReadStream("large.csv").pipe(csvParser).pipe(outputStream);
  ```

- **Worker Threads**: Offload CPU-intensive tasks (image processing, crypto, compression) to `worker_threads` to avoid blocking the event loop.
- **Cluster Module**: For production HTTP servers, use the `cluster` module or a process manager (PM2) to utilize all CPU cores.
- **`--max-old-space-size`**: Set an appropriate memory limit to prevent unbounded memory growth in long-running processes.

## 8. Testing & Quality

- **Testing Framework**: Use `Vitest` (preferred) or `Jest`. All business logic MUST have unit tests.
- **Coverage**: Enforce minimum 80% coverage. Fail CI if coverage drops below threshold.
- **Integration Tests**: Use `supertest` for HTTP endpoint testing.
- **Mocking**: Use `vi.mock()` (Vitest) or `jest.mock()` for module-level mocking. Avoid mocking too broadly.
- **Linting**: Use `ESLint` with `eslint-config-prettier` to avoid formatting conflicts with Prettier.
- **Formatting**: Use `Prettier` for consistent code style. Run via `npm run format`.
- **Pre-commit**: Always run `make lint` before pushing to ensure all checks pass.
