# Full review — 2026-06-11/12

Full-repo review: technical accuracy vs the current Compose Spec (web-verified),
a cross-check against a private production stack, docs quality, and MCP server
code/security/packaging. Four review agents plus one fix pass.

> **Note:** this supersedes the partial `2026-06-11-review.md` from a run that hit
> its token limit. That file claimed several fixes as applied that never landed;
> they are all genuinely applied now (commits `1436a0c`..`9fdf114`).

**Verdict:** the guide's core claims hold up — no `version:` key anywhere, Compose
v2-only commands, correct secrets model, correct profiles guidance. The real
problems were at the edges: a wrong env-precedence list, pre-Engine-23 prune
semantics, two recipes that shipped broken, CVE/EOL image pins, and a security
chapter with no answer for privilege-dropping entrypoints. All fixed this pass.

## Fixed (committed and pushed)

**`1436a0c` — recipes:**

- Traefik healthcheck could never pass: `--ping=true` was missing from `command:`
- Pi-hole recipe used removed v5 env vars on a v6 image (`WEBPASSWORD_FILE` must hold the
  secret name, not a path; `PIHOLE_DNS_` → `FTLCONF_dns_upstreams`)
- Image bumps: redis 7.4.2→7.4.9 (CVE-2025-49844, CVSS 10.0), traefik v3.3.5→v3.6.2
  (EOL + CVE-2025-32431), nextcloud 30→32 (EOL), mariadb 11.7→11.8 LTS, pihole 2025.03→2026.05

**`d19adda` — doc accuracy:**

- Env-var precedence list corrected to the official order (shell beats `.env` for
  interpolation; `env_file:` and image `ENV` tiers were missing)
- `volume prune` removes only anonymous volumes since Engine 23 (`--all` for named)
- CIS numbers: CPU = 5.11 not 5.12, non-root = 4.1 not 5.21
- `prom/prometheus:v3` and `node-exporter:v1` now exist — claim reworded
- Watchtower marked archived (Dec 2025 — fails the guide's own T5 rule)
- `start_interval` added (Engine 25+); v1-secrets claim corrected

**`9c57181` — links and hygiene:** 5 dead external links fixed (Codex, 2× Copilot, Cosign ×2,
private `ai-tools` repo reworded); README tree completed; CHANGELOG caught up; back-link style
unified; `__pycache__/` gitignored; BEST-PRACTICES banner refreshed.

**`04e665c` — MCP docs:** `mcp>=1.2.0` floor (1.0.x lacks `fastmcp` — the old pin allowed a
broken install); VS Code registration rewritten from the deprecated `settings.json` block to
`mcp.json`; Python version note.

**`9fdf114` — hardening lessons:** new §3.2 gotcha + §3.9 exception row — `cap_drop: ALL` +
`no-new-privileges` break privilege-dropping entrypoints (gluetun OpenVPN, postgres), a
regression observed in production; §3.10 "hardening isn't done until every hardened service
starts"; §7.6 VPN-sidecar pattern (`network_mode: service:`); `deploy.resources` equivalent
syntax; `shm_size` for browser containers; TROUBLESHOOTING entry for post-hardening
`chown: operation not permitted`.

**`0c60127` — server.py P1-P3** (applied after sign-off): password patterns anchored to one
line (compliant `secrets:` blocks no longer flag — 4 of 6 repo compose files failed their own
linter); `list_scripts` skips `# ====` banners; containment check before existence check
(closes a host-path existence oracle), `is_file()` guard, uniform not-found messages.

## Deferred — server.py code proposals (not applied)

The server's architecture is sound: all 11 tools read repo files at runtime (no
content drift by construction) and path traversal is blocked (`resolve()` +
`is_relative_to`, tested live including absolute paths and symlinks). Proposals:

| # | Sev | Finding | Proposed fix |
|---|---|---|---|
| P1 | high | `check_compose_text` password regex matches across newlines, so the guide's own recommended `secrets:` block is flagged as an inline password — 4 of the repo's 6 compose files fail their own linter | Anchor to one line: `password:[ \t]*['\"]?\w{4,}` |
| P2 | med | `list_scripts` returns the `# ====` banner as every script's description | Skip comment lines with no letters |
| P3 | med | `exists()` runs before the containment check (file-existence oracle for host paths); `filename=""` raises unhandled `IsADirectoryError` | Reorder checks, add `is_file()`, return one uniform not-found message |
| P4 | low | Linter passes a file if any service complies; success message overclaims | Soften message now; per-service parsing later |
| P5 | low | `:latest` check misses untagged images (`image: nginx`) | Add multiline untagged alternative |

## Production cross-check (report-only)

The guide was cross-checked both ways against a private production stack
(17 services: databases, workflow engine, VPN-sidecar crawler pairs). The stack
follows the guide well — anchors, pins, healthchecks, limits, profiles, and
documented security exceptions all line up.

Lessons the guide adopted from that stack are in commit `9fdf114`. Findings that
ran the other way (stack deviations from the guide) are tracked in that
project's own private backlog, not here.

The most transferable lesson: official images often read only a fixed set of
env vars — tuning vars the image never documents are silent no-ops. Verify with
the running process (`SHOW shared_buffers;` and similar), not the compose file.

## Backlog

Closed during the review window: server.py P1-P3 plus the untagged-image check
and a softened linter success message; MCP client registrations re-synced; CI
smoke test for the MCP server; INDEX.md quickstart/MCP entries; GITHUB-METADATA
publication note. Released as v1.1.0.

Deferred to the next session on this repo:

1. Sentence-case heading pass on REVERSE-PROXY, SECRETS-MANAGEMENT, STYLE, INDEX,
   recipes/README — needs coordinated anchor updates across linking docs, do as
   one change.
2. Linter depth: per-service parsing (one compliant service currently satisfies
   a check for the whole file) and the 3 unchecked CLAUDE.md standards
   (container_name avoidance, read_only+tmpfs, secrets-not-in-.env).

## Honest assessment

The guide is trustworthy on Compose fundamentals and its scope statement
(Engine 24+, Compose v2) is honest. Before this pass it had one factual error an
agent could act on (env precedence), two recipes that did not work as shipped,
and security-stale pins — a reminder that pinned examples rot and need a
scheduled currency pass. The security chapter now covers its former blind spot
(privilege-dropping entrypoints), learned from production rather than theory.

[← Back to README](../../README.md)
