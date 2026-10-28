import { defineConfig } from "vitepress";

export default defineConfig({
  lang: "en-US",
  title: "Snowdream Tech AI IDE Template",
  description:
    "An enterprise-grade foundational template for multi-AI IDE collaboration, unifying rules, workflows, and configurations across 50+ AI coding assistants.",

  base: "/template/",

  // Ignore dead links for files outside docs directory
  ignoreDeadLinks: [/\/benchmarks\//, /\/\.kiro\//],

  head: [["link", { rel: "icon", href: "/template/favicon.ico" }]],

  themeConfig: {
    logo: "/logo.png",

    nav: [
      { text: "Guide", link: "/guide/introduction" },
      { text: "Rules", link: "/rules/overview" },
      {
        text: "Languages",
        items: [
          { text: "Languages", link: "/rules/languages/node" },
          { text: "Frontend", link: "/rules/frontend/react" },
          { text: "Backend", link: "/rules/backend/express" },
          { text: "Databases", link: "/rules/database/mysql" },
          { text: "Infrastructure", link: "/rules/infrastructure/docker" },
          { text: "Specialized", link: "/rules/specialized/api-design" },
        ],
      },
      { text: "Workflows", link: "/workflows/speckit" },
      { text: "Reference", link: "/reference/unirtm-tasks" },
      {
        text: "Changelog",
        link: "https://github.com/snowdreamtech/template/blob/main/CHANGELOG.md",
      },
    ],

    sidebar: {
      "/guide/": [
        {
          text: "Getting Started",
          items: [
            { text: "Introduction", link: "/guide/introduction" },
            { text: "Quick Start", link: "/guide/quickstart" },
            { text: "Project Structure", link: "/guide/structure" },
            { text: "Configuration", link: "/guide/configuration" },
          ],
        },
        {
          text: "Developer Experience",
          items: [
            { text: "DevContainer", link: "/guide/devcontainer" },
            { text: "Pre-commit Hooks", link: "/guide/precommit" },
            { text: "VS Code Setup", link: "/guide/vscode" },
            { text: "AI IDE Integration", link: "/guide/ai-ide" },
          ],
        },
        {
          text: "CI/CD",
          items: [
            { text: "GitHub Actions", link: "/guide/ci" },
            { text: "GoReleaser", link: "/guide/release" },
          ],
        },
      ],
      "/rules/": [
        {
          text: "Rule System",
          items: [
            { text: "Overview", link: "/rules/overview" },
            { text: "01 · General", link: "/rules/01-general" },
            { text: "02 · Coding Style", link: "/rules/02-coding-style" },
            { text: "03 · Architecture", link: "/rules/03-architecture" },
            { text: "04 · Security", link: "/rules/04-security" },
            { text: "05 · Dependencies", link: "/rules/05-dependencies" },
            { text: "06 · CI & Testing", link: "/rules/06-ci-testing" },
            { text: "07 · Git", link: "/rules/07-git" },
            { text: "08 · Dev Env", link: "/rules/08-dev-env" },
            { text: "09 · AI Interaction", link: "/rules/09-ai-interaction" },
            { text: "10 · UI/UX", link: "/rules/10-ui-ux" },
            { text: "11 · Deployment", link: "/rules/11-deployment" },
            { text: "12 · Docs", link: "/rules/12-docs" },
          ],
        },
      ],
      "/workflows/": [
        {
          text: "SpecKit Workflows",
          items: [
            { text: "Overview", link: "/workflows/speckit" },
            { text: "specify", link: "/workflows/speckit.specify" },
            { text: "plan", link: "/workflows/speckit.plan" },
            { text: "tasks", link: "/workflows/speckit.tasks" },
            { text: "implement", link: "/workflows/speckit.implement" },
            { text: "analyze", link: "/workflows/speckit.analyze" },
            { text: "init", link: "/workflows/snowdreamtech.init" },
          ],
        },
      ],
      "/reference/": [
        {
          text: "Reference",
          items: [
            { text: ".unirtm.toml Commands", link: "/reference/unirtm-tasks" },
            { text: "Supported AI IDEs", link: "/reference/ai-ides" },
            { text: "Linting Tools", link: "/reference/linters" },
            { text: "Tool Installation", link: "/reference/tool-installation" },
            { text: "UniRTM Configuration", link: "/reference/unirtm-configuration" },
            { text: "API Reference", link: "/reference/api-common" },
          ],
        },
        {
          text: "Troubleshooting",
          items: [{ text: "UniRTM Attestation Error", link: "/troubleshooting/unirtm-attestation-error" }],
        },
      ],
      "/rules/languages/": [
        {
          text: "Languages",
          items: [
            { text: "Node.js", link: "/rules/languages/node" },
            { text: "Bun", link: "/rules/languages/bun" },
            { text: "Deno", link: "/rules/languages/deno" },
            { text: "JavaScript", link: "/rules/languages/javascript" },
            { text: "TypeScript", link: "/rules/languages/typescript" },
            { text: "Python", link: "/rules/languages/python" },
            { text: "Go", link: "/rules/languages/go" },
            { text: "Rust", link: "/rules/languages/rust" },
            { text: "Java", link: "/rules/languages/java" },
            { text: "Kotlin", link: "/rules/languages/kotlin" },
            { text: "Swift", link: "/rules/languages/swift" },
            { text: "C#", link: "/rules/languages/csharp" },
            { text: "PHP", link: "/rules/languages/php" },
            { text: "Ruby", link: "/rules/languages/ruby" },
            { text: "C", link: "/rules/languages/c" },
            { text: "C++", link: "/rules/languages/cpp" },
            { text: "Scala", link: "/rules/languages/scala" },
            { text: "Lua", link: "/rules/languages/lua" },
            { text: "R", link: "/rules/languages/r" },
            { text: "Shell", link: "/rules/languages/shell" },
            { text: "WebAssembly", link: "/rules/languages/wasm" },
          ],
        },
      ],
      "/rules/frontend/": [
        {
          text: "Frontend Frameworks",
          items: [
            { text: "React", link: "/rules/frontend/react" },
            { text: "Vue", link: "/rules/frontend/vue" },
            { text: "Angular", link: "/rules/frontend/angular" },
            { text: "Next.js", link: "/rules/frontend/nextjs" },
            { text: "Nuxt", link: "/rules/frontend/nuxt" },
            { text: "Svelte", link: "/rules/frontend/svelte" },
            { text: "Astro", link: "/rules/frontend/astro" },
            { text: "Remix", link: "/rules/frontend/remix" },
            { text: "Flutter", link: "/rules/frontend/flutter" },
            { text: "HTML", link: "/rules/frontend/html" },
            { text: "CSS", link: "/rules/frontend/css" },
          ],
        },
      ],
      "/rules/backend/": [
        {
          text: "Backend Frameworks",
          items: [
            { text: "Express", link: "/rules/backend/express" },
            { text: "NestJS", link: "/rules/backend/nestjs" },
            { text: "Hono", link: "/rules/backend/hono" },
            { text: "Django", link: "/rules/backend/django" },
            { text: "FastAPI", link: "/rules/backend/fastapi" },
            { text: "Flask", link: "/rules/backend/flask" },
            { text: "Spring", link: "/rules/backend/spring" },
            { text: "Laravel", link: "/rules/backend/laravel" },
            { text: "Rails", link: "/rules/backend/rails" },
            { text: "Gin", link: "/rules/backend/gin" },
            { text: "Echo", link: "/rules/backend/echo" },
            { text: "Fiber", link: "/rules/backend/fiber" },
            { text: "Chi", link: "/rules/backend/chi" },
            { text: "Beego", link: "/rules/backend/beego" },
            { text: "Go Zero", link: "/rules/backend/go-zero" },
            { text: "Kratos", link: "/rules/backend/kratos" },
            { text: "Actix Web", link: "/rules/backend/actix-web" },
            { text: "Axum", link: "/rules/backend/axum" },
          ],
        },
      ],
      "/rules/database/": [
        {
          text: "Databases",
          items: [
            { text: "MySQL", link: "/rules/database/mysql" },
            { text: "PostgreSQL", link: "/rules/database/postgresql" },
            { text: "MongoDB", link: "/rules/database/mongodb" },
            { text: "Redis", link: "/rules/database/redis" },
            { text: "Elasticsearch", link: "/rules/database/elasticsearch" },
            { text: "SQL", link: "/rules/database/sql" },
            { text: "GORM", link: "/rules/database/gorm" },
            { text: "Prisma", link: "/rules/database/prisma" },
            { text: "SQLAlchemy", link: "/rules/database/sqlalchemy" },
          ],
        },
      ],
      "/rules/infrastructure/": [
        {
          text: "Infrastructure",
          items: [
            { text: "Docker", link: "/rules/infrastructure/docker" },
            { text: "Kubernetes", link: "/rules/infrastructure/kubernetes" },
            { text: "Terraform", link: "/rules/infrastructure/terraform" },
            { text: "Ansible", link: "/rules/infrastructure/ansible" },
            { text: "Monitoring", link: "/rules/infrastructure/monitoring" },
            { text: "GitHub Actions", link: "/rules/infrastructure/github-actions" },
          ],
        },
      ],
      "/rules/specialized/": [
        {
          text: "Specialized",
          items: [
            { text: "API Design", link: "/rules/specialized/api-design" },
            { text: "GraphQL", link: "/rules/specialized/graphql" },
            { text: "gRPC", link: "/rules/specialized/grpc" },
            { text: "tRPC", link: "/rules/specialized/trpc" },
            { text: "Accessibility", link: "/rules/specialized/accessibility" },
            { text: "Data Engineering", link: "/rules/specialized/data-engineering" },
            { text: "LLM Prompting", link: "/rules/specialized/llm-prompt" },
            { text: "Markdown", link: "/rules/specialized/markdown" },
            { text: "YAML", link: "/rules/specialized/yaml" },
            { text: "Elixir", link: "/rules/specialized/elixir" },
          ],
        },
      ],
    },

    socialLinks: [
      {
        icon: "github",
        link: "https://github.com/snowdreamtech/template",
      },
    ],

    footer: {
      message: "Released under the MIT License.",
      copyright: "Copyright © 2026-present SnowdreamTech Inc.",
    },

    editLink: {
      pattern: "https://github.com/snowdreamtech/template/edit/main/docs/:path",
      text: "Edit this page on GitHub",
    },

    search: {
      provider: "local",
    },
  },
});
