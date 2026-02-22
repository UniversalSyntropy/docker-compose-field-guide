# Docker Compose Best Practices

A structured reference covering every element of a Docker Compose stack — security, storage, networking, resource limits, backups, monitoring, and cross-platform setup. Designed as a reusable foundation you can adapt to any project.

**Last Updated:** February 2026

> **Compatibility:** This document targets **Docker Engine 24+** with the **Docker Compose v2** plugin (`docker compose`). Some runtime keys (`mem_limit`, `cpus`, `pids_limit`) are Docker-specific and may behave differently in Podman Compose or Docker Swarm. The legacy Python-based `docker-compose` (v1) is deprecated and not covered.

> **Threat model:** This guide assumes a **self-hosted homelab or small-team environment** — services are LAN-facing, not directly exposed to the internet. For internet-facing production, add a reverse proxy with TLS, WAF, rate limiting, and stricter network policies. The security hardening here is a strong baseline, not a substitute for a full security architecture.

> **New to Docker?** Start with [DOCKER-BASICS.md](DOCKER-BASICS.md) for an introduction to Docker, Compose, and alternative container runtimes. See the [glossary](GLOSSARY.md) for quick definitions of any term, or the [index](INDEX.md) to find where a topic is covered.

---

## Table of Contents

1. [Compose File Structure](#1-compose-file-structure)
2. [Image Management](#2-image-management)
3. [Security Hardening](#3-security-hardening)
4. [Storage & Volumes](#4-storage--volumes)
5. [Host Filesystem Setup](#5-host-filesystem-setup)
6. [Environment & Configuration](#6-environment--configuration)
7. [Networking](#7-networking)
8. [Resource Limits](#8-resource-limits)
9. [Healthchecks & Dependencies](#9-healthchecks--dependencies)
10. [Logging](#10-logging)
11. [Graceful Shutdown](#11-graceful-shutdown)
12. [Update Management](#12-update-management)
13. [Backup & Disaster Recovery](#13-backup--disaster-recovery)
14. [Monitoring](#14-monitoring)
15. [Cross-Platform Compatibility](#15-cross-platform-compatibility)
16. [USB & Hardware Devices](#16-usb--hardware-devices)
17. [Penetration Testing Readiness](#17-penetration-testing-readiness)
18. [Container Source Verification & Supply Chain Security](#18-container-source-verification--supply-chain-security)
19. [LLM-Assisted Stack Design Workflow](#19-llm-assisted-stack-design-workflow)
20. [Checklist for New Services](#20-checklist-for-new-services)
21. [References](#21-references)

---

## 1. Compose File Structure

> **In a nutshell:** Put reusable config in extension fields (`x-`), define services, secrets, networks, and volumes in that order. Use YAML anchors to avoid repetition. Use profiles for optional services.

### 1.1 File Organisation

```yaml
# Extension fields (reusable blocks) — must start with x-
x-logging: &default-logging
  ...
x-security: &default-security
  ...

# Services — the containers
services:
  app:
    ...

# Secrets — file-based password injection
secrets:
  db_password:
    file: ./secrets/db_password.txt

# Networks — isolated communication channels
networks:
  frontend:
    driver: bridge

# Volumes — named volumes (if not using bind mounts)
volumes:
  db-data:
    driver: local
```

### 1.2 YAML Anchors & Extension Fields

Define shared config once, reference everywhere:

```yaml
x-logging: &default-logging
  driver: json-file
  options:
    max-size: "10m"
    max-file: "3"

x-security: &default-security
  security_opt:
    - no-new-privileges:true
  cap_drop:
    - ALL

services:
  app:
    <<: *default-security        # Merge security block
    logging: *default-logging    # Reference logging block
```

> **Gotcha:** `<<:` performs a **shallow merge**. If a service defines its own `security_opt`, it completely replaces the anchor — lists don't merge. In those cases, spell out the full block inline.

### 1.3 Profiles

Use profiles to define optional services that aren't started by default:

```yaml
services:
  app:
    image: your-app:1.0.0           # Always started (no profile)

  debug-tools:
    image: nicolaka/netshoot:latest
    profiles: ["debug"]             # Only started with --profile debug

  monitoring:
    image: prom/prometheus:v3.9.1
    profiles: ["monitoring"]        # Only started with --profile monitoring
```

```bash
docker compose up -d                           # Starts only unprofiled services
docker compose --profile monitoring up -d      # Starts app + monitoring
docker compose --profile debug up -d           # Starts app + debug tools
```

Useful for: development tools, monitoring stacks, one-off maintenance containers, and services needed only in specific environments.

### 1.4 Compose Version

Docker Compose v2 (the Go-based `docker compose` plugin) does **not** require a `version:` key in the compose file. If present, it's ignored. The legacy `docker-compose` (Python, v1) is deprecated and should not be used.

Verify your version:
```bash
docker compose version    # Should show v2.x.x
```

---

## 2. Image Management

> **In a nutshell:** Always pin images to exact version tags. Never use `:latest`. Verify tags actually exist on Docker Hub before committing — not all versions have matching tags.

### 2.1 Image Pinning

| Tag Style | Example | Use When |
|-----------|---------|----------|
| Exact version | `postgres:16.6` | **Default for all services** |
| Major version | `eclipse-mosquitto:2` | Only if the registry publishes a rolling major tag |
| **Never** | `:latest` | Never in production — unpredictable, unauditable |

> **Gotcha:** Not all images publish major-only tags. For example, `grafana/grafana:12`, `prom/prometheus:v3`, and `prom/node-exporter:v1` do **not** exist. Always verify with `docker pull <image>:<tag>` before committing.

> **Gotcha (tag mismatch):** A container's internal version may not match any Docker Hub tag. For example, `eclipse-mosquitto:2` pulls an image that reports version `2.1.2` internally, but Docker Hub only publishes `eclipse-mosquitto:2.1.2-alpine` — there is no `eclipse-mosquitto:2.1.2` tag. Always check the registry (Docker Hub tags page or `docker manifest inspect`) rather than trusting `docker inspect` labels or in-container version commands.

### 2.2 Multi-Architecture Images

Most official images publish multi-arch manifests (`linux/amd64`, `linux/arm64`, `linux/arm/v7`). Docker automatically pulls the correct architecture for your host.

Verify an image supports your platform:
```bash
docker manifest inspect <image>:<tag> | grep architecture
```

### 2.3 Image Provenance

- Prefer official images from Docker Hub or verified publishers
- For GitHub Container Registry images, verify the source repository
- Consider enabling [Docker Content Trust](https://docs.docker.com/engine/security/trust/) for image signature verification:
  ```bash
  export DOCKER_CONTENT_TRUST=1
  ```

---

## 3. Security Hardening

> **In a nutshell:** Drop all Linux capabilities, block privilege escalation, run as non-root, make the filesystem read-only, and use Docker secrets for passwords. If a service can't follow these rules, document why and what compensates.

### 3.1 Mandatory Defaults

Every service MUST have these unless a documented exception exists:

```yaml
x-security: &default-security
  security_opt:
    - no-new-privileges:true     # CIS 5.25 — block setuid privilege escalation
  cap_drop:
    - ALL                        # CIS 5.3  — drop all Linux capabilities
```

### 3.2 Capability Management

After dropping all capabilities, add back **only** what the service requires:

| Capability | When Needed | Example Service |
|-----------|-------------|-----------------|
| `NET_BIND_SERVICE` | Binding to ports < 1024 | Nginx, Apache |
| `NET_ADMIN` | Network configuration, mDNS | Home automation hubs |
| `NET_RAW` | Raw sockets, ping, DHCP | Network tools, IoT hubs |
| `SETGID`, `SETUID` | Entrypoints that drop privileges | Mosquitto, MariaDB, Redis |
| `CHOWN`, `DAC_OVERRIDE` | Entrypoints that chown data dirs | Mosquitto, Postgres (some images) |
| `SYS_PTRACE` | Debugging, process inspection | Development only |

> **Gotcha (entrypoint chown):** Some images (e.g., Eclipse Mosquitto, MariaDB) run `chown` on data directories before dropping to a non-root user. They crash with `Operation not permitted` unless you add `SETGID`, `SETUID`, `CHOWN`, and `DAC_OVERRIDE`.

### 3.3 Read-Only Root Filesystem

Where possible, make the container's root filesystem immutable:

```yaml
services:
  app:
    read_only: true
    tmpfs:
      - /tmp                    # Writable temp directory (RAM-backed)
      - /run                    # Some services need this
```

This prevents an attacker from writing to the container filesystem. Use `tmpfs` mounts for directories that need to be writable.

### 3.4 Run as Non-Root

```yaml
services:
  app:
    user: "1000:1000"           # Run as your host user, not root
```

Or build images with a non-root `USER` directive.

> **Note:** `PUID`/`PGID` environment variables are a [LinuxServer.io](https://docs.linuxserver.io/general/understanding-puid-and-pgid/) convention, not a Docker or official-image standard. Most official images (postgres, redis, nginx) do **not** support them. Check the image documentation for the correct method — some use `user:` in compose, others handle ownership in their entrypoint.

### 3.5 Docker Socket Safety

The Docker socket (`/var/run/docker.sock`) gives **full root-equivalent access** to the host. A compromised container with socket access can:

- Create privileged containers
- Mount the host root filesystem
- Execute commands on the host as root

Rules:
- Mount with `:ro` where possible: `/var/run/docker.sock:/var/run/docker.sock:ro`
- Both Watchtower and Portainer work with `:ro` mounts

> **Gotcha (`:ro` is not API restriction):** The `:ro` flag on a Unix socket mount only prevents deleting or replacing the socket **file** — it does **not** restrict API operations sent through the socket. A container with `:ro` socket access can still create privileged containers, mount the host filesystem, and execute commands as root. The `:ro` flag prevents one specific attack (replacing the socket with a malicious one) but is not meaningful access control.

- For real socket protection, use [Tecnativa/docker-socket-proxy](https://github.com/Tecnativa/docker-socket-proxy) to expose only specific API endpoints (e.g., allow container listing but block container creation)

### 3.6 Secrets Management

**Never** put passwords in:
- Compose files (committed to git)
- `.env` files (can leak, often committed accidentally)
- Environment variables in the compose file (visible via `docker inspect`)

Use Docker secrets:

```yaml
secrets:
  db_password:
    file: ./secrets/db_password.txt    # Plain text, no trailing newline

services:
  database:
    secrets:
      - db_password
    environment:
      - POSTGRES_PASSWORD_FILE=/run/secrets/db_password
```

- Add `secrets/` to `.gitignore`
- Create secret files with: `echo -n "password" > secrets/db_password.txt`
- Not all images support `_FILE` suffix — check the image documentation
- Consider encrypting secrets at rest with `age`, `sops`, or `git-crypt`

> **Gotcha:** File-based secrets require Compose v2. Legacy `docker-compose` (Python v1) requires Swarm mode for secrets.

### 3.7 Network Segmentation

See [Section 7: Networking](#7-networking) for isolating services by trust zone.

### 3.8 AppArmor and Seccomp

Docker applies default AppArmor and seccomp profiles to all containers. For additional hardening:

```yaml
services:
  app:
    security_opt:
      - no-new-privileges:true
      - seccomp:./seccomp-profile.json     # Custom seccomp profile
      # - apparmor:docker-custom            # Custom AppArmor profile
```

The default seccomp profile blocks ~44 dangerous syscalls. Only create custom profiles if you need to restrict further.

### 3.9 Documenting Security Exceptions

When a service can't follow the defaults, document **why** and **what compensates**:

```yaml
services:
  cadvisor:
    # EXCEPTION: Requires privileged mode for cgroup v2 metrics.
    # Compensation: read-only volume mounts, no published ports on
    # sensitive interfaces, isolated monitoring network.
    privileged: true
    security_opt:
      - no-new-privileges:true     # Still applied even with privileged
```

Common exceptions and their compensations:

| Exception | Why Needed | Compensating Control |
|-----------|-----------|---------------------|
| `privileged: true` | cgroup v2 metrics (cAdvisor) | Read-only mounts, network isolation |
| Extra capabilities (`cap_add`) | Entrypoint chown, raw sockets | Drop all first, add only what's needed |
| Writable root filesystem | App writes to non-volume paths | Limit with `tmpfs`, monitor with read-only data volumes |
| Running as root | Image doesn't support non-root | `no-new-privileges`, `read_only`, capability drop |
| Docker socket access | Container management | `:ro` mount + socket proxy, isolated network |

---

## 4. Storage & Volumes

> **In a nutshell:** Use bind mounts for config files you edit on the host. Use named volumes or bind mounts under `${DATA_DIR}` for persistent data. Mount config as `:ro`. Never store important data in the container filesystem — it's gone when the container is removed.

### 4.1 Bind Mounts vs Named Volumes

| Type | Syntax | Use When |
|------|--------|----------|
| Bind mount | `./config:/app/config:ro` | Config files you edit on the host |
| Bind mount (data) | `${DATA_DIR}/postgres:/var/lib/postgresql/data` | Data you need to backup directly |
| Named volume | `db-data:/var/lib/postgresql/data` | Docker-managed, better performance on macOS/Windows |
| tmpfs | `tmpfs: [/tmp]` | Ephemeral data that should never hit disk |

### 4.2 Volume Mount Patterns

Separate your mounts by purpose and permission:

```yaml
services:
  app:
    volumes:
      # Configuration — read-only, backed up via git
      - ./config/app.yml:/app/config/app.yml:ro

      # Application data — read-write, backed up via tar/rsync
      - ${DATA_DIR}/app/data:/app/data

      # Logs — read-write, rotated by the container or log driver
      - ${DATA_DIR}/app/logs:/app/logs

      # Cache / temp — ephemeral, RAM-backed
    tmpfs:
      - /tmp
      - /app/cache
```

### 4.3 Mount Permissions and Flags

| Flag | Meaning | When to Use |
|------|---------|-------------|
| `:ro` | Read-only | Config files, host system mounts (`/etc/localtime`) |
| `:rw` | Read-write (default) | Data directories |
| `:rslave` | Recursive slave propagation | When mounting `/` for system metrics |
| `:cached` | Relaxed consistency (macOS) | Source code mounts in development |
| `:delegated` | Container-authoritative (macOS) | Build output directories |
| `:z` | SELinux shared label | Multi-container access on SELinux hosts (Fedora, RHEL) |
| `:Z` | SELinux private label | Single-container access on SELinux hosts |

> **Gotcha (SELinux):** On Fedora, RHEL, and CentOS, bind mounts may fail with permission denied unless you add `:z` or `:Z`. Docker relabels the host directory — `:Z` is safer (private to one container) but prevents sharing.

### 4.4 Recommended Directory Layout

```
${DATA_DIR}/
├── app/
│   ├── config/          # Application configuration (backed up)
│   ├── data/            # Persistent data (backed up)
│   └── logs/            # Log files (rotated, optional backup)
├── database/
│   └── data/            # Database files (backed up, stop before snapshot)
├── monitoring/
│   ├── prometheus/      # TSDB data (expendable, retention-managed)
│   └── grafana/         # Dashboard state (backed up)
└── cache/               # Ephemeral cache (no backup needed)
```

### 4.5 File Ownership

Most containers run as a specific UID/GID. Ensure your host directories match:

```bash
# Create directories with correct ownership
sudo mkdir -p /mnt/data/app/data
sudo chown 1000:1000 /mnt/data/app/data

# Or let the container handle it (if it runs as root at startup)
# Many images accept PUID/PGID environment variables
```

> **Gotcha:** If you run the container as `user: "1000:1000"` but the host directory is owned by root, the container can't write. Always verify ownership matches.

---

## 5. Host Filesystem Setup

> **In a nutshell:** Use a dedicated data drive (ext4 or XFS) mounted with `noatime,nofail`. On macOS, prefer named volumes for heavy I/O. On Windows, always store data on the WSL2 filesystem — never on NTFS mounts.

### 5.1 Linux

**Recommended filesystem:** ext4 (default, battle-tested) or XFS (better for large files / databases)

```bash
# Format a dedicated data drive
sudo mkfs.ext4 -L docker-data /dev/sdX1
# Or for XFS:
# sudo mkfs.xfs -L docker-data /dev/sdX1

# Create mount point
sudo mkdir -p /mnt/data

# Mount
sudo mount /dev/sdX1 /mnt/data

# Add to /etc/fstab for persistence (use UUID for reliability)
UUID=$(sudo blkid -s UUID -o value /dev/sdX1)
echo "UUID=$UUID /mnt/data ext4 defaults,noatime,nofail 0 2" | sudo tee -a /etc/fstab
```

**Recommended mount options:**
- `noatime` — don't update access times (reduces disk writes, improves SSD lifespan)
- `nofail` — don't block boot if the drive is missing (critical for external/USB drives)
- `discard` — enable TRIM for SSDs (or use `fstrim.timer` systemd service)

**Permissions:**
```bash
sudo chown 1000:1000 /mnt/data    # Match your PUID/PGID
sudo chmod 750 /mnt/data           # Owner: rwx, group: rx, other: none
```

**Raspberry Pi / SBCs:**
- NVMe SSD via PCIe or USB3 adapter is strongly recommended over SD card for data
- Add `cgroup_enable=memory` to `/boot/firmware/cmdline.txt` for Docker memory limits
- For NVMe booting: configure `BOOT_ORDER` in EEPROM with `rpi-eeprom-config`

### 5.2 macOS

Docker Desktop for Mac runs containers in a lightweight Linux VM. Volumes are shared via VirtioFS (default) or gRPC FUSE.

**Filesystem:** APFS (default macOS filesystem) — no special setup needed.

**Performance:**
- Bind mounts are slower than native Linux due to the VM layer
- For large data volumes (databases), prefer named volumes over bind mounts
- In development, use `:cached` flag for source code mounts

**Data location:**
- Docker VM disk image: `~/Library/Containers/com.docker.docker/Data/vms/0/data/`
- Default bind mount root: your macOS home directory
- Recommended data directory: `~/docker-data/` or `/opt/docker-data/`

**Permissions:**
```bash
mkdir -p ~/docker-data
# macOS doesn't use UID/GID the same way — Docker Desktop maps your macOS
# user to the container user. Usually no permission issues with bind mounts
# from your home directory.
```

### 5.3 Windows

Docker Desktop for Windows uses WSL2 as the backend.

**Filesystem options:**

| Location | Filesystem | Performance | Recommendation |
|----------|-----------|-------------|----------------|
| WSL2 ext4 (`/home/...`) | ext4 in VM | Fast | **Use this for all data** |
| Windows NTFS (`C:\...` or `/mnt/c/`) | NTFS via 9P | Very slow | Avoid for databases/volumes |
| Named volumes | ext4 in Docker VM | Fast | Good alternative |

**Setup:**
```powershell
# In WSL2 (Ubuntu/Debian):
sudo mkdir -p /mnt/data
sudo chown 1000:1000 /mnt/data
```

**Line endings:** Ensure all config files use LF, not CRLF:
```bash
git config --global core.autocrlf input
```

> **Gotcha:** Never store Docker volume data on NTFS mounts (`/mnt/c/`). The 9P filesystem bridge is extremely slow and causes permission issues. Always use the WSL2 native ext4 filesystem.

### 5.4 FreeBSD / Unix

Docker is not officially supported on FreeBSD. Alternatives:
- **Podman** — compatible with Docker Compose files, runs natively on FreeBSD
- **Jails + Bastille** — FreeBSD-native containerisation
- **bhyve VM** — run Docker inside a Linux VM on FreeBSD

If using a Linux VM on FreeBSD:
- Use ZFS for the VM disk image (native to FreeBSD, excellent snapshotting for backups)
- Format the VM's data volume as ext4 or XFS (same as Linux section above)

---

## 6. Environment & Configuration

> **In a nutshell:** Put non-sensitive shared config (timezone, paths, UIDs) in `.env`. Put passwords and tokens in Docker secrets. Never commit `.env` or secrets to git.

### 6.1 The `.env` File

Docker Compose automatically loads `.env` from the compose file's directory. Use it for **non-sensitive**, shared configuration:

```
TZ=UTC
PUID=1000
PGID=1000
DATA_DIR=/mnt/data
COMPOSE_PROJECT_NAME=mystack
```

Provide `.env.example` in your repo as a template. Add `.env` to `.gitignore`.

> **Gotcha:** `.env` is loaded relative to the **compose file's directory**, not your working directory. Running `docker compose -f /path/to/docker-compose.yml up` loads `/path/to/.env`.

### 6.2 Environment Variable Precedence

From highest to lowest priority:
1. `docker compose run -e VAR=value` (CLI override)
2. `environment:` block in the compose file
3. `--env-file` flag
4. `.env` file
5. Host environment variables

### 6.3 Sensitive vs Non-Sensitive Config

| Type | Storage Method | Example |
|------|---------------|---------|
| Passwords, tokens, keys | Docker secrets (`_FILE` suffix) | `POSTGRES_PASSWORD_FILE=/run/secrets/db_pass` |
| API endpoints, feature flags | `environment:` in compose | `API_URL=http://backend:3000` |
| Timezone, UID, paths | `.env` file | `TZ=UTC`, `DATA_DIR=/mnt/data` |

### 6.4 Docker Configs (Read-Only Files)

For non-sensitive config files that need to be injected:

```yaml
configs:
  nginx_conf:
    file: ./nginx/nginx.conf

services:
  proxy:
    configs:
      - source: nginx_conf
        target: /etc/nginx/nginx.conf
        mode: 0444                       # Read-only
```

This is an alternative to bind-mounting config files. Useful in Swarm deployments.

---

## 7. Networking

> **Troubleshooting:** If containers can't reach each other, see [Troubleshooting — Service connectivity](TROUBLESHOOTING.md#17-service-cant-connect-to-another-service) and [Debugging — Check networking](TROUBLESHOOTING.md#step-7-check-networking).

### 7.1 Network Types

| Type | Use When | Command |
|------|----------|---------|
| `bridge` (default) | Isolated container communication | `driver: bridge` |
| `host` | Container needs direct LAN access (mDNS, SSDP) | `network_mode: host` |
| `none` | Container should have no network access | `network_mode: none` |
| `macvlan` | Container needs its own IP on the LAN | `driver: macvlan` |

### 7.2 Network Isolation by Trust Zone

```yaml
networks:
  frontend:
    driver: bridge       # Public-facing services (web, reverse proxy)
  backend:
    driver: bridge       # Internal services (databases, caches, APIs)
  management:
    driver: bridge       # Docker management tools (Portainer, Watchtower)
  monitoring:
    driver: bridge       # Metrics collection (Prometheus, exporters)
```

Place each service on only the networks it needs. A web app might join `frontend` and `backend`, while the database only joins `backend`.

### 7.3 Internal Networks

For networks that should never be externally accessible:

```yaml
networks:
  backend:
    driver: bridge
    internal: true       # No external/internet access
```

### 7.4 Host Network Mode

```yaml
services:
  app:
    network_mode: host   # Bypass Docker networking entirely
```

> **Gotcha:** `network_mode: host` means the container **cannot** join custom bridge networks. Other containers reach it via `172.17.0.1` (Docker bridge gateway) or the host's LAN IP.
>
> **Gotcha (macOS/Windows):** `network_mode: host` connects to the Docker VM's network, not your physical LAN. Device discovery (mDNS, SSDP) will not work.

### 7.5 Port Publishing

```yaml
services:
  app:
    ports:
      - "8080:8080"            # Bind to all interfaces (0.0.0.0)
      - "127.0.0.1:8080:8080"  # Bind to localhost only (more secure)
```

> **Security:** For services that should only be accessed locally or through a reverse proxy, bind to `127.0.0.1` to prevent external access.

---

## 8. Resource Limits

> **In a nutshell:** Every container must have `mem_limit`, `cpus`, and `pids_limit` set. Without them, a single runaway container can starve or crash the entire host. Start with the sizing guidelines and tune from `docker stats`.

### 8.1 Mandatory Limits

Every container MUST have these set:

```yaml
services:
  app:
    mem_limit: 256m        # CIS 5.10 — prevent OOM killing neighbours
    cpus: 1.0              # CIS 5.12 — prevent CPU starvation
    pids_limit: 200        # CIS 5.28 — prevent fork bombs
```

### 8.2 Sizing Guidelines

| Service Type | Memory | CPUs | PIDs |
|-------------|--------|------|------|
| Databases (Postgres, MySQL, MongoDB) | 512m–2g | 1.0–2.0 | 200–500 |
| Application servers (Node.js, Python, Go) | 256m–512m | 1.0 | 200 |
| Web servers / reverse proxies | 64m–128m | 0.5 | 100 |
| Message brokers (MQTT, RabbitMQ) | 64m–256m | 0.25–1.0 | 50–200 |
| Monitoring (Prometheus, Grafana) | 256m–512m | 1.0 | 200 |
| Lightweight exporters / sidecars | 32m–64m | 0.25 | 50 |
| Management tools (Portainer) | 128m | 0.5 | 100 |

Tune based on actual usage: `docker stats --no-stream`

### 8.3 Memory Reservation vs Limit

```yaml
services:
  database:
    mem_limit: 1g          # Hard cap — OOM-killed if exceeded
    mem_reservation: 512m  # Soft limit — Docker tries to maintain this
```

### 8.4 Verifying Limits Are Enforced

```bash
# Check for Docker warnings about missing cgroup support
docker info | grep -i "warning"

# Verify cgroup memory controller is enabled
cat /proc/cgroups | grep memory    # "enabled" column should be 1

# Inspect a running container's limits
docker inspect <container> --format '{{.HostConfig.Memory}}'
```

> **Gotcha (Raspberry Pi / ARM):** Memory limits silently do nothing unless `cgroup_enable=memory` is in the kernel command line (`/boot/firmware/cmdline.txt`).
>
> **Gotcha (macOS / Windows):** Limits are enforced within the Docker Desktop VM. The VM has its own resource cap set in Docker Desktop → Settings → Resources.

### 8.5 Ulimits

Databases and high-concurrency services often need tuned file descriptor limits:

```yaml
services:
  database:
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
      nproc:
        soft: 4096
        hard: 4096
```

| Ulimit | Default | When to Increase | Typical Services |
|--------|---------|-----------------|-----------------|
| `nofile` (open files) | 1024 | High connection count, many open DB files | Postgres, MySQL, Elasticsearch, Redis |
| `nproc` (processes) | 4096 | Thread-heavy workloads | Java apps, databases |
| `memlock` | 64KB | Lock memory pages (disable swap for perf) | Elasticsearch, Redis with persistence |

---

## 9. Healthchecks & Dependencies

> **Troubleshooting:** For common healthcheck failures, see [Troubleshooting — Check healthchecks](TROUBLESHOOTING.md#step-6-check-healthchecks).

### 9.1 Healthcheck Configuration

```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s        # How often to check
      timeout: 10s         # Must be < interval
      retries: 3           # Failures before marking unhealthy
      start_period: 30s    # Grace period for slow-starting services
```

### 9.2 Healthcheck Patterns by Service Type

| Service Type | Healthcheck | Notes |
|-------------|-------------|-------|
| HTTP web app | `curl -f http://localhost:PORT/health` | Use a public endpoint (no auth) |
| PostgreSQL | `pg_isready -U user` | Built-in CLI tool |
| MySQL / MariaDB | `mysqladmin ping -h localhost` | Built-in CLI tool |
| Redis | `redis-cli ping` | Returns "PONG" |
| MongoDB | `mongosh --eval "db.adminCommand('ping')"` | |
| MQTT broker | `mosquitto_sub -t '$$SYS/#' -C 1 -W 5` | CMD-SHELL required |
| Prometheus | `wget --spider http://localhost:9090/-/healthy` | wget available in image |
| Grafana | `wget --spider http://localhost:3000/api/health` | |

### 9.3 CMD vs CMD-SHELL

| Format | Shell Required? | Use When |
|--------|----------------|----------|
| `["CMD", "binary", "args"]` | No | Default — more secure, works in minimal images |
| `["CMD-SHELL", "command &#124;&#124; exit 1"]` | Yes (`/bin/sh`) | Need pipes, `&#124;&#124;`, or shell features |

> **Gotcha:** Some minimal images (distroless, Portainer, scratch-based) have no shell — `CMD-SHELL` will fail. Use `CMD` with a binary that exists in the image.

### 9.4 Dependency Ordering

```yaml
services:
  app:
    depends_on:
      database:
        condition: service_healthy       # Wait for DB healthcheck to pass
      cache:
        condition: service_started       # Just wait for container to start
```

> **Gotcha:** `condition: service_healthy` requires the dependency to have a healthcheck defined. Without one, compose will error.

---

## 10. Logging

> **In a nutshell:** Always configure log rotation (`max-size: "10m"`, `max-file: "3"`) — without it, logs grow until your disk is full. Use a shared YAML anchor so every service gets the same config.

### 10.1 Log Rotation

Every service MUST have log rotation configured to prevent disk exhaustion:

```yaml
x-logging: &default-logging
  driver: json-file
  options:
    max-size: "10m"        # Cap each log file at 10MB
    max-file: "3"          # Keep 3 rotated files (30MB max per container)
```

### 10.2 Alternative: Daemon-Level Default

Set globally in `/etc/docker/daemon.json`:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

Per-service logging in compose overrides the daemon default. The anchor approach is preferred because it's visible and travels with the repo.

### 10.3 Log Drivers

| Driver | Use When |
|--------|----------|
| `json-file` | Default — works everywhere, supports `docker logs` |
| `local` | Better performance, compressed, but `docker logs` still works |
| `syslog` | Forwarding to a centralised syslog server |
| `fluentd` | Forwarding to Fluentd/Fluent Bit for aggregation |
| `none` | Disable logging entirely (not recommended) |

---

## 11. Graceful Shutdown

> **In a nutshell:** Set `stop_grace_period` on stateful services so they have time to flush data before Docker kills them. Use `init: true` if your container ignores stop signals. Databases need 30s; most services are fine with the 10s default.

### 11.1 Stop Grace Period

Set `stop_grace_period` on stateful services that need time to flush data:

```yaml
services:
  database:
    stop_grace_period: 30s     # 30 seconds before SIGKILL
```

| Service Type | Suggested Period | Reason |
|-------------|-----------------|--------|
| Databases (Postgres, MySQL, SQLite) | 30s | Transaction log / WAL flush |
| Time-series DBs (Prometheus, InfluxDB) | 15s | TSDB WAL flush |
| Application servers | 15s | In-flight request completion |
| Message brokers | 10s | Queue flush |
| Stateless services | 10s (default) | No special needs |

Docker sends SIGTERM first. If the container doesn't stop within the grace period, Docker sends SIGKILL — which can **corrupt databases**.

### 11.2 Stop Signal

Docker sends SIGTERM by default. Some services expect a different signal for graceful shutdown:

```yaml
services:
  proxy:
    stop_signal: SIGQUIT            # Nginx uses SIGQUIT for graceful shutdown
```

| Service | Graceful Signal | Notes |
|---------|----------------|-------|
| Most services | SIGTERM (default) | No `stop_signal` needed |
| Nginx | SIGQUIT | Finishes in-flight requests before exiting |
| PostgreSQL | SIGTERM or SIGINT | SIGTERM = smart shutdown (wait for clients) |
| HAProxy | SIGUSR1 | Graceful stop in some configurations |

### 11.3 Init Process (`init: true`)

```yaml
services:
  app:
    init: true                      # Add tini as PID 1
```

`init: true` adds a lightweight init process ([tini](https://github.com/krallin/tini)) as PID 1 in the container. This:
- **Forwards signals** properly to child processes (fixes containers that ignore SIGTERM)
- **Reaps zombie processes** that would otherwise accumulate
- Is especially useful for shell-based entrypoints, multi-process containers, and services that don't handle PID 1 responsibilities

> **When to use:** If your container runs a shell script entrypoint, spawns background processes, or doesn't respond to `docker stop` within a few seconds, add `init: true`.

### 11.4 Signal Handling in Dockerfiles

Ensure your application handles SIGTERM gracefully. In shell-based entrypoints, use `exec` to replace the shell process so SIGTERM reaches the application:

```dockerfile
# BAD — SIGTERM goes to the shell, not the app
CMD /start.sh

# GOOD — app receives SIGTERM directly
CMD ["node", "server.js"]
# Or in shell scripts:
CMD exec node server.js
```

---

## 12. Update Management

> **In a nutshell:** Use Watchtower for automatic updates on non-critical services. Exclude databases and critical services with labels so you can review changelogs before updating them manually.

### 12.1 Automatic Updates with Watchtower

```yaml
services:
  watchtower:
    image: containrrr/watchtower:1.7.1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - WATCHTOWER_CLEANUP=true              # Remove old images
      - WATCHTOWER_SCHEDULE=0 0 4 * * *      # 4am daily
      - WATCHTOWER_LABEL_ENABLE=false        # Update all except opted-out
```

### 12.2 Selective Updates

Exclude critical services that need manual review:

```yaml
services:
  database:
    labels:
      - "com.centurylinklabs.watchtower.enable=false"
```

> **Note:** `WATCHTOWER_LABEL_ENABLE=false` means update **all** unless opted out. Set to `true` to only update containers explicitly opted in.

### 12.3 Manual Update Procedure

```bash
# 1. Check current versions
docker compose ps

# 2. Pull new images
docker compose pull <service>

# 3. Recreate with new image
docker compose up -d <service>

# 4. Verify
docker logs <container> --tail 20
```

### 12.4 Rollback

```bash
# 1. Stop the broken service
docker compose stop <service>

# 2. Check local images
docker images | grep <service>

# 3. Pin the previous version in docker-compose.yml
# 4. Restart
docker compose up -d <service>
```

---

## 13. Backup & Disaster Recovery

> **In a nutshell:** Keep compose files and config in git (Tier 1). Back up data volumes daily with tar or rsync (Tier 2). Use native database dump tools for databases (Tier 3). Test your restores quarterly — an untested backup is not a backup.

### 13.1 What to Protect

| Data Type | Priority | RPO | Backup Method |
|-----------|----------|-----|---------------|
| Application config | Critical | 24h | Tier 1 (git) + Tier 2 (tar) |
| Database volumes | Critical | 24h | Database dump + Tier 2 |
| Compose files + config | Critical | Real-time | Tier 1 (git) |
| Secrets | Critical | Manual | Secure offline storage |
| Dashboard / UI state | Medium | 7d | Tier 2 (tar) |
| Metrics / TSDB | Low | Expendable | Not backed up (retention-managed) |
| Cache | None | Expendable | Not backed up |

**RPO** = Recovery Point Objective — the maximum acceptable data loss in time.

### 13.2 Backup Tiers

**Tier 1 — Git (config-as-code)**
- All compose files, Prometheus config, provisioning scripts in git
- Push after every change
- Recovery: `git clone` on a fresh machine

**Tier 2 — Daily data volume backup**
- Schedule: daily (e.g. 2am, before any auto-updater runs)
- Tools:
  - [`offen/docker-volume-backup`](https://github.com/offen/docker-volume-backup) — Docker-native, handles stop/start
  - `cron` + `tar` — simple, universal
  - `rsync` — incremental, bandwidth-efficient for remote backups
  - `restic` or `borgbackup` — deduplicated, encrypted, supports cloud targets
- Target: USB drive, NAS, S3-compatible storage
- Retention: 7 days rolling minimum

```bash
# Simple daily backup script (add to cron)
#!/bin/bash
BACKUP_DIR=/backup
TIMESTAMP=$(date +%Y%m%d)
COMPOSE_FILE=/path/to/docker-compose.yml

# Stop only database containers for filesystem consistency.
# Stateless services (web apps, proxies) can be backed up live.
docker compose -f "$COMPOSE_FILE" stop database

tar czf "$BACKUP_DIR/stack-$TIMESTAMP.tar.gz" \
  /mnt/data/app \
  /mnt/data/database \
  /mnt/data/grafana

docker compose -f "$COMPOSE_FILE" start database

# Remove backups older than 7 days
find "$BACKUP_DIR" -name "stack-*.tar.gz" -mtime +7 -delete
```

**Tier 3 — Database-specific dumps**

For databases, a filesystem backup of a running database can produce a corrupt snapshot. Use native dump tools:

```bash
# PostgreSQL
docker exec database pg_dump -U app > /backup/db-$(date +%Y%m%d).sql

# MySQL / MariaDB
docker exec database mysqldump -u root --all-databases > /backup/db-$(date +%Y%m%d).sql

# MongoDB
docker exec database mongodump --out /backup/mongo-$(date +%Y%m%d)

# Redis
docker exec cache redis-cli BGSAVE
# Then copy the dump.rdb file
```

**Tier 4 — Full disk image (OS + everything)**
- Quarterly or before major changes
- Tools: `dd`, Clonezilla, Raspberry Pi Imager (for Pi)
- Store off-site (different physical location)

### 13.3 Recovery Procedures

#### Single container crash
```bash
docker logs <container> --tail 50
docker compose restart <service>
docker stats <container>                          # Check resource usage
docker inspect <container> | grep -i oom          # Check OOM kills
```

#### Bad update
```bash
docker compose stop <service>
docker images | grep <service>                    # Find previous version
# Edit docker-compose.yml to pin the old version
docker compose up -d <service>
```

#### Storage failure
```bash
# 1. Replace/format drive, mount at your DATA_DIR
# 2. Restore from Tier 2 backup: tar xzf /backup/stack-YYYYMMDD.tar.gz -C /
# 3. Restore database from Tier 3 dump if needed
# 4. git clone your compose repo
# 5. Recreate secrets, copy .env.example to .env
# 6. docker compose up -d
```

#### Full host failure
```bash
# 1. Fresh OS install (or restore Tier 4 image)
# 2. Install Docker: curl -fsSL https://get.docker.com | sh
# 3. Mount/format storage drive
# 4. Restore data and start stack (see storage failure above)
```

### 13.4 Testing Backups

**Monthly:** Verify backups exist and aren't corrupt
```bash
ls -lh /backup/stack-*.tar.gz
tar tzf /backup/stack-LATEST.tar.gz | head -20
```

**Quarterly:** Restore on spare hardware or a VM to verify the full recovery path works.

---

## 14. Monitoring

> **In a nutshell:** At minimum, use `docker stats` and `docker ps` to check health. For proper monitoring, run Prometheus + Grafana + Node Exporter + cAdvisor — there's a ready-made stack in the [monitoring/](../monitoring/) directory.

### 14.1 Quick Health Commands

```bash
# Container status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Resource usage
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Disk usage
docker system df

# Reclaim space
docker system prune -f
```

### 14.2 Recommended Alert Thresholds

| Alert | Threshold | Severity |
|-------|-----------|----------|
| Disk usage | > 80% | Warning |
| Disk usage | > 90% | Critical |
| Container memory | > 90% of limit | Warning |
| Container restarts | > 3 in 10 minutes | Critical |
| Healthcheck failure | 3 consecutive | Critical |
| CPU temperature | > 80°C | Warning |
| Backup age | > 48 hours | Warning |

### 14.3 Monitoring Stack

A complete monitoring stack typically includes:

| Component | Purpose | Port |
|-----------|---------|------|
| Prometheus | Metrics collection and TSDB | 9090 |
| Grafana | Dashboards and alerting | 3000 |
| Node Exporter | Host system metrics | 9100 |
| cAdvisor | Container metrics | 8080 |
| SNMP Exporter | Network device metrics | 9116 |
| Alertmanager | Alert routing and deduplication | 9093 |

See the [monitoring/](../monitoring/) directory for an example compose file.

---

## 15. Cross-Platform Compatibility

> **In a nutshell:** Security hardening, resource limits, healthchecks, and secrets work everywhere. Host networking, USB passthrough, and system-level monitoring (Node Exporter, cAdvisor) only work properly on native Linux.

### 15.1 Feature Matrix

| Feature | Linux | macOS (Docker Desktop) | Windows (Docker Desktop / WSL2) |
|---------|-------|----------------------|-------------------------------|
| `network_mode: host` | Native LAN access | Docker VM only | Docker VM only |
| USB device passthrough | Native | Not supported | Requires `usbipd-win` |
| `/proc`, `/sys` mounts | Host kernel | VM kernel | VM kernel |
| `tmpfs` | Real RAM | VM disk | VM disk |
| `privileged: true` | Full host access | VM-scoped | VM-scoped |
| `read_only: true` | Works | Works | Works |
| cgroup resource limits | Native | Via VM | Via VM |
| Volume performance | Native | VirtioFS (slower) | ext4/WSL2 (fast), NTFS (slow) |
| SELinux `:z`/`:Z` flags | Fedora/RHEL | N/A | N/A |

### 15.2 What Works Everywhere

These patterns work on all platforms without modification:
- Security hardening (`no-new-privileges`, `cap_drop`, `read_only`)
- Resource limits (`mem_limit`, `cpus`, `pids_limit`)
- Healthchecks and `depends_on`
- Docker secrets
- Logging configuration
- Bridge networks

### 15.3 Linux-Only for Production

These require native Linux for meaningful results:
- **Node Exporter** — reports VM metrics on macOS/Windows
- **cAdvisor** — reports VM-level container metrics on non-Linux
- **`network_mode: host`** — connects to VM, not your physical LAN
- **USB device passthrough** — not supported on macOS

---

## 16. USB & Hardware Devices

> **In a nutshell:** Always use `/dev/serial/by-id/` paths for USB devices — they're stable across reboots and don't change when you plug in other devices. USB passthrough only works on native Linux.

### 16.1 Persistent Device Paths

Always use `/dev/serial/by-id/` for USB devices:

```yaml
devices:
  # GOOD — unique to the physical device, survives reboots
  - /dev/serial/by-id/usb-VENDOR_PRODUCT_SERIAL-if00-port0:/dev/ttyUSB0

  # BAD — can change when other USB devices are plugged in
  - /dev/ttyUSB0:/dev/ttyUSB0
```

Find your devices: `ls -la /dev/serial/by-id/`

### 16.2 Platform Limitations

| Platform | USB Support |
|----------|-------------|
| Linux | Native — full device passthrough |
| macOS | Not supported — use network-based alternatives (e.g., `ser2net`) |
| Windows | Requires [`usbipd-win`](https://github.com/dorssel/usbipd-win) to forward into WSL2 |

---

## 17. Penetration Testing Readiness

> **In a nutshell:** This section maps every security control in this guide to what a pen tester would flag if it's missing. If you follow sections 3, 7, and 8, you'll pass most container-focused pen test checks.

### 17.1 Container Isolation (CIS Docker Benchmark)

| Control | CIS Ref | Implementation | Pen Test Finding If Missing |
|---------|---------|----------------|----------------------------|
| Drop all capabilities | 5.3 | `cap_drop: [ALL]` | Privilege escalation via capabilities |
| No new privileges | 5.25 | `security_opt: [no-new-privileges:true]` | setuid binary exploitation |
| Memory limits | 5.10 | `mem_limit: 256m` | Denial of service (resource exhaustion) |
| CPU limits | 5.12 | `cpus: 1.0` | Denial of service (CPU starvation) |
| PID limits | 5.28 | `pids_limit: 200` | Fork bomb / PID exhaustion |
| Read-only filesystem | 5.12 | `read_only: true` + `tmpfs: [/tmp]` | Malware persistence, file drops |
| Non-root user | 5.21 | `user: "1000:1000"` | Container breakout via root |

### 17.2 Network Security

| Control | Implementation | Pen Test Finding If Missing |
|---------|----------------|----------------------------|
| Network segmentation | Separate bridge networks per trust zone | Lateral movement between services |
| Internal networks | `internal: true` on backend networks | Unexpected internet access from internal services |
| Localhost binding | `127.0.0.1:8080:8080` for internal services | Unintended external exposure |
| No inter-container trust | Each service has minimum network membership | Compromised container pivoting to others |

### 17.3 Secrets & Credentials

| Control | Implementation | Pen Test Finding If Missing |
|---------|----------------|----------------------------|
| No plaintext passwords | Docker secrets (`_FILE` suffix) | Credential exposure in compose files |
| No secrets in `.env` | Secrets in `./secrets/` directory | Credential exposure in environment |
| Secrets not in git | `secrets/` in `.gitignore` | Credential exposure in version control |
| Minimal env vars | Only non-sensitive config in environment | Information disclosure via `docker inspect` |

### 17.4 Docker Socket Protection

| Control | Implementation | Pen Test Finding If Missing |
|---------|----------------|----------------------------|
| Read-only socket | `:ro` mount where possible | Full host compromise via container |
| Minimal socket access | Only management tools get socket | Unnecessary attack surface |
| Socket proxy | Tecnativa/docker-socket-proxy | API endpoint restriction |

### 17.5 Image Security

| Control | Implementation | Pen Test Finding If Missing |
|---------|----------------|----------------------------|
| Pinned versions | Exact tags (no `:latest`) | Supply chain attack, unpredictable updates |
| Official images | Docker Hub verified publishers | Malicious image injection |
| Signature verification | Cosign / digest pinning | Image tampering |
| Regular updates | Watchtower or manual pull schedule | Known CVE in outdated images |

### 17.6 Logging & Audit Trail

| Control | Implementation | Pen Test Finding If Missing |
|---------|----------------|----------------------------|
| Container logs | `json-file` driver with rotation | No forensic trail after incident |
| Docker daemon audit | `auditd` rules for Docker socket | Undetected Docker API abuse |
| Resource monitoring | Prometheus + Grafana alerts | No detection of anomalous behaviour |

### 17.7 Additional Hardening

For production environments expecting regular pen tests:

```yaml
services:
  app:
    # Custom seccomp profile to restrict syscalls
    security_opt:
      - no-new-privileges:true
      - seccomp:./profiles/seccomp-strict.json

    # Custom AppArmor profile
    # security_opt:
    #   - apparmor:docker-custom

    # DNS configuration — prevent DNS rebinding
    dns:
      - 1.1.1.1
      - 8.8.8.8

    # Disable inter-container communication on the default bridge
    # (set in daemon.json: "icc": false)
```

**Daemon-level hardening** (`/etc/docker/daemon.json`):
```json
{
  "icc": false,
  "userns-remap": "default",
  "no-new-privileges": true,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true
}
```

- `icc: false` — disables inter-container communication on the default bridge (CIS 2.1)
- `userns-remap` — maps container root to an unprivileged host user (CIS 2.8)
- `live-restore` — containers survive daemon restarts (CIS 2.14)

---

## 18. Container Source Verification & Supply Chain Security

> **In a nutshell:** Before adding any image to your stack, check who maintains it, whether it has unpatched CVEs, and how it's signed. Use the trust framework (T1–T5) and pre-adoption checklist to make the decision systematic.

### 18.1 Image Trust Framework

Classify every image by trust level:

| Level | Label | Criteria | Review Frequency |
|-------|-------|----------|------------------|
| T1 | **Official** | Maintained by the project itself, Docker Hub verified publisher | Quarterly |
| T2 | **Verified** | Large community (10k+ stars), regular security audits, CNCF/LF project | Monthly |
| T3 | **Community** | 1,000+ GitHub stars, active maintenance, responsive to CVEs | Monthly |
| T4 | **Experimental** | New/unproven, <1,000 stars, single maintainer | Weekly |
| T5 | **Deprecated** | No longer maintained, no commits in 12+ months | **Do not use** |

### 18.2 Pre-Adoption Checklist

Before adding ANY new container image:

- [ ] **Source repository verified** — can you find the Dockerfile and CI pipeline?
- [ ] **Maintainer reputation** — is it an organisation, CNCF project, or solo developer?
- [ ] **License compatible** — MIT, Apache 2.0, BSD preferred; check AGPL implications
- [ ] **Last commit within 6 months** — abandoned projects don't get security patches
- [ ] **No critical CVEs unpatched >30 days** — check [Docker Scout](https://docs.docker.com/scout/) or Trivy
- [ ] **Signed releases or verified checksums** — use Cosign or check digests (see [18.5](#185-supply-chain-protection))
- [ ] **Multi-arch support** — publishes `linux/amd64` and `linux/arm64` if you need both
- [ ] **Adequate documentation** — clear configuration, environment variables, volume mounts
- [ ] **Image size reasonable** — bloated images often include unnecessary attack surface
- [ ] **Base image known** — check `FROM` in the Dockerfile (Alpine, Debian, distroless preferred)

### 18.3 Security Scanning

| Scan Type | Frequency | Tool | Purpose |
|-----------|-----------|------|---------|
| Container vulnerability scan | Every build + daily | [Trivy](https://github.com/aquasecurity/trivy), Docker Scout | Known CVEs in image layers |
| SBOM generation | Every release | [CycloneDX](https://cyclonedx.org/), Syft | Software bill of materials |
| License compliance | Monthly | FOSSA, Trivy | License compatibility check |
| CVE monitoring | Continuous | GitHub Dependabot, Snyk | Ongoing vulnerability alerts |

```bash
# Scan an image with Trivy (free, open source)
trivy image postgres:16.6

# Scan with Docker Scout (built into Docker Desktop)
docker scout cves postgres:16.6

# Generate SBOM
trivy image --format cyclonedx postgres:16.6 > sbom.json
```

### 18.4 Version Pinning Policy

```yaml
# PRODUCTION — always pin to exact patch version
image: postgres:16.6

# STAGING — minor version acceptable if image publishes rolling tags
image: postgres:16

# NEVER in production — unpredictable, unauditable, breaks reproducibility
image: postgres:latest
```

### 18.5 Supply Chain Protection

**Risk:** An upstream image could be compromised (malicious layer injection, account takeover, typosquatting).

**Mitigations:**

1. **Verify image signatures** — use modern signing tools:

   | Tool | Status | Use When |
   |------|--------|----------|
   | [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/) | **Recommended** | Keyless signing via OIDC, widely adopted by CNCF projects |
   | [Notation (Notary v2)](https://notaryproject.dev/) | Emerging | OCI-native signatures, cloud registry integration |
   | Docker Content Trust (DCT/Notary v1) | **Legacy — being retired** | Historical; Docker no longer signs Official Images with DCT |

   ```bash
   # Verify with Cosign (modern approach)
   cosign verify --certificate-identity-regexp '.*' \
     --certificate-oidc-issuer-regexp '.*' postgres:16.6

   # Legacy DCT (still works for some images, but being phased out)
   export DOCKER_CONTENT_TRUST=1
   ```

   > **Note:** Docker Content Trust for Official Images is being retired. Docker recommends migrating to Sigstore-based verification. See [Docker's signing roadmap](https://docs.docker.com/engine/security/trust/) for current status.

2. **Pin by digest** — the most tamper-proof method (immutable hash):
   ```yaml
   image: postgres@sha256:abc123...
   ```
   Find the digest: `docker inspect --format='{{index .RepoDigests 0}}' postgres:16.6`

3. **Mirror critical images** — copy to a private registry you control:
   ```bash
   # Mirror to GitHub Container Registry
   docker pull postgres:16.6
   docker tag postgres:16.6 ghcr.io/your-org/mirror/postgres:16.6
   docker push ghcr.io/your-org/mirror/postgres:16.6
   ```
   Benefits: protection against upstream compromise, offline availability, full audit trail.

4. **Automated update monitoring** — use Renovate or Dependabot to track new versions:
   ```json
   // renovate.json
   {
     "extends": ["config:base"],
     "docker-compose": { "enabled": true }
   }
   ```

### 18.6 Application Security Scorecard

Assess each service in your stack:

| Criteria | Score | What to Check |
|----------|-------|---------------|
| Maintainer | A–F | Organisation vs solo dev, response time to CVEs |
| CVE history | A–F | Frequency and severity of past vulnerabilities |
| Update cadence | A–F | Regular releases, LTS support |
| Default security | A–F | Auth enabled by default, no dangerous defaults |
| Documentation | A–F | Security configuration guide, hardening docs |

**Red flags that should block adoption:**
- No authentication by default on a network-exposed service
- Critical CVEs unpatched for >30 days
- Single maintainer with no succession plan
- Requires `privileged: true` without clear justification
- No healthcheck endpoint
- Runs as root with no option to change

---

## 19. LLM-Assisted Stack Design Workflow

> **In a nutshell:** Copy-paste these prompt templates into an LLM to get it to design, critique, deploy, test, and maintain your Docker Compose stack. Each phase has a specific prompt that feeds the right context to the LLM.

### 19.1 Phase 1 — Requirements & Design

**Prompt: Define stack requirements**
```
I need to design a Docker Compose stack for [describe your use case].

Requirements:
- Services needed: [list services]
- Expected traffic/load: [describe]
- Platform: [Linux/macOS/Windows, architecture]
- Storage: [describe available storage, e.g. "NVMe SSD mounted at /mnt/data"]
- Security requirements: [e.g. "production, internet-facing" or "internal homelab"]
- Monitoring: [yes/no, existing tools]

Please design the stack architecture including:
1. Service selection with specific image versions (verify tags exist)
2. Network topology (which services need to communicate)
3. Volume mapping strategy (config vs data vs logs)
4. Resource allocation (memory, CPU, PIDs per service)
5. Security posture (capabilities, read-only filesystems, secrets)
6. Dependency ordering (healthcheck-based startup)
```

**Prompt: Evaluate image choices**
```
For each Docker image in my stack, assess:
1. Trust level (official/verified/community/experimental)
2. CVE history and current vulnerability status
3. Whether the exact version tag exists on Docker Hub
4. Multi-architecture support (amd64, arm64)
5. License compatibility
6. Whether it runs as non-root by default
7. Available healthcheck endpoints

Images to assess:
- [image:tag]
- [image:tag]
```

### 19.2 Phase 2 — Compose File Critique

**Prompt: Security audit**
```
Critique this Docker Compose file against CIS Docker Benchmark and OWASP
Docker Security Cheat Sheet. For each service, check:

1. Is no-new-privileges set? (CIS 5.25)
2. Are all capabilities dropped with only necessary ones added back? (CIS 5.3)
3. Are resource limits set (mem_limit, cpus, pids_limit)? (CIS 5.10/5.12/5.28)
4. Is the filesystem read-only where possible?
5. Are secrets properly managed (not in env vars or compose file)?
6. Is the Docker socket mount necessary and read-only?
7. Is the service running as non-root?
8. Are volumes mounted with minimum permissions (:ro where possible)?
9. Is the service on the minimum necessary networks?
10. Are ports bound to 127.0.0.1 where external access isn't needed?

Rate each finding as: PASS / FAIL / WARNING / NOT APPLICABLE
Provide the fix for each FAIL.

[paste your docker-compose.yml]
```

**Prompt: Architecture review**
```
Review this Docker Compose stack for production readiness:

1. Are there any single points of failure?
2. Is network isolation adequate (lateral movement risk)?
3. Are healthchecks properly configured (timeout < interval, start_period)?
4. Is dependency ordering correct (service_healthy conditions)?
5. Are graceful shutdown periods set for stateful services?
6. Is log rotation configured?
7. Are image versions pinned (no :latest)?
8. Is the .env / secrets strategy sound?
9. Are there any cross-platform gotchas?
10. What's missing from a disaster recovery perspective?

[paste your docker-compose.yml]
```

### 19.3 Phase 3 — Deployment & Debugging

**Prompt: Pre-deployment validation**
```
I'm about to deploy this Docker Compose stack. Generate a pre-deployment
checklist and the exact commands to:

1. Validate the compose file syntax
2. Pull all images and verify they exist
3. Check host prerequisites (disk space, cgroups, kernel modules)
4. Create required directories with correct permissions
5. Create required secrets files
6. Start services in the correct order
7. Verify all healthchecks pass
8. Confirm resource limits are enforced
9. Test network isolation (container A cannot reach container B)
10. Verify log rotation is working

Platform: [Linux/macOS/Windows]
```

**Prompt: Debug a failing service**
```
My Docker container [name] is [describe the problem: crash looping /
unhealthy / can't connect / permission denied / OOM killed].

Here's the relevant information:
- docker logs output: [paste last 50 lines]
- docker inspect output: [paste relevant sections]
- docker stats output: [paste]
- Compose file for this service: [paste]

Diagnose the issue and provide the fix. Consider:
1. Resource limits (is it OOM killed?)
2. Permissions (is it running as the right user?)
3. Capabilities (does it need caps that were dropped?)
4. Network (can it reach its dependencies?)
5. Volumes (are paths correct, permissions right?)
6. Healthcheck (is the check itself wrong?)
7. Image compatibility (does this version work on my architecture?)
```

### 19.4 Phase 4 — Testing

**Prompt: Generate test plan**
```
Generate a comprehensive test plan for this Docker Compose stack.
For each service, provide the exact commands to verify:

1. FUNCTIONAL: Service starts and serves its purpose
2. HEALTH: Healthcheck passes consistently
3. SECURITY: Capabilities are dropped, filesystem is read-only, non-root
4. RESOURCE: Memory and CPU limits are enforced
5. NETWORK: Service can only reach its intended peers
6. PERSISTENCE: Data survives container restart
7. RECOVERY: Service recovers from crash (restart policy works)
8. BACKUP: Data can be backed up and restored
9. UPDATE: Service can be updated without data loss
10. ROLLBACK: Previous version can be restored

[paste your docker-compose.yml]
```

**Prompt: Stress testing**
```
Generate commands to stress test this Docker Compose stack:

1. Memory pressure: verify containers are killed at their mem_limit, not before
2. CPU saturation: verify cpus limit prevents host starvation
3. PID exhaustion: verify pids_limit prevents fork bombs
4. Disk pressure: verify log rotation prevents disk fill
5. Network partition: verify services handle dependency unavailability
6. Rapid restart: verify restart policy and healthcheck recovery
7. Concurrent connections: verify the service handles expected load

Platform: [Linux/macOS/Windows]
Service to stress: [name]
Expected resource limits: [mem_limit, cpus, pids_limit]
```

### 19.5 Phase 5 — Ongoing Maintenance

**Prompt: Update assessment**
```
I'm updating [service] from [old version] to [new version].

Please:
1. Check the changelog/release notes for breaking changes
2. Identify any new environment variables or config changes
3. Check for new CVEs in the target version
4. Recommend whether to update or skip this version
5. Provide the exact commands to update, verify, and rollback if needed
6. Note any changes to resource requirements
```

**Prompt: Stack health review**
```
Review this `docker stats` output and `docker ps` output for issues:

[paste docker stats --no-stream output]
[paste docker ps output]

Check for:
1. Containers using >80% of their memory limit
2. Containers that have restarted recently
3. Unhealthy containers
4. Containers without healthchecks
5. Unexpected resource usage patterns
6. Suggestions for resource limit adjustments
```

---

## 20. Checklist for New Services

When adding any container to a compose stack:

- [ ] Verify image trust level (T1–T4) using the [source verification checklist](#182-pre-adoption-checklist)
- [ ] Scan image for CVEs (`trivy image <image>:<tag>`)
- [ ] Pin to exact version tag (not `:latest`) — verify with `docker pull`
- [ ] Set `mem_limit`, `cpus`, and `pids_limit`
- [ ] Set `stop_grace_period` if the service has persistent state
- [ ] Add `logging: *default-logging`
- [ ] Add `<<: *default-security` (or document the exception)
- [ ] Add healthcheck if HTTP endpoint exists
- [ ] Set `restart: unless-stopped`
- [ ] Assign to the correct network (minimum necessary)
- [ ] Use `${DATA_DIR}` for volume mount paths
- [ ] Mount config volumes as `:ro` where the service only reads
- [ ] Use Docker secrets for passwords (not `.env` or inline)
- [ ] Run as non-root user where possible
- [ ] Set `read_only: true` with `tmpfs` mounts where possible
- [ ] Validate with `docker compose config --quiet`
- [ ] Test the service starts and healthcheck passes

---

## 21. References

- [Docker Compose specification](https://docs.docker.com/reference/compose-file/)
- [CIS Docker Benchmark v1.6](https://www.cisecurity.org/benchmark/docker)
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html)
- [Docker secrets documentation](https://docs.docker.com/compose/how-tos/use-secrets/)
- [Docker Content Trust](https://docs.docker.com/engine/security/trust/) (legacy — being retired for Official Images)
- [Sigstore Cosign](https://docs.sigstore.dev/cosign/overview/) — modern image signature verification
- [Notation / Notary Project](https://notaryproject.dev/) — OCI-native image signing
- [Seccomp security profiles](https://docs.docker.com/engine/security/seccomp/)
- [AppArmor security profiles](https://docs.docker.com/engine/security/apparmor/)
- [Docker socket proxy (Tecnativa)](https://github.com/Tecnativa/docker-socket-proxy)
- [Trivy — container vulnerability scanner](https://github.com/aquasecurity/trivy)
- [Docker Scout — image analysis](https://docs.docker.com/scout/)
- [CycloneDX — SBOM standard](https://cyclonedx.org/)
- [Renovate — automated dependency updates](https://github.com/renovatebot/renovate)

**Other guides in this repo:**
- [Docker Basics](DOCKER-BASICS.md) — intro to Docker & Compose, installation, alternative runtimes
- [Troubleshooting](TROUBLESHOOTING.md) — common gotchas, debugging playbook, cleanup and reset recipes

---

[← Back to README](../README.md)
