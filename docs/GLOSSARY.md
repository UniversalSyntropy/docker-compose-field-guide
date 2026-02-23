# Glossary

Plain-English definitions for every Docker and Compose term used in this repo. Terms are alphabetical. Each heading is a link anchor — other documents link directly here.

> **Tip:** Use your browser's find (`Ctrl+F` / `Cmd+F`) to jump to any term.

---

### Anonymous volume

A volume Docker creates automatically when a container declares a `VOLUME` in its Dockerfile but no named volume or bind mount is mapped to it. Anonymous volumes get a random ID and are easy to lose track of. Prefer [named volumes](#named-volume) or [bind mounts](#bind-mount) instead.

### Bind mount

A direct mapping from a folder on your host machine into a container. You control the exact path on both sides. Good for config files and data you want to access directly from the host.
```yaml
volumes:
  - /mnt/data/app:/app/data        # host path : container path
  - ./config.yml:/app/config.yml:ro  # relative path, read-only
```
See [Storage & Volumes](BEST-PRACTICES.md#4-storage--volumes).

### Bridge network

The default network type for Compose stacks. Each bridge network is isolated — containers on the same bridge can talk to each other by [service](#service) name, but containers on different bridges cannot (unless they share a network). See [Networking](BEST-PRACTICES.md#7-networking).

### Build cache

Cached layers from previous `docker build` runs. Speeds up rebuilds but accumulates on disk. Clear with `docker builder prune`. See [Cleanup and Prune Strategy](TROUBLESHOOTING.md#4-cleanup-and-prune-strategy).

### cAdvisor

**Container Advisor** — a tool by Google that collects resource usage metrics (CPU, memory, network, disk I/O) from running containers. Feeds data to [Prometheus](#prometheus). See [Monitoring](BEST-PRACTICES.md#14-monitoring).

### Capabilities (Linux)

Fine-grained permissions that break down what "root" can do. Docker best practice is to drop all capabilities (`cap_drop: [ALL]`) and add back only the specific ones a service needs (`cap_add:`). See [Security Hardening](BEST-PRACTICES.md#3-security-hardening).

### CIS Docker Benchmark

A security standard published by the Center for Internet Security.
Defines controls like "drop all capabilities" (5.3), "set memory limits" (5.10), and "block privilege escalation" (5.25).
This repo references CIS controls throughout. See [Penetration Testing Readiness](BEST-PRACTICES.md#17-penetration-testing-readiness).

### Compose file

The YAML file (usually `docker-compose.yml`) that defines your entire stack — services, networks, volumes, secrets, and configuration. It's the single source of truth for how your stack runs. See [Compose File Structure](BEST-PRACTICES.md#1-compose-file-structure).

### Compose project

A group of containers, networks, and volumes managed together by Compose.
The **project name** (derived from the directory name, `name:` key, or `COMPOSE_PROJECT_NAME`) determines how resources are grouped.
Changing it creates a completely separate stack. See [Docker Basics — Project](DOCKER-BASICS.md#project-compose-term).

### Container

A running instance of an [image](#image). Lightweight, isolated, and disposable. When a container is removed, anything not stored in a [volume](#volume) is lost. You can run multiple containers from the same image. See [Docker Basics — Container](DOCKER-BASICS.md#container).

### Container name

An optional fixed name for a container (`container_name:` in Compose). Makes logs and commands easier to read, but prevents scaling and can cause naming collisions across stacks. Omit it unless tooling requires a stable name.

### Dangling image

An image with no tag — usually a leftover from a rebuild where the old layers were replaced. Safe to remove. Clear with `docker image prune`. See [Cleanup and Prune Strategy](TROUBLESHOOTING.md#4-cleanup-and-prune-strategy).

### depends_on

A Compose key that controls startup order. With `condition: service_healthy`, Compose waits for the dependency's [healthcheck](#healthcheck) to pass before starting the dependent service. See [Healthchecks & Dependencies](BEST-PRACTICES.md#9-healthchecks--dependencies).

### Docker Compose

A tool for defining and running multi-container applications from a single YAML file. The modern version is the Go-based `docker compose` plugin (v2). The older Python-based `docker-compose` (v1) is deprecated. See [Docker Basics](DOCKER-BASICS.md#what-is-docker-compose).

### Docker Desktop

A GUI application for running Docker on macOS and Windows. Includes Docker Engine, Compose, and a VM to run Linux containers. Has commercial licensing terms for larger organisations. See [Docker Basics — Installing Docker](DOCKER-BASICS.md#installing-docker).

### Docker Engine

The core runtime that builds and runs containers. On Linux, it runs natively. On macOS/Windows, it runs inside a lightweight VM via [Docker Desktop](#docker-desktop) or alternatives. See [Docker Basics](DOCKER-BASICS.md#what-is-docker).

### Docker Hub

The default public [registry](#registry) for container images. Hosts official images (like `postgres`, `nginx`) and community images. See [Image Management](BEST-PRACTICES.md#2-image-management).

### Docker secrets

A mechanism for injecting sensitive data (passwords, tokens, API keys) into containers via files at `/run/secrets/`. Keeps secrets out of environment variables, compose files, and git history. See [Secrets Management](BEST-PRACTICES.md#36-secrets-management).

### Docker socket

The Unix socket file (`/var/run/docker.sock`) that provides API access to the Docker daemon. Mounting it into a container gives that container **full root-equivalent access** to the host. See [Docker Socket Safety](BEST-PRACTICES.md#35-docker-socket-safety).

### Environment variable

A key-value pair passed to a container at startup. Used for non-sensitive configuration. Defined in the Compose file (`environment:`), an `.env` file, or via CLI. See [Environment & Configuration](BEST-PRACTICES.md#6-environment--configuration).

### Extension field

A YAML key prefixed with `x-` in a Compose file. Compose ignores these keys, making them useful for defining reusable blocks with [YAML anchors](#yaml-anchor). Example: `x-logging`, `x-security`. See [YAML Anchors & Extension Fields](BEST-PRACTICES.md#12-yaml-anchors--extension-fields).

### Grafana

An open-source dashboard and visualisation platform. Connects to data sources like [Prometheus](#prometheus) to display metrics as graphs, gauges, and alerts. See the [monitoring stack](../monitoring/docker-compose.yml).

### Healthcheck

A command that runs periodically inside a container to verify the service is working.
If the check fails repeatedly, the container is marked **unhealthy**.
Other services can wait for healthy status using [depends_on](#depends_on). See [Healthchecks & Dependencies](BEST-PRACTICES.md#9-healthchecks--dependencies).

### Host network

A network mode where the container shares the host's network stack directly — no port mapping needed, but no network isolation either. Required for protocols like mDNS and SSDP. Only works properly on Linux. See [Host Network Mode](BEST-PRACTICES.md#74-host-network-mode).

### Image

A packaged application template. Think of it as a recipe — a [container](#container) is a dish made from that recipe. Images are pulled from a [registry](#registry) and identified by name and [tag](#image-tag). See [Docker Basics — Image](DOCKER-BASICS.md#image).

### Image tag

A label that identifies a specific version of an image (e.g., `postgres:16.6`). Always pin to exact version tags in production — never use `:latest`. See [Image Pinning](BEST-PRACTICES.md#21-image-pinning).

### init (tini)

A lightweight init process added as PID 1 in a container when `init: true` is set. Properly forwards signals and reaps zombie processes. Useful for containers with shell-based entrypoints. See [Init Process](BEST-PRACTICES.md#113-init-process-init-true).

### Logging driver

The mechanism Docker uses to handle container logs. The default `json-file` driver stores logs as JSON on disk. Always configure rotation (`max-size`, `max-file`) to prevent disk exhaustion. See [Logging](BEST-PRACTICES.md#10-logging).

### Macvlan

A network driver that gives a container its own IP address on your physical LAN — the container appears as a separate device on the network. Useful for services that need to be discoverable by other LAN devices. See [Networking](BEST-PRACTICES.md#71-network-types).

### Named volume

A Docker-managed storage volume with a human-readable name. Persists across container restarts and recreations. Better performance than [bind mounts](#bind-mount) on macOS/Windows. See [Storage & Volumes](BEST-PRACTICES.md#4-storage--volumes).

### Node Exporter

A Prometheus exporter that collects host system metrics — CPU, memory, disk, network. Only provides meaningful data on Linux (on macOS/Windows it reports VM metrics). See the [monitoring stack](../monitoring/docker-compose.yml).

### no-new-privileges

A security option (`security_opt: [no-new-privileges:true]`) that prevents processes inside the container from gaining additional privileges via `setuid` or `setgid` binaries. CIS Benchmark control 5.25. See [Security Hardening](BEST-PRACTICES.md#31-mandatory-defaults).

### OOM (Out of Memory)

When a container exceeds its memory limit (`mem_limit`), the Linux kernel kills it. This shows as exit code 137. Set appropriate memory limits and monitor usage. See [Resource Limits](BEST-PRACTICES.md#8-resource-limits).

### Orphan container

A container that Compose no longer manages — usually caused by renaming a service, changing the project name, or running from a different directory.
Clean up with `docker compose down --remove-orphans`. See [Troubleshooting — Orphan Containers](TROUBLESHOOTING.md#11-orphan-containers-after-renaming-services).

### Port mapping

Publishing a container's internal port to the host. Format: `"host:container"`. Bind to `127.0.0.1` for local-only access. See [Port Publishing](BEST-PRACTICES.md#75-port-publishing).

### Profile

A Compose feature for defining optional services that only start when explicitly requested with `--profile`. Useful for debug tools, monitoring, or environment-specific services. See [Profiles](BEST-PRACTICES.md#13-profiles).

### Prometheus

An open-source monitoring system that scrapes metrics from targets at regular intervals and stores them as time-series data. The backbone of most Docker monitoring stacks. See [Monitoring](BEST-PRACTICES.md#14-monitoring) and the [monitoring stack](../monitoring/).

### Prune

Docker commands that remove unused resources. Ranges from safe (`docker container prune`) to aggressive (`docker system prune -a --volumes`). See [Cleanup and Prune Strategy](TROUBLESHOOTING.md#4-cleanup-and-prune-strategy).

### read_only

A Compose key (`read_only: true`) that makes the container's root filesystem immutable. Prevents attackers from writing malicious files. Combine with [tmpfs](#tmpfs) for directories that need to be writable. See [Read-Only Root Filesystem](BEST-PRACTICES.md#33-read-only-root-filesystem).

### Registry

A service that stores and distributes container images. [Docker Hub](#docker-hub) is the default public registry. Others include GitHub Container Registry (ghcr.io), Quay.io, and private registries.

### Restart policy

Controls what happens when a container stops. `unless-stopped` restarts the container unless you explicitly stop it — the recommended default. See the [Checklist for New Services](BEST-PRACTICES.md#20-checklist-for-new-services).

### SBOM (Software Bill of Materials)

A machine-readable inventory of all software components in an image. Generated with tools like Trivy or Syft. Used for vulnerability tracking and compliance. See [Security Scanning](BEST-PRACTICES.md#183-security-scanning).

### Service

A named container definition in a Compose file. Each service describes one container — its image, ports, volumes, environment, and configuration. Multiple services form a stack. See [Docker Basics — Service](DOCKER-BASICS.md#service-compose-term).

### SNMP Exporter

A Prometheus exporter that acts as a proxy for querying SNMP-enabled network devices (routers, switches, access points). See the [monitoring stack](../monitoring/).

### stop_grace_period

The time Docker waits after sending SIGTERM before sending SIGKILL to a container. Set this higher for stateful services (databases, message brokers) to allow clean shutdown. See [Graceful Shutdown](BEST-PRACTICES.md#11-graceful-shutdown).

### tmpfs

A temporary filesystem stored in RAM (not on disk). Used with `read_only: true` to provide writable directories (`/tmp`, `/run`) without compromising filesystem immutability. Data is lost when the container stops. See [Read-Only Root Filesystem](BEST-PRACTICES.md#33-read-only-root-filesystem).

### Ulimits

Per-container resource limits for things like open files (`nofile`), processes (`nproc`), and locked memory (`memlock`). Important for databases and high-concurrency services. See [Ulimits](BEST-PRACTICES.md#85-ulimits).

### Volume

Persistent storage that survives container restarts and recreations.
Comes in three forms: [bind mounts](#bind-mount), [named volumes](#named-volume), and [anonymous volumes](#anonymous-volume).
Without a volume, all data inside a container is lost when it's removed. See [Storage & Volumes](BEST-PRACTICES.md#4-storage--volumes).

### Watchtower

A container that monitors your running containers and automatically updates them when new images are available. Can be configured to update all containers or only specific ones via labels. See [Update Management](BEST-PRACTICES.md#12-update-management).

### YAML anchor

A YAML feature (`&name` to define, `*name` to reference) that lets you reuse configuration blocks. Combined with [extension fields](#extension-field) (`x-` prefix) in Compose files to avoid repetition. See [YAML Anchors & Extension Fields](BEST-PRACTICES.md#12-yaml-anchors--extension-fields).

---

## AI Agent Terms

### AGENTS.md

An instruction file read by OpenAI Codex before doing work. The Codex equivalent of [CLAUDE.md](#claudemd). Contains project standards, safe commands, and workflow rules. See [Agent Setup — Codex](AGENT-SETUP.md#52-openai-codex).

### CLAUDE.md

A project instruction file for Claude Code. Defines project scope, standards, safety rules, and references to documentation. Loaded automatically when Claude Code works in the repo. See [Agent Setup — Claude Code](AGENT-SETUP.md#51-claude-code).

### Skill pack

A set of instruction files, checklists, and prompt templates that teach AI coding agents your project's standards. This repo can be used as a skill pack for multiple tools — see [Agent Setup](AGENT-SETUP.md).

---

[← Back to README](../README.md)
