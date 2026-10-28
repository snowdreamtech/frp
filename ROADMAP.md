# Roadmap

This document outlines the planned improvements and future direction of the **Snowdream Tech AI IDE Template**.

> Items are subject to change based on community feedback and ecosystem evolution. To suggest additions, open a [Discussion](https://github.com/snowdreamtech/template/discussions).

## ✅ Completed

- [x] Core AI rule system (`.agent/rules/`) as Single Source of Truth
- [x] SpecKit workflow suite (specify → plan → tasks → implement)
- [x] 50+ AI IDE configuration directories
- [x] DevContainer with Docker Compose
- [x] Comprehensive CI/CD (lint, security, CodeQL, stale, GoReleaser)
- [x] Pre-commit hooks with 50+ quality gates
- [x] GitHub community health files
- [x] VS Code productivity suite (tasks + launch configs)
- [x] Project hydration script (`scripts/init-project.sh`)
- [x] Atomic commit discipline in AI agent guidelines

## 🔄 In Progress

- [ ] Automated rule synchronization across all AI IDE directories
- [ ] Expanded language-specific rules (`.agent/rules/*.md` per language/framework)

## 📅 Planned

### Short-term

- [ ] **MCP (Model Context Protocol) integration** — standardized tool definitions for AI agents
- [ ] **Semantic Release** — fully automated versioning and CHANGELOG generation on merge to main
- [ ] **Multi-language bootstrap** — detect project language and auto-configure relevant linters

### Mid-term

- [ ] **Repository health dashboard** — aggregated badge report for all quality signals
- [ ] **AI-assisted PR review** — automated code review workflow using agent capabilities
- [ ] **Template versioning** — track which template version a downstream project was cloned from

### Long-term

- [ ] **Plugin registry** — extensible SpecKit workflow marketplace
- [ ] **Cross-repo rule sync** — GitHub App to propagate rule updates to downstream repositories

## 💬 Suggest a Feature

Open a [Feature Request](https://github.com/snowdreamtech/template/issues/new?template=feature_request.yml) or start a [Discussion](https://github.com/snowdreamtech/template/discussions/new?category=general).
