# Recipes

Hardened Docker Compose templates for popular homelab applications. Each recipe
follows the same security baseline as the root
[`docker-compose.yml`](../docker-compose.yml) — with exceptions documented
inline where an application requires them.

---

## Available Recipes

| Recipe | What it runs | Key exceptions |
| ------ | ------------ | -------------- |
| [pihole.yml](pihole.yml) | Pi-hole DNS ad blocker | `NET_BIND_SERVICE`, `NET_RAW` (DNS + optional DHCP) |
| [nextcloud.yml](nextcloud.yml) | Nextcloud + MariaDB + Redis | `NET_BIND_SERVICE` (Apache), `SYS_NICE` (MariaDB), writable app dir |
| [traefik.yml](traefik.yml) | Traefik v3 reverse proxy with HTTPS | `NET_BIND_SERVICE`, Docker socket (read-only) |

---

## How to Use a Recipe

```bash
# 1. Create required secrets (check the recipe header for specifics)
mkdir -p secrets

# 2. Validate the compose file
docker compose -f recipes/<recipe>.yml config --quiet

# 3. Deploy
docker compose -f recipes/<recipe>.yml up -d

# 4. Check status
docker compose -f recipes/<recipe>.yml ps
```

Each recipe is self-contained with its own secrets, networks, and volumes.
Read the header comments in each file for setup instructions.

---

## Security Baseline

Every recipe applies these defaults (or documents why it can't):

- `cap_drop: ALL` — drop all Linux capabilities, add back only what's needed
- `no-new-privileges:true` — block privilege escalation
- `read_only: true` where possible — immutable root filesystem
- Resource limits — `mem_limit`, `cpus`, `pids_limit` on every service
- Log rotation — `max-size: 10m`, `max-file: 3`
- Healthchecks — on every service with an available endpoint
- Network isolation — separate networks per trust zone
- Docker secrets — for all passwords (never inline or in `.env`)

When a recipe breaks a default, the exception is documented with:

1. **Why** the exception is needed
2. **What compensates** for the relaxed control

See [BEST-PRACTICES.md §3.9](../docs/BEST-PRACTICES.md#39-documenting-security-exceptions)
for the exception documentation pattern.

---

[← Back to README](../README.md)
