# Changelog

## [Unreleased]

### Added

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

### Changed

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
