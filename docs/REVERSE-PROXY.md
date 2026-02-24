# Reverse Proxy & HTTPS

How to put a hardened reverse proxy in front of your Docker services and
terminate TLS with automatic certificate management.

> **Scope:** This guide covers Traefik v3 with Let's Encrypt. The same
> principles apply to Caddy, Nginx Proxy Manager, or any other reverse proxy —
> the differences are in configuration syntax, not architecture.

---

## Why You Need a Reverse Proxy

If you expose any service beyond your LAN, a reverse proxy gives you:

- **TLS termination** — HTTPS between clients and the proxy, plain HTTP
  internally (where your Docker network is trusted)
- **Single entry point** — one place to manage certificates, rate limiting,
  access control, and logging
- **Port consolidation** — all services share ports 80/443 instead of
  publishing random high ports
- **Hostname routing** — `nextcloud.example.com` and `grafana.example.com`
  both resolve to the same IP; the proxy routes by `Host` header

Without a reverse proxy, every service publishes its own port, handles its own
TLS (or doesn't), and you have no central point to enforce security policy.

---

## Architecture

```text
Internet / LAN
       │
       ▼
┌──────────────┐
│   Traefik    │  ports 80/443
│  (proxy net) │  TLS termination, routing
└──────┬───────┘
       │  Docker "proxy" network
       ├──────────────────┐
       ▼                  ▼
┌─────────────┐   ┌─────────────┐
│  Nextcloud  │   │   Grafana   │
│ (app + back)│   │ (monitoring)│
└─────────────┘   └─────────────┘
```

- Traefik sits on a shared `proxy` network with a fixed name.
- Each application stack joins the `proxy` network for its public-facing
  service, while keeping its internal services (databases, caches) on
  separate backend networks.
- Traefik discovers services automatically via Docker labels — no manual
  config file editing when you add or remove a service.

---

## Quick Start with Traefik

The recipe at [`recipes/traefik.yml`](../recipes/traefik.yml) is a
ready-to-deploy hardened Traefik setup. Here's the short version:

### 1. Prepare the certificate store

```bash
mkdir -p /mnt/data/traefik
touch /mnt/data/traefik/acme.json
chmod 600 /mnt/data/traefik/acme.json
```

Let's Encrypt stores certificates in `acme.json`. The file must exist and
have `600` permissions, or Traefik refuses to start.

### 2. Set your domain and email

```bash
export DOMAIN=example.com
export ACME_EMAIL=admin@example.com
```

Or add these to your `.env` file.

### 3. Deploy Traefik

```bash
docker compose -f recipes/traefik.yml up -d
```

### 4. Route a service through Traefik

Add these labels to any service in any compose stack:

```yaml
services:
  myapp:
    image: myapp:1.0.0
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.myapp.rule=Host(`myapp.example.com`)"
      - "traefik.http.routers.myapp.entrypoints=websecure"
      - "traefik.http.routers.myapp.tls.certresolver=letsencrypt"
      - "traefik.http.services.myapp.loadbalancer.server.port=8080"
    networks:
      - proxy

networks:
  proxy:
    external: true                       # Join the network Traefik created
```

The key points:

- `traefik.enable=true` — opt-in (Traefik ignores unlabelled containers)
- `Host(...)` — the domain this service responds to
- `entrypoints=websecure` — HTTPS only (HTTP is auto-redirected)
- `certresolver=letsencrypt` — Traefik handles the certificate
- `loadbalancer.server.port` — the port your app listens on *inside*
  the container

---

## Certificate Methods

### HTTP Challenge (default)

The simplest method. Traefik proves domain ownership by responding to a
challenge on port 80. Requires:

- Port 80 forwarded from your router to the Docker host
- The domain's A/AAAA record pointing to your public IP

This is what `recipes/traefik.yml` uses out of the box.

### DNS Challenge

Proves ownership by creating a DNS TXT record. Useful when:

- You can't open port 80 (ISP blocks it, or you're behind CGNAT)
- You want wildcard certificates (`*.example.com`)

Replace the HTTP challenge config in `traefik.yml`:

```yaml
command:
  # Remove the httpchallenge line and add:
  - '--certificatesresolvers.letsencrypt.acme.dnschallenge=true'
  - '--certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare'
environment:
  # Cloudflare API token with DNS edit permissions
  - CF_DNS_API_TOKEN_FILE=/run/secrets/cloudflare_token
```

Traefik supports
[dozens of DNS providers](https://doc.traefik.io/traefik/https/acme/#providers).
Check the docs for your provider's required environment variables.

### Local CA (no public domain)

If your services are LAN-only and you don't have a public domain, you can
use a local certificate authority instead of Let's Encrypt:

1. Generate a root CA with `mkcert` or `step-ca`
2. Install the root CA on your devices
3. Mount the certificates directly into Traefik as file-based TLS

This avoids the need for DNS challenges or port forwarding entirely.

---

## Security Hardening

The `recipes/traefik.yml` file applies these controls:

| Control | How |
| ------- | --- |
| `cap_drop: ALL` + `cap_add: NET_BIND_SERVICE` | Minimum capabilities for port 80/443 |
| `no-new-privileges:true` | Block privilege escalation |
| `read_only: true` + `tmpfs` | Immutable filesystem |
| Docker socket `:ro` | Traefik reads labels, never modifies containers |
| `exposedbydefault=false` | Services must explicitly opt in with labels |
| HTTP → HTTPS redirect | No accidental plaintext traffic |
| `api.insecure=false` | Dashboard only accessible via authenticated route |

> **Gotcha:** The Docker socket gives root-equivalent host access even when
> mounted read-only. For stronger isolation, place a
> [Docker socket proxy](https://github.com/Tecnativa/docker-socket-proxy)
> between Traefik and the real socket. See
> [BEST-PRACTICES.md §3.5](BEST-PRACTICES.md#35-docker-socket-safety).

---

## Connecting Multi-Stack Services

When Traefik and your application are in **different** compose files, the
proxy network must be created once and shared:

```yaml
# In traefik.yml — creates the network
networks:
  proxy:
    name: proxy
    driver: bridge

# In your app's compose file — joins the existing network
networks:
  proxy:
    external: true
```

The `name: proxy` in Traefik's file gives the network a fixed name
(instead of the default `<project>_proxy`), so other stacks can
reference it by name with `external: true`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
| ------- | ------------ | --- |
| `acme.json` permission error | File doesn't exist or wrong mode | `touch acme.json && chmod 600 acme.json` |
| Certificate not issued | Port 80 not reachable, or DNS not pointing to host | Check firewall and DNS A record |
| 404 on service URL | Service not on the `proxy` network, or labels wrong | Check `docker network inspect proxy` for the container |
| 502 Bad Gateway | Service is down or wrong `loadbalancer.server.port` | Check service logs and verify the internal port |
| Dashboard not accessible | `api.insecure=false` and no route label | Add the dashboard routing labels (see recipe) |

---

[← Back to README](../README.md)
