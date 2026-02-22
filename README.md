# Docker Compose Field Guide

A practical, opinionated guide to building Docker Compose stacks that are secure, maintainable, and easy to reason about. Whether you're setting up your first container or standardising an existing homelab, this repo gives you a solid foundation to build on — covering everything from initial design through deployment, troubleshooting, and ongoing maintenance.

> **Target:** Docker Engine 24+ with Docker Compose v2 (`docker compose` plugin). Homelab / self-hosted focus — see the [threat model note](docs/BEST-PRACTICES.md) for internet-facing deployments.

---

## Repo Structure

```
├── README.md                              ← You are here
├── CLAUDE.md                              ← Claude Code project instructions
├── AGENTS.md                              ← OpenAI Codex agent instructions
├── docker-compose.yml                     ← Annotated template (copy into your project)
├── .env.example                           ← Environment variable template
├── docs/
│   ├── BEST-PRACTICES.md                  ← Comprehensive best practices (21 sections)
│   ├── DOCKER-BASICS.md                   ← New to Docker? Start here
│   ├── TROUBLESHOOTING.md                 ← Gotchas, debugging, cleanup, reset recipes
│   ├── GLOSSARY.md                        ← Definitions for every Docker/Compose term
│   ├── INDEX.md                           ← Find any topic across all files
│   └── AGENT-SETUP.md                     ← Multi-agent skill pack setup guide
├── .github/
│   ├── copilot-instructions.md            ← GitHub Copilot repo instructions
│   └── workflows/validate.yml             ← CI validation
├── monitoring/
│   ├── docker-compose.yml                 ← Prometheus + Grafana + exporters stack
│   └── prometheus/prometheus.yml          ← Prometheus scrape config template
└── scripts/
    ├── safe-reset.sh                      ← Restart stack without data loss
    ├── hard-reset.sh                      ← Full teardown + rebuild (destroys volumes)
    ├── docker-disk-report.sh              ← Show what Docker is using on disk
    └── prune-unused.sh                    ← Remove unused resources (safe or aggressive)
```

---

## Where to Start

| If you want to... | Read this |
|--------------------|-----------|
| Learn what Docker & Compose are | [DOCKER-BASICS.md](docs/DOCKER-BASICS.md) |
| Set up a new Compose stack properly | [Best Practices](docs/BEST-PRACTICES.md) |
| Fix something that's broken | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |
| Look up a term or concept | [GLOSSARY.md](docs/GLOSSARY.md) |
| Find where a topic is discussed | [INDEX.md](docs/INDEX.md) |
| Copy a ready-made template | [docker-compose.yml](docker-compose.yml) |
| Add monitoring to your stack | [monitoring/](monitoring/) |
| Clean up disk space or reset a stack | [scripts/](scripts/) |
| Use this repo with AI coding agents | [AGENT-SETUP.md](docs/AGENT-SETUP.md) |

---

## Best Practices — Topics Covered

| # | Topic | # | Topic |
|---|-------|---|-------|
| 1 | [Compose File Structure](docs/BEST-PRACTICES.md#1-compose-file-structure) | 12 | [Update Management](docs/BEST-PRACTICES.md#12-update-management) |
| 2 | [Image Management](docs/BEST-PRACTICES.md#2-image-management) | 13 | [Backup & Disaster Recovery](docs/BEST-PRACTICES.md#13-backup--disaster-recovery) |
| 3 | [Security Hardening](docs/BEST-PRACTICES.md#3-security-hardening) | 14 | [Monitoring](docs/BEST-PRACTICES.md#14-monitoring) |
| 4 | [Storage & Volumes](docs/BEST-PRACTICES.md#4-storage--volumes) | 15 | [Cross-Platform Compatibility](docs/BEST-PRACTICES.md#15-cross-platform-compatibility) |
| 5 | [Host Filesystem Setup](docs/BEST-PRACTICES.md#5-host-filesystem-setup) | 16 | [USB & Hardware Devices](docs/BEST-PRACTICES.md#16-usb--hardware-devices) |
| 6 | [Environment & Configuration](docs/BEST-PRACTICES.md#6-environment--configuration) | 17 | [Penetration Testing Readiness](docs/BEST-PRACTICES.md#17-penetration-testing-readiness) |
| 7 | [Networking](docs/BEST-PRACTICES.md#7-networking) | 18 | [Container Source Verification](docs/BEST-PRACTICES.md#18-container-source-verification--supply-chain-security) |
| 8 | [Resource Limits](docs/BEST-PRACTICES.md#8-resource-limits) | 19 | [LLM-Assisted Workflow](docs/BEST-PRACTICES.md#19-llm-assisted-stack-design-workflow) |
| 9 | [Healthchecks & Dependencies](docs/BEST-PRACTICES.md#9-healthchecks--dependencies) | 20 | [Checklist for New Services](docs/BEST-PRACTICES.md#20-checklist-for-new-services) |
| 10 | [Logging](docs/BEST-PRACTICES.md#10-logging) | 21 | [References](docs/BEST-PRACTICES.md#21-references) |
| 11 | [Graceful Shutdown](docs/BEST-PRACTICES.md#11-graceful-shutdown) | | |

---

## Quick Start

```bash
# 1. Clone and use as a reference
git clone https://github.com/UniversalSyntropy/docker-compose-field-guide.git
cd docker-compose-field-guide

# 2. Copy the template into your project
cp docker-compose.yml ~/my-project/docker-compose.yml
cp .env.example ~/my-project/.env

# 3. Create secrets (never committed to git)
mkdir -p ~/my-project/secrets
echo -n "your-password" > ~/my-project/secrets/db_password.txt

# 4. Validate before deploying
cd ~/my-project
docker compose config --quiet

# 5. Deploy
docker compose up -d
```

## Helper Scripts

```bash
# Restart a stack without losing data
./scripts/safe-reset.sh [path/to/docker-compose.yml]

# Full teardown + rebuild (WARNING: deletes volumes)
./scripts/hard-reset.sh [path/to/docker-compose.yml]

# See what Docker is using on disk
./scripts/docker-disk-report.sh

# Remove unused resources (stopped containers, dangling images, etc.)
./scripts/prune-unused.sh              # Safe mode
./scripts/prune-unused.sh --aggressive # Also removes all unused images + volumes
```

## Standards

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker) — container isolation, resource limits, capabilities
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html) — secrets, images, networking
- [Docker Compose specification](https://docs.docker.com/reference/compose-file/) — authoritative reference for all directives

## License

[MIT](LICENSE)
