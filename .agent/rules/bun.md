# Bun Development Guidelines

> Objective: Define standards for building fast JavaScript/TypeScript applications with the Bun runtime — covering tooling, compatibility, HTTP servers, testing, and bundling for production.

## 1. Runtime, Tooling & Version Management

- Bun is an **all-in-one toolkit**: runtime (JavaScriptCore-based), package manager, bundler, and test runner. Prefer Bun's built-in tools over third-party equivalents where they meet your needs — it reduces toolchain complexity and significantly improves performance.
- **Pin the Bun version** for reproducibility across developers and CI. Use one of:
  - `.unirtm.toml`: `[tools]\nbun = "1.1.38"`
  - `.tool-versions` (asdf): `bun 1.1.38`
  - GitHub Actions: `oven-sh/setup-bun@v2` with `bun-version: "1.1.38"`
  - Never rely on a system-wide Bun installation of unknown version.
- Use **`bun install`** for package management. Commit `bun.lockb` to version control for reproducible installs. Use `--frozen-lockfile` in CI to prevent accidental lockfile mutations:

  ```bash
  bun install --frozen-lockfile
  ```

- **Strict Version Pinning (MANDATORY)**: All dependencies in `package.json` MUST use **exact version numbers**. Never use range operators (`^`, `~`, `>=`, `*`, `latest`).

  ```jsonc
  // ❌ WRONG — version ranges are non-deterministic
  "dependencies": {
    "elysia": "^1.0.0",
    "drizzle-orm": "~0.30.0"
  }

  // ✅ CORRECT — exact, auditable, reproducible
  "dependencies": {
    "elysia": "1.0.27",
    "drizzle-orm": "0.30.10"
  }
  ```

