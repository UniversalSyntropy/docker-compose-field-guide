# Docker Compose Field Guide — Agent Instructions

This repo is a comprehensive Docker Compose reference. Follow these standards when working on Docker Compose tasks.

## Setup Commands

```bash
# Validate compose file
docker compose config --quiet

# Deploy
docker compose up -d --wait

# Check status
docker compose ps

# Check logs
docker compose logs --tail=50 <service>
```

## Compose Standards

- Pin images to exact version tags — never `:latest`
- No `version:` key (deprecated in Compose v2)
- Avoid `container_name` unless tooling requires it
- Set `mem_limit`, `cpus`, `pids_limit` on every service
- Set `restart: unless-stopped` on every service
- Configure log rotation: `max-size: "10m"`, `max-file: "3"`
- Add healthchecks on all services with endpoints
- Use Docker secrets for passwords — never inline or in `.env`
- Apply security defaults: `cap_drop: [ALL]`, `no-new-privileges:true`
- Use `read_only: true` + `tmpfs` where possible
- Only publish ports that need external access

## Workflow

1. Plan first, YAML second
2. Validate before running: `docker compose config --quiet`
3. Patch minimally during debugging — don't rewrite working services
4. Test after every change: `docker compose ps`

## Safety — Commands That Need Confirmation

These commands are destructive. Always warn and explain before running:

- `docker compose down -v` — deletes all project volumes (data loss)
- `docker system prune` — removes unused containers, networks, images
- `docker system prune -a --volumes` — removes everything not attached to running containers
- `docker volume prune` — removes volumes not attached to any container
- `--force-recreate` — restarts all containers even if config hasn't changed

## Troubleshooting Loop

When something fails, follow this order:

1. **Validate** — `docker compose config`
2. **Inspect** — `docker compose ps`, check exit codes
3. **Logs** — `docker compose logs <service>`
4. **Minimal patch** — fix the specific issue
5. **Revalidate** — confirm fix, check nothing else broke

Full debugging playbook: [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)

## Scaling Rules

- Only scale stateless services
- Remove `container_name` from anything that might scale
- Compose is manual `--scale`, not autoscaling

## File Map

| What you need | Where to look |
|---------------|---------------|
| Compose best practices | [DOCKER-COMPOSE-BEST-PRACTICES.md](docs/BEST-PRACTICES.md) |
| Troubleshooting & debugging | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| Docker basics | [DOCKER-BASICS.md](docs/DOCKER-BASICS.md) |
| Term definitions | [GLOSSARY.md](docs/GLOSSARY.md) |
| Topic finder | [INDEX.md](docs/INDEX.md) |
| Annotated template | [docker-compose.yml](docker-compose.yml) |
| Monitoring stack | [monitoring/](monitoring/) |
| Helper scripts | [scripts/](scripts/) |
