# Docker Compose Field Guide — project instructions

This repo is a comprehensive Docker Compose reference. When working on Docker Compose tasks in this repo or in projects that reference it, follow these standards.

## Scope

- **Target:** Docker Engine 24+ with Docker Compose v2 (`docker compose` plugin)
- **Environment:** Self-hosted homelab / small-team — LAN-facing, not internet-exposed
- **This repo contains:** best practices, templates, troubleshooting, monitoring, helper scripts

## Compose standards

Follow these for every compose file:

- No `version:` key (deprecated in Compose v2)
- Pin images to exact version tags — never `:latest`
- Avoid `container_name` unless tooling requires a stable name
- Set `mem_limit`, `cpus`, and `pids_limit` on every service
- Set `restart: unless-stopped` on every service
- Configure log rotation on every service (`max-size: "10m"`, `max-file: "3"`)
- Add healthchecks on all services with HTTP or CLI endpoints
- Use named volumes or bind mounts for all persistent data
- Use Docker secrets for passwords — never inline or in `.env`
- Apply security defaults: `cap_drop: [ALL]`, `no-new-privileges:true`
- Use `read_only: true` + `tmpfs` where possible
- Prefer internal-only ports — only publish what needs external access

## Workflow

1. **Plan first, YAML second** — understand what's needed before writing
2. **Validate before running** — `docker compose config --quiet`
3. **Patch minimally during debugging** — fix the specific issue, don't rewrite working services
4. **Test after every change** — `docker compose up -d && docker compose ps`

## Safety rules

- **Warn before `down -v`** — this deletes all project volumes (data loss)
- **Warn before any `prune` command** — explain what will be removed
- **Warn before `--force-recreate`** — explain what will be restarted
- **Never force-push without confirmation**
- **Back up before destructive operations**
- Include rollback notes for risky changes

## Validation commands

```bash
docker compose config --quiet          # Syntax check
docker compose up -d --wait            # Deploy and wait for healthy
docker compose ps                      # Status check
docker compose logs --tail=50 <svc>    # Log check
docker stats --no-stream               # Resource usage
```

## Troubleshooting loop

When something fails, follow this order:

1. `docker compose config` — is the YAML valid?
2. `docker compose ps` — what's the container status?
3. `docker compose logs <service>` — what does the service say?
4. `docker inspect <container>` — exit code, OOM, health state?
5. Apply a minimal fix — change only what's broken
6. Revalidate — confirm the fix, check nothing else broke

See [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) for the full debugging playbook.

## Key documentation

| Topic | File |
|-------|------|
| Best practices (21 sections) | [Best practices](docs/BEST-PRACTICES.md) |
| Troubleshooting & debugging | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| Docker basics & installation | [DOCKER-BASICS.md](docs/DOCKER-BASICS.md) |
| Reverse proxy & HTTPS | [REVERSE-PROXY.md](docs/REVERSE-PROXY.md) |
| Advanced secrets management | [SECRETS-MANAGEMENT.md](docs/SECRETS-MANAGEMENT.md) |
| Term definitions | [GLOSSARY.md](docs/GLOSSARY.md) |
| Topic finder | [INDEX.md](docs/INDEX.md) |
| Annotated template | [docker-compose.yml](docker-compose.yml) |
| Hardened recipes | [recipes/](recipes/) |
| Monitoring stack | [monitoring/](monitoring/) |
| Helper scripts | [scripts/](scripts/) |