- Use **`bunx`** (Bun's `npx` equivalent) sparingly and only for one-off commands. For repeated linting/formatting in this project, prefer direct execution after `unirtm install` for maximum performance.

  ```bash
  bunx prisma generate
  bunx drizzle-kit push
  ```

- Use **`bun run <script>`** for `package.json` script execution. Define consistent script names across projects:

  ```json
  {
    "scripts": {
      "dev": "bun --hot src/server.ts",
      "build": "bun build src/index.ts --outdir dist --target bun",
      "start": "bun dist/index.js",
      "test": "bun test",
      "typecheck": "bun tsc --noEmit",
      "lint": "bunx eslint ."
    }
  }
  ```

- Configure Bun via **`bunfig.toml`** for project-level defaults:

  ```toml
  [install]
  frozen = true  # equivalent to --frozen-lockfile always on

  [test]
  coverageThreshold = 0.80
  coverage = true
  ```

## 2. Compatibility & Ecosystem

- Bun aims for Node.js compatibility but is **not 100% identical**. Always test with `bun run` early in the project — don't assume Node.js code will work unchanged.
- Packages using **native Node.js addons** (`.node` binaries, N-API gyp builds) may not work with Bun. Identify incompatible dependencies early and plan alternatives:
  - Replace `bcrypt` → `bcryptjs` (pure JS) or use `Bun.password.hash()`
  - Replace native crypto addons with Web Crypto API (`crypto.subtle`)
- Check the [Bun Node.js compatibility table](https://bun.sh/docs/runtime/nodejs-apis) for known API coverage gaps.
- For projects requiring maximum compatibility (e.g., specific Node.js-only packages, native addons), consider using Bun as **package manager and bundler only**, while keeping Node.js as the runtime.
- Migrate strategies for existing Node.js projects:
  1. Switch package manager first (`bun install`), keep runtime as Node.js
  2. Switch runtime for development/testing (`bun --watch`)
  3. Switch runtime for production only after full compatibility verification
- Use `bun pm ls` to inspect installed packages. Use `bun update` with a lockfile review to safely update dependencies.

## 3. TypeScript & JavaScript

- Bun supports TypeScript **natively without a separate compile step**. The runtime strips types at startup with zero configuration.
- **Type-checking is separate** — Bun's native TS execution does not type-check. Always add a `typecheck` script and run it in CI:

  ```bash
  bun run tsc --noEmit   # fails on type errors without emitting files
  ```

- Configure `tsconfig.json` aligned with Bun's runtime and bundler:

  ```json
  {
    "compilerOptions": {
      "target": "ESNext",
      "module": "ESNext",
      "moduleResolution": "bundler",
      "strict": true,
      "noUnusedLocals": true,
      "noUncheckedIndexedAccess": true,
      "types": ["bun-types"] // Bun-specific global types
    }
  }
  ```

- Install `@types/bun` to get IDE support for Bun globals (`Bun.serve`, `Bun.file`, `Bun.password`, etc.):

  ```bash
  bun add -d bun-types
  ```

- Use **`bun --hot`** for hot module reloading during development (replaces `nodemon`/`tsx`). Use **`bun --watch`** for simple file watching that restarts the process on change:

  ```bash
  bun --hot src/server.ts   # hot reload without restart
  bun --watch src/server.ts # restart on change
  ```

## 4. HTTP Server & APIs

- Use Bun's native **`Bun.serve()`** for HTTP servers — it leverages the uWS (µWebSockets) event loop, making it significantly faster than Node.js `http`:

  ```typescript
  const server = Bun.serve({
    port: Bun.env.PORT ?? 3000,
    hostname: "0.0.0.0",

    async fetch(req: Request): Promise<Response> {
      const url = new URL(req.url);

      if (url.pathname === "/health") {
        return Response.json({ status: "ok" });
      }

      if (url.pathname === "/api/users" && req.method === "GET") {
        const users = await userService.list();
        return Response.json({ data: users });
      }

      return new Response("Not Found", { status: 404 });
    },

    error(err: Error): Response {
      console.error(err);
      return Response.json({ error: "Internal Server Error" }, { status: 500 });
    },
  });

  console.log(`Listening on ${server.url}`);
  ```

- For production APIs with routing, middleware, and request validation, prefer a framework with first-class Bun support:
  - **Elysia** — Bun-native, schema-first with type-safe validation, OpenAPI generation
  - **Hono** — multi-runtime, runs on Bun, Cloudflare Workers, Deno, Node.js
  - **Fastify** — mature ecosystem with a Bun adapter
- Use **`Bun.file()`** for efficient file serving without loading into memory:

  ```typescript
  const file = Bun.file("./public/logo.png");
  return new Response(file); // streams from disk efficiently
  ```

- Bun's `Bun.serve()` supports **WebSockets natively** via the `websocket` option — no additional library needed:

  ```typescript
  Bun.serve({
    fetch(req, server) {
      if (server.upgrade(req)) return; // upgrade to WebSocket
      return new Response("HTTP response");
    },
    websocket: {
      message(ws, message) {
        ws.send(`Echo: ${message}`);
      },
      open(ws) {
        ws.subscribe("global");
      },
      close(ws) {
        ws.unsubscribe("global");
      },
    },
  });
  ```

## 5. Testing, Bundling & CI

### Testing

- Use Bun's built-in test runner (**`bun test`**) — it is Jest-compatible (`describe`, `it`, `test`, `expect`, `mock`, `spyOn`, `beforeEach`, `afterEach`) with no configuration:

  ```typescript
  // users.test.ts
  import { describe, it, expect, mock } from "bun:test";
  import { UserService } from "./users.service";

  describe("UserService", () => {
    it("returns user by id", async () => {
      const mockRepo = { findById: mock(() => Promise.resolve({ id: "1", name: "Alice" })) };
      const service = new UserService(mockRepo as any);
      const user = await service.getUser("1");
      expect(user.name).toBe("Alice");
      expect(mockRepo.findById).toHaveBeenCalledWith("1");
    });
  });
  ```

- Tests are auto-discovered from `*.test.ts`, `*.spec.ts`, `*_test.ts`, and `test.ts` files — no configuration needed.
- Run with useful CI flags:

  ```bash
  bun test --bail          # stop on first failure
  bun test --timeout 10000 # fail tests taking > 10 seconds
  bun test --coverage      # generate coverage report
  ```

- Configure coverage thresholds in `bunfig.toml`:

  ```toml
  [test]
  coverageThreshold = 0.80       # fail if < 80% coverage
  coverageReporter = ["text", "lcov"]
  ```

### Bundling & Production

- Use `bun build` to produce optimized production bundles:

  ```bash
  # Server bundle (Bun target — no minification of identifiers)
  bun build ./src/server.ts --outdir ./dist --target bun

  # Browser bundle (tree-shaking and minification)
  bun build ./src/client.ts --outdir ./dist/public --target browser --minify

  # Standalone executable (embeds Bun runtime)
  bun build ./src/server.ts --outfile server --compile
  ```

- Inspect bundle size with `--analysis` flag to identify large dependencies.
- Use the **compiled executable** (`--compile`) for containerless deployments — ships a single binary without requiring Bun to be installed in the target environment.

### CI Pipeline

```bash

# Full quality gate
bun install --frozen-lockfile
bun run typecheck       # tsc --noEmit
bun run lint            # eslint
bun test --bail --coverage  # tests + coverage gate
bun build ...           # production build verification

```
