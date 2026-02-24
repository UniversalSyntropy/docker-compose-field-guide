# Quickstart stack

A working demo of the Docker Compose Field Guide's best practices.
Runs a dashboard and a monitoring tool — up and usable in under 60 seconds.

| Service | What it does | URL |
|---------|-------------|-----|
| Homepage | Dashboard with Docker auto-discovery | `http://localhost:3000` |
| Uptime Kuma | Service health monitoring + status page | `http://localhost:3001` |

---

## Start the stack

```bash
cp .env.example .env
docker compose up -d
```

## Verify

```bash
docker compose ps
```

Both services should show "healthy" within 60 seconds.

---

## First-run setup

Homepage works immediately — your dashboard is at <http://localhost:3000>.

Uptime Kuma needs a one-time setup:

1. Open <http://localhost:3001>
2. Create an admin account (prompted automatically)
3. Add a monitor: type **HTTP(s)**, URL `http://homepage:3000`, name "Homepage"
4. Go to **Status Pages**, create a page with slug `default`
5. Add the Homepage monitor to the status page and save

The Homepage dashboard will then show live Uptime Kuma status data.

---

## What this demonstrates

| Practice | How it's used |
|----------|---------------|
| YAML anchors | `x-logging` and `x-security` blocks reused across services |
| Security hardening | `cap_drop: ALL`, `no-new-privileges`, `read_only` (Homepage) |
| Healthchecks | Both services report health to Docker |
| Resource limits | `mem_limit`, `cpus`, `pids_limit` on every service |
| Log rotation | `max-size: 10m`, `max-file: 3` on every service |
| Network isolation | Dedicated bridge network |
| Docker labels | Homepage auto-discovers services via labels |
| Pinned versions | No `:latest` tags |

---

## Customise

- Edit `config/homepage/settings.yaml` to change the dashboard theme
- Edit `config/homepage/bookmarks.yaml` to add your own links
- Add labels to any container to make it appear on the dashboard

## Teardown

```bash
docker compose down              # Stop (data preserved)
docker compose down -v           # Stop and delete all data
```

---

## Next steps

- [Best Practices](../docs/BEST-PRACTICES.md) — 21 sections of Docker Compose guidance
- [Recipes](../recipes/) — hardened templates for Pi-hole, Nextcloud, Traefik
- [Monitoring](../monitoring/) — Prometheus + Grafana stack
- [Main template](../docker-compose.yml) — annotated reference with secrets, databases

---

[Back to README](../README.md)
