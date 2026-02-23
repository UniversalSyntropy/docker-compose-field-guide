# Docker Compose Field Guide

> Stop copy-pasting Compose files from Stack Overflow — start with hardened defaults.

A reference for building Docker Compose stacks that are well-structured, security-hardened, and easy to maintain.
Aimed at homelabs and self-hosted setups — the kind of environment where you want things done properly but don't have a dedicated ops team.

> **Requires:** Docker Engine 24+ with Docker Compose v2 (`docker compose` plugin).
>
> **Scope:** Homelab / self-hosted / LAN-facing services.
> If you're exposing services to the internet, this is a reasonable starting point — but you'll also need a reverse proxy with TLS, rate limiting, and stricter network policies.
> See the [threat model note](docs/BEST-PRACTICES.md#3-security-hardening).

---

## Who This Is For

- You run a homelab, NAS, Pi, or small server
- You know basic Linux and have run at least one container before
- You want to do things properly — security, backups, log rotation — without reading the CIS Benchmark end-to-end
- You're tired of Compose files cobbled together from Stack Overflow snippets

**Not the target audience:** Complete Docker beginners (start with [DOCKER-BASICS.md](docs/DOCKER-BASICS.md)), large-scale production, Kubernetes, or Swarm deployments.

---

## What's In Here

- **An annotated [`docker-compose.yml`](docker-compose.yml) template** — copy it into your project. Includes security defaults, log rotation, resource limits, and healthchecks as a starting baseline.
- **[21 sections of best practices](docs/BEST-PRACTICES.md)** — from [network trust zones](docs/BEST-PRACTICES.md#72-network-isolation-by-trust-zone) and [secrets management](docs/BEST-PRACTICES.md#36-secrets-management)
  to [USB passthrough](docs/BEST-PRACTICES.md#16-usb--hardware-devices) and [cross-platform gotchas](docs/BEST-PRACTICES.md#15-cross-platform-compatibility). The WSL2/NTFS warning alone will save you hours.
- **[A troubleshooting guide](docs/TROUBLESHOOTING.md)** — step-by-step [debugging playbook](docs/TROUBLESHOOTING.md#2-debugging-playbook),
  [decision tree](docs/TROUBLESHOOTING.md#6-troubleshooting-decision-tree), and fixes for orphan containers, port conflicts, and data that "disappears" after a recreate.
- **[A monitoring stack](monitoring/)** — Prometheus, Grafana, Node Exporter, and cAdvisor. A reference config you'll want to adapt to your setup (Node Exporter gives meaningful host metrics on Linux only).
- **[Helper scripts](scripts/)** — safe resets, hard resets, disk reports, and pruning. So you don't have to remember the flags.
- **[Glossary](docs/GLOSSARY.md) and [index](docs/INDEX.md)** — look up any term, or find where a topic is discussed across the docs.
- **[AI agent instructions](docs/AGENT-SETUP.md)** — for Claude Code, Copilot, Codex, and Cursor, so your coding tools follow the same standards you do.

**Worth a look:**

| Section | What you get |
|---------|-------------|
| [Image trust framework (T1–T5)](docs/BEST-PRACTICES.md#181-image-trust-framework) | A practical model for deciding whether to trust a container image |
| [Security exceptions table](docs/BEST-PRACTICES.md#39-documenting-security-exceptions) | How to document *why* a service breaks the rules — and what compensates |
| [CIS Benchmark mapping](docs/BEST-PRACTICES.md#17-penetration-testing-readiness) | Security controls mapped to what a pen tester would flag |
| [LLM prompt templates](docs/BEST-PRACTICES.md#19-llm-assisted-stack-design-workflow) | Copy-paste prompts for getting an LLM to design, review, and debug your stack |
| [Cleanup levels (safe → nuclear)](docs/TROUBLESHOOTING.md#4-cleanup-and-prune-strategy) | Five levels of Docker cleanup, from project-scoped to "remove everything" |
| [Capability cheat sheet](docs/BEST-PRACTICES.md#32-capability-management) | Which Linux capabilities each service type actually needs |

---

## Where to Start

| If you want to... | Go here |
|--------------------|---------|
| Learn what Docker & Compose are | [DOCKER-BASICS.md](docs/DOCKER-BASICS.md) |
| Set up a new stack properly | [Best Practices](docs/BEST-PRACTICES.md) |
| Fix something that's broken | [Troubleshooting](docs/TROUBLESHOOTING.md) |
| Look up a term | [Glossary](docs/GLOSSARY.md) |
| Find where a topic is discussed | [Index](docs/INDEX.md) |
| Copy a ready-made template | [docker-compose.yml](docker-compose.yml) |
| Add monitoring | [monitoring/](monitoring/) |
| Clean up disk space or reset a stack | [scripts/](scripts/) |
| Use this with AI coding agents | [Agent Setup](docs/AGENT-SETUP.md) |

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

> The template is a **starting point**, not a drop-in solution. You'll need to swap in your own images, volumes, and secrets. The annotations explain what each block does and why.

---

## What Hardening Looks Like

A naive Compose service vs the same service with this guide's defaults applied:

<details>
<summary><strong>Before — common but fragile</strong></summary>

```yaml
services:
  web:
    image: nginx:latest
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html
    restart: always
```

</details>

<details>
<summary><strong>After — hardened baseline</strong></summary>

```yaml
services:
  web:
    image: nginx:1.27.4                    # Pin to exact version
    security_opt:
      - no-new-privileges:true             # Block privilege escalation
    cap_drop: [ALL]                        # Drop all capabilities
    cap_add:
      - NET_BIND_SERVICE                   # Only what's needed for port 80
    read_only: true                        # Immutable root filesystem
    tmpfs:
      - /tmp
      - /var/cache/nginx
      - /run
    ports:
      - "80:80"
    volumes:
      - ./html:/usr/share/nginx/html:ro    # Read-only bind mount
    mem_limit: 128m                        # Prevent OOM killing neighbours
    cpus: 0.5                              # Prevent CPU starvation
    pids_limit: 100                        # Prevent fork bombs
    restart: unless-stopped                # Respect manual stops
    logging:
      driver: json-file
      options: { max-size: "10m", max-file: "3" }
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 10s
    networks:
      - frontend
```

</details>

Every directive is explained in the [best practices](docs/BEST-PRACTICES.md).
The [annotated template](docker-compose.yml) is a copy-paste starting point.

---

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

## Repo Structure

```
├── README.md                              ← You are here
├── CONTRIBUTING.md                        ← How to contribute
├── SECURITY.md                            ← Security policy
├── CHANGELOG.md                           ← What changed
├── CLAUDE.md                              ← Claude Code project instructions
├── AGENTS.md                              ← OpenAI Codex agent instructions
├── docker-compose.yml                     ← Annotated template (copy into your project)
├── .env.example                           ← Environment variable template
├── Makefile                               ← Local linting (make lint)
├── docs/
│   ├── BEST-PRACTICES.md                  ← Best practices (21 sections)
│   ├── DOCKER-BASICS.md                   ← New to Docker? Start here
│   ├── TROUBLESHOOTING.md                 ← Gotchas, debugging, cleanup, reset recipes
│   ├── GLOSSARY.md                        ← Definitions for every Docker/Compose term
│   ├── INDEX.md                           ← Find any topic across all files
│   ├── STYLE.md                           ← Voice and style guide for contributors
│   └── AGENT-SETUP.md                     ← Multi-agent skill pack setup guide
├── .github/
│   ├── copilot-instructions.md            ← GitHub Copilot repo instructions
│   ├── ISSUE_TEMPLATE/                    ← Bug report and feature request templates
│   ├── PULL_REQUEST_TEMPLATE.md           ← PR checklist
│   └── workflows/validate.yml             ← CI: YAML, Markdown, ShellCheck, line length
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

## Security Approach

This guide follows the [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker) and [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html) as baselines. The defaults are:

- Drop all Linux capabilities, add back only what's needed
- Block privilege escalation (`no-new-privileges`)
- Run as non-root where the image supports it
- Use Docker secrets for passwords (not environment variables)
- Read-only root filesystem where possible

These are **safe defaults for a homelab LAN**. They reduce your attack surface and catch common mistakes.
They are not a complete security architecture — if you're exposing services to the internet, you'll need more (reverse proxy, TLS, WAF, network policies).
The [security hardening section](docs/BEST-PRACTICES.md#3-security-hardening) explains each control, when to relax it, and how to document exceptions.

---

## Trust & Limits

This guide is:

- A **hardened starting point** for homelab and self-hosted stacks
- Based on published standards (CIS Docker Benchmark, OWASP Docker Security)
- Tested with Docker Engine 24+ and Compose v2 on Linux, macOS, and Windows/WSL2

This guide is **not**:

- A substitute for a security audit
- Validated for internet-facing production without additional controls (reverse proxy, TLS, WAF)
- A guarantee — Docker, Compose, and upstream images change; verify against your environment
- Maintained by a security team — it is a community reference

If you find an error or a gap, [open an issue](https://github.com/UniversalSyntropy/docker-compose-field-guide/issues).

---

## Standards

- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker) — container isolation, resource limits, capabilities
- [OWASP Docker Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Docker_Security_Cheat_Sheet.html) — secrets, images, networking
- [Docker Compose specification](https://docs.docker.com/reference/compose-file/) — authoritative reference for all directives

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for how to run checks, what to include in a PR, and what changes are welcome.
Voice and style guidelines are in [STYLE.md](docs/STYLE.md).

## License

[MIT](LICENSE)
