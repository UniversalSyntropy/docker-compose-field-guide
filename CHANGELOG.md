# Changelog

## [Unreleased]

### Added

- v1.2 roadmap (`docs/ROADMAP.md`): verification depth (per-service linter, CI boot tests,
  `validate_compose` tool, pin-currency checks), a hardened blocks catalogue, and a
  three-wave recipe expansion across ~26 popular self-hosted stacks — each built with the
  guide, boot-tested, and its learnings rolled back into the guide

## [1.1.0] - 2026-06-12

### Added

- **GitHub metadata:** repo description, topics, and publication guide (`GITHUB-METADATA.md`)
- **Vault gitignore rules** and cross-system MCP instructions in `CLAUDE.md`
- **MCP server:** Model Context Protocol server exposing 11 tools for AI coding agents — compose standards, best practices, troubleshooting, annotated template, guides, recipes, scripts, and a compose linter (`mcp-server/`). Works with Claude Code, VS Code, Cursor, and any MCP-compatible client
- **Quickstart stack:** Homepage dashboard + Uptime Kuma monitoring — a working two-service demo that follows all field guide patterns (`quickstart/`)
- **Recipes:** Hardened compose templates for Pi-hole, Nextcloud (+MariaDB +Redis), and Traefik v3 reverse proxy with automatic HTTPS (`recipes/`)
- **Reverse proxy guide:** Architecture overview, Traefik quick start, certificate methods (HTTP challenge, DNS challenge, local CA), multi-stack networking (`docs/REVERSE-PROXY.md`)
- **Advanced secrets management guide:** SOPS + age, Doppler, git-crypt walkthrough with comparison table (`docs/SECRETS-MANAGEMENT.md`)
- **Dependabot:** Weekly checks for Docker image and GitHub Actions updates (`.github/dependabot.yml`)
- **Mermaid architecture diagram** in README showing User → Proxy → Networks → Containers → Volumes/Secrets flow
- **Live stack test** CI job — starts the root compose stack, verifies containers are running, tears down
- Recipe validation in CI and Makefile `compose-check`
- Pi-hole and Nextcloud commented scrape targets in Prometheus config
- `DOMAIN` and `ACME_EMAIL` variables in `.env.example` for Traefik recipe
- CONTRIBUTING.md — contributor guide with local validation instructions
- SECURITY.md — security policy for a documentation repository
- CHANGELOG.md
- Issue templates (bug report, feature request)
- Pull request template
- CI smoke test: imports the MCP server and runs the linter over all repo compose files
- INDEX.md entries for the quickstart stack and MCP server

### Fixed

- MCP server linter: untagged images (implicit `:latest`) are now flagged
- MCP server linter: success message no longer overclaims — notes that checks are
  document-wide heuristics

### Changed

- README: stated the dual human/agent purpose, added a currency note (pins and links rot —
  check the changelog date), listed the quickstart stack and MCP server under what's included
- Accuracy + link fixes from the 2026-06 full review: env precedence, prune behaviour,
  CIS control numbers, Pi-hole v6 env vars, Traefik ping healthcheck, CVE/EOL image bumps
- MCP server linter fixes from the same review: password patterns anchored to one line
  (compliant `secrets:` blocks no longer flag as inline passwords), real script descriptions
  in `list_scripts`, hardened path validation in the `get_*` tools
- Applied house style: sentence case headings across all 17 markdown files
- Replaced `&` with `and` in headings and updated all cross-file anchor links
- README: added separate "What this is not" section, quick start verification step,
  removed tagline blockquote
- Fixed all markdownlint violations (MD028, MD031, MD032, MD036, MD040, MD022, MD058)
- Converted emphasis-as-heading patterns to `####` headings (backup tiers, LLM prompts)
- Added language identifiers to all unlabeled code blocks
- Added `## Terms` heading to GLOSSARY.md for proper heading hierarchy
- Disabled MD060 (table column style) in markdownlint config
- Fixed incorrect display name in CLAUDE.md key documentation table

### Previously changed

- Wrapped 15 lines exceeding 300 characters across 4 markdown files (no content changes)
- Tightened CI line-length check from 500 to 300 characters
- Tightened yamllint from `relaxed` preset to targeted config
  (enables structural checks, disables noisy `truthy` and `document-start` rules)
- Expanded CI line-length check to cover `.json`, `.jsonc`, and `.env` files
- Added before/after hardening example to README (nginx)
- Added Trust & Limits section to README
- Added value proposition hook to README
- Updated Contributing section in README to reference CONTRIBUTING.md
- Added `strong` to allowed HTML elements in markdownlint config
