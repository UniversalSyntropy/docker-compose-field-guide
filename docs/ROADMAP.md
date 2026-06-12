# Roadmap — v1.2

v1.1.0 made the guide accurate. v1.2 makes it **verifiable**: deep enough validation that an
LLM (or a person) can generate a stack from the guide and have wrong output detected
mechanically, and a much larger recipe catalogue — built with the guide, then boot-tested.

Definition of done for everything below: it runs in CI, not just on one machine.

## Workstream 1 — verification depth

| # | Item | Effort | Why |
|---|---|---|---|
| 1 | Per-service linter: parse the YAML and check each service against the standards | small | Today one compliant service satisfies a check for the whole file |
| 2 | Live recipe boots in CI: `up -d --wait` with generated throwaway secrets, assert healthy | small | Config-only validation shipped two broken recipes; a boot test catches what regex can't |
| 3 | `validate_compose` MCP tool: `docker compose config` + per-service lint in one call | medium | Exposes the verify loop to agents at generation time |
| 4 | Scheduled pin-currency check: image tags vs registry, EOL, known CVEs | medium | Pins rot — v1.1.0 fixed a CVSS 10.0 pin that sat for months |

## Workstream 2 — blocks catalogue

Recipes are whole files to imitate; imitation is where LLM drift happens. This workstream
extracts hardened, composable fragments with known-good anchors that get assembled instead:

- **Service blocks** — postgres, mariadb, valkey/redis, generic web app, browser/worker
  (with `shm_size`), each with its capability exceptions documented inline
- **Pattern blocks** — VPN sidecar pair (§7.6), reverse-proxy attachment, healthcheck +
  `depends_on` chain, log rotation and security anchors (`x-logging`, `x-security`)
- **Assembly rules** — which blocks combine, which networks they join, what each block
  needs from `.env`

Every block carries the same definition of done as a recipe: boots healthy in CI.

## Workstream 3 — recipe expansion

The aim: take the most commonly deployed self-hosted stacks, build each one *with* the guide,
boot-test it, document every exception inline, and merge it into `recipes/` plus the CI boot
matrix. Each wave deliberately exercises different guide patterns, so expanding the catalogue
also tests the guide itself.

Candidates are drawn from community popularity (selfh.st surveys, awesome-selfhosted) — verify
demand and image pins at build time, per the README currency note.

### The loop for each stack

1. Assemble from the template and blocks (not from upstream's sample compose)
2. `docker compose config --quiet`, then lint
3. `up -d --wait` with test secrets — every service must reach healthy
4. Document each security exception inline (§3.9) — a recipe is not done while an
   undocumented exception exists
5. **Roll the learnings back into the guide** — every gotcha, broken assumption, or failed
   hardening from the test run becomes a Best Practices addition or TROUBLESHOOTING entry
   before the recipe merges. The §3.2 privilege-dropping gotcha and §7.6 VPN-sidecar section
   both came from exactly this loop; the test runs are how the guide earns its claims
6. Add to `recipes/` and the CI boot matrix; pin and verify every image tag

A recipe that boots first try still produces output for step 5 — at minimum, confirmation of
which guide defaults the upstream image tolerates. A recipe that fights back produces more.

### Wave 1 — high demand, distinct patterns

| Stack | Use | Compose shape | Guide patterns exercised |
|---|---|---|---|
| Jellyfin | Media server | Single service + media mounts | Device passthrough (transcode), `:ro` media volumes |
| *arr suite (Prowlarr, Sonarr, Radarr, qBittorrent + gluetun) | Media automation | 5+ services, VPN-routed downloader | §7.6 VPN sidecar, shared volumes, profiles |
| Vaultwarden | Password manager | Single service + SQLite or postgres | Secrets handling, reverse-proxy TLS requirement, backup notes |
| Paperless-ngx | Document management and OCR | App + redis + postgres + worker | Privilege-dropping entrypoint (§3.2), `depends_on` chains |
| AdGuard Home | DNS filtering | Single service | Port 53 binding conflicts, host DNS gotchas |
| Dozzle | Container log viewer | Single service | Docker socket `:ro` caveat (§3.5) — the canonical exception case |
| Home Assistant | Home automation hub | Single service (often + MQTT) | Host networking trade-off, USB device passthrough (§15/§16) |
| Forgejo | Git hosting | App + postgres | SSH port mapping, data-volume layout |

### Wave 2 — popular, heavier or more specialised

| Stack | Use | Compose shape | Guide patterns exercised |
|---|---|---|---|
| Immich | Photo backup and search | App + ML + postgres + redis | Multi-service resource limits, `deploy.resources` reservations |
| wg-easy | WireGuard VPN server | Single service | `NET_ADMIN`/sysctls — targeted `cap_add` done right |
| n8n | Workflow automation | App + postgres (+ task runner) | Healthcheck chains, env-fed config, worker pattern |
| Mosquitto + Zigbee2MQTT | MQTT broker + Zigbee bridge | 2 services | USB passthrough, `read_only` broker, config mounts |
| Portainer CE | Container management UI | Single service | Docker socket access — full §3.5 treatment |
| Syncthing | File sync | Single service | Port strategy (LAN discovery), UID/GID volume ownership |
| MinIO | S3-compatible object storage | Single service | Secrets, console vs API ports |
| BookStack | Wiki | App + mariadb | `APP_KEY` secret, mariadb block reuse |

### Wave 3 — catalogue fill-out

| Stack | Use | Notes |
|---|---|---|
| Ollama + Open WebUI | Local LLM serving | GPU passthrough — needs its own guide section first |
| Navidrome | Music streaming | Easy `read_only` showcase |
| Audiobookshelf | Audiobooks and podcasts | Simple, popular |
| Stirling-PDF | PDF toolbox | Single service |
| FreshRSS | RSS reader | Single service + db block |
| Linkding | Bookmarks | Minimal — good smallest-recipe example |
| Mealie | Recipe manager | App + db |
| Beszel | Lightweight server monitoring | Hub + agent pattern |
| Nginx Proxy Manager | Reverse proxy with UI | Alternative to the Traefik recipe — compare honestly |
| Grafana Loki | Log aggregation | Extends the existing monitoring stack |

## Sequencing

Workstream 1 items 1-2 come first — they are small, and every recipe added afterwards inherits
the verification. Then wave 1 recipes and the blocks catalogue grow together (each recipe built
from blocks hardens the blocks). The MCP `validate_compose` tool and pin-currency automation
land once there is a catalogue worth pointing them at.

## Success criteria for v1.2

- Every recipe and block boots to healthy in CI — zero config-only validation
- The linter reports per service, not per document
- An agent can generate, validate, and fix a stack using only this repo's MCP tools
- The catalogue covers at least the wave 1 stacks

[← Back to README](../README.md)
