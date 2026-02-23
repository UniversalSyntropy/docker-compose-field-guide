# Docker & Docker Compose — Quick Start Guide

A plain-English introduction to Docker and Docker Compose for people setting up their first stack.
If you already know what containers are, skip to [Docker Compose](#what-is-docker-compose) or go straight to the [best practices](BEST-PRACTICES.md).
See also the [glossary](GLOSSARY.md) for quick definitions of any term.

---

## Table of Contents

1. [What Is Docker?](#what-is-docker)
2. [What Problem Does It Solve?](#what-problem-does-it-solve)
3. [What Is Docker Compose?](#what-is-docker-compose)
4. [Core Concepts](#core-concepts)
5. [What a Typical Stack Looks Like](#what-a-typical-stack-looks-like)
6. [Quick Start Workflow](#quick-start-workflow)
7. [Installing Docker](#installing-docker)
8. [Alternative Container Runtimes](#alternative-container-runtimes)
9. [Which Option Should I Choose?](#which-option-should-i-choose)
10. [Official Resources](#official-resources)

---

## What Is Docker?

Docker is a platform for running applications in **containers** — lightweight, isolated environments that package your app together with everything it needs (code, libraries, config, runtime). A container is like a tiny purpose-built machine that runs one service.

**Key mental model:**
- An **image** is a template (like a recipe)
- A **container** is a running instance of that image (like a dish made from the recipe)

## What Problem Does It Solve?

Without containers, people regularly hit:

| Problem | What Happens |
|---------|-------------|
| "Works on my machine" | App runs locally but breaks on the server |
| Version conflicts | Python 3.10 needed here, 3.12 needed there |
| Painful setup | 20-step install guide that's always slightly wrong |
| Inconsistent environments | Dev, test, and production behave differently |
| Messy upgrades | Updating one thing breaks three other things |
| Difficult rollbacks | "Can we go back to yesterday's version?" |

Docker fixes this by making the runtime environment **repeatable and portable**. If it runs in the container, it runs the same way everywhere.

## What Is Docker Compose?

Docker Compose is the tool for defining and running **multi-container applications** using a single YAML file. Instead of manually running separate commands for each service, you describe your entire stack once and run:

```bash
docker compose up -d
```

**What Compose fixes:** the "too many commands / too many moving parts" problem. Instead of manually creating networks, volumes, environment variables, and startup order for each container, you define it all in one file.

**Key idea:**
- **Docker** = container runtime + image tooling
- **Compose** = orchestration for local and small deployments using a YAML file
- Compose is not just a shortcut — it becomes your **source of truth** for how a stack runs

## Core Concepts

### Image

A packaged application template pulled from a registry (e.g., Docker Hub). Examples: `nginx`, `postgres:16.6`, `grafana/grafana:12.3.3`.

### Container

A running instance of an image. You can have multiple containers from the same image. Containers are ephemeral — when removed, any data not stored in a volume is lost.

### Volume

Persistent storage that survives container recreation. Without volumes, all data inside a container disappears when the container is removed.

```yaml
volumes:
  - /mnt/data/postgres:/var/lib/postgresql/data    # Bind mount (host path)
  - db-data:/var/lib/postgresql/data                # Named volume (Docker-managed)
```

### Network

A private network for containers to communicate. Containers on the same network can reach each other by service name (e.g., `database:5432`). Containers on different networks are isolated from each other.

```yaml
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
```

### Service (Compose term)

A named container definition in your compose file. Each service describes one container: its image, ports, volumes, environment variables, and configuration.

```yaml
services:
  app:        # This is a service
    image: your-app:1.0.0
  database:   # This is another service
    image: postgres:16.6
```

### Project (Compose term)

A whole stack of services managed together. Compose groups all resources (containers, networks, volumes) by **project name** — derived from the directory name by default, or set explicitly with `name:` in the compose file or `COMPOSE_PROJECT_NAME` in `.env`.

> **Gotcha:** If you run the same compose file from a different directory (or with a different `-p` flag), Compose treats it as a separate project and creates duplicate containers. This is the #1 cause of "phantom containers" and port conflicts.

## What a Typical Stack Looks Like

Most Docker Compose stacks follow a pattern like this:

```
                    ┌─────────────┐
                    │   proxy     │  ← Reverse proxy (Nginx, Traefik, Caddy)
                    │  :80/:443   │
                    └──────┬──────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
        ┌─────┴─────┐ ┌───┴───┐ ┌──────┴──────┐
        │    app     │ │  api  │ │   worker    │  ← Application services
        │   :8080    │ │ :3000 │ │ (no ports)  │
        └─────┬──────┘ └───┬───┘ └──────┬──────┘
              │            │            │
        ┌─────┴────────────┴────────────┴─────┐
        │              backend network         │
        └─────┬────────────┬──────────────────┘
              │            │
        ┌─────┴─────┐ ┌───┴───┐
        │  database  │ │ cache │  ← Data services
        │   :5432    │ │ :6379 │
        └───────────┘ └───────┘
```

Common components:
- **App / API** — your application
- **Database** — PostgreSQL, MySQL, MongoDB
- **Cache** — Redis, Memcached
- **Proxy** — Nginx, Traefik, Caddy
- **Worker** — background job processors
- **Monitoring** — Prometheus, Grafana

## Quick Start Workflow

```bash
# 1. Install Docker (see next section)

# 2. Create a project directory
mkdir my-stack && cd my-stack

# 3. Create a docker-compose.yml file
#    (copy the template from this repo, or write your own)

# 4. Create an environment file
cp .env.example .env
# Edit .env with your values

# 5. Create secrets
mkdir -p secrets
echo -n "your-db-password" > secrets/db_password.txt

# 6. Validate before deploying
docker compose config --quiet

# 7. Start everything
docker compose up -d

# 8. Check status
docker compose ps

# 9. View logs
docker compose logs -f app

# 10. Stop everything
docker compose down
```

## Installing Docker

### Linux (recommended for production/homelab)

Install Docker Engine + Compose plugin directly:

```bash
# Official install script (Debian, Ubuntu, Fedora, etc.)
curl -fsSL https://get.docker.com | sh

# Add your user to the docker group (avoids needing sudo)
sudo usermod -aG docker $USER
# Log out and back in for group change to take effect

# Verify
docker compose version    # Should show v2.x.x
```

> **Raspberry Pi / ARM:** Also add `cgroup_enable=memory` to `/boot/firmware/cmdline.txt` for memory limits to work. See [Section 8](BEST-PRACTICES.md#8-resource-limits) of the best practices doc.

### macOS

Docker Desktop is the easiest option — download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/). Compose is included.

Alternatives: [Colima](#3-colima-macos--linux-cli-first), [OrbStack](#4-orbstack-macos), [Rancher Desktop](#2-rancher-desktop).

> **Note:** Docker on macOS runs containers in a lightweight Linux VM. Bind mount performance, host networking, and USB passthrough behave differently from native Linux. See the [cross-platform section](BEST-PRACTICES.md#15-cross-platform-compatibility) for details.

### Windows

Docker Desktop with WSL2 backend — download from [docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop/). Compose is included.

> **Important:** Store Docker data on the WSL2 filesystem (`/home/...`), **not** on NTFS mounts (`/mnt/c/`). NTFS via 9P is extremely slow and causes permission issues. See [Section 5.3](BEST-PRACTICES.md#53-windows) for details.

> **Note:** Docker Desktop has commercial subscription terms for larger organisations (>250 employees or >$10M revenue). See Docker's pricing page for current terms.

## Alternative Container Runtimes

Docker Desktop is not the only way to run containers. Here are the main alternatives:

### 1. Podman / Podman Desktop

A daemonless, open-source container engine. No background daemon process — each container runs as a direct child process. Podman Desktop provides a GUI.

- **Good for:** rootless/daemonless workflows, security-conscious users, Linux-heavy environments
- **Compose support:** `podman-compose` or `docker compose` via compatibility mode
- **Docs:** [podman.io](https://podman.io/), [podman-desktop.io](https://podman-desktop.io/)

> **Caveat:** Some Compose keys (`mem_limit`, `cpus`, `pids_limit`) may behave differently. Test your stack on Podman before assuming full compatibility.

### 2. Rancher Desktop

Desktop app for container management and local Kubernetes. Supports both containerd/nerdctl and Moby/dockerd as the container runtime.

- **Good for:** users who want built-in local Kubernetes, cross-platform GUI
- **Compose support:** Yes (via dockerd runtime selection)
- **Docs:** [rancherdesktop.io](https://rancherdesktop.io/)

### 3. Colima (macOS / Linux, CLI-first)

Lightweight CLI tool for running container runtimes on macOS. Popular with terminal-first developers who want lower overhead than Docker Desktop.

- **Good for:** Mac users who prefer CLI workflows, lower resource usage
- **Compose support:** Yes (uses Docker Engine under the hood)
- **Docs:** [github.com/abiosoft/colima](https://github.com/abiosoft/colima)

### 4. OrbStack (macOS)

Fast, lightweight container and Linux VM manager for macOS. Positioned as a performance-focused Docker Desktop alternative.

- **Good for:** macOS users wanting a polished, high-performance experience
- **Compose support:** Yes (Docker-compatible)
- **Docs:** [orbstack.dev](https://orbstack.dev/)

### 5. nerdctl + containerd (advanced)

Docker-compatible CLI for containerd. Similar UX to Docker, including `nerdctl compose up` for Compose workflows.

- **Good for:** advanced users, containerd-native environments
- **Compose support:** Yes (`nerdctl compose`)
- **Docs:** [github.com/containerd/nerdctl](https://github.com/containerd/nerdctl)

### 6. Lima (VM layer / building block)

Provides Linux VMs with automatic file sharing and port forwarding. Often used as a building block for other tools (Colima uses Lima under the hood).

- **Good for:** users who want a flexible Linux VM base for custom setups
- **Docs:** [lima-vm.io](https://lima-vm.io/)

## Which Option Should I Choose?

| If you are... | Start with |
|---------------|-----------|
| New to containers | **Docker Desktop** — fastest path, best docs, Compose included |
| Want a Docker Desktop alternative with GUI | **Podman Desktop**, **Rancher Desktop**, or **OrbStack** (macOS) |
| Prefer terminal-first / lightweight | **Colima** (macOS), **Docker Engine** (Linux) |
| Advanced / containerd-native | **nerdctl + containerd** |
| Building a custom setup | **Lima** + your chosen runtime |

## Official Resources

**Docker:**
- [Docker overview ("What is Docker?")](https://docs.docker.com/get-started/docker-overview/)
- [Docker Get Started tutorial](https://docs.docker.com/get-started/)
- [Docker Compose overview](https://docs.docker.com/compose/)
- [Docker Compose quickstart](https://docs.docker.com/compose/gettingstarted/)
- [Install Docker Engine](https://docs.docker.com/engine/install/)
- [Install Docker Compose plugin](https://docs.docker.com/compose/install/)
- [Docker Desktop](https://docs.docker.com/desktop/)

**Alternatives:**
- [Podman](https://podman.io/) / [Podman Desktop](https://podman-desktop.io/)
- [Rancher Desktop](https://rancherdesktop.io/)
- [Colima](https://github.com/abiosoft/colima)
- [OrbStack](https://orbstack.dev/)
- [nerdctl](https://github.com/containerd/nerdctl)
- [Lima](https://lima-vm.io/)

---

## Next Steps

- Ready to build a stack? Follow the [best practices guide](BEST-PRACTICES.md)
- Something broken? See the [troubleshooting guide](TROUBLESHOOTING.md)
- Want a ready-made template? Copy [docker-compose.yml](../docker-compose.yml)

---

[← Back to README](../README.md)
