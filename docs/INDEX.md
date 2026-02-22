# Index

A topical index covering every concept across all documents in this repo. Use this to find where a topic is discussed — many topics appear in multiple places.

> **Format:** Each entry links to the specific file and section. **BP** = Best Practices, **TB** = Troubleshooting, **DB** = Docker Basics, **GL** = Glossary.

---

## Getting Started

- What is Docker — [DB: What Is Docker?](DOCKER-BASICS.md#what-is-docker)
- What is Docker Compose — [DB: What Is Docker Compose?](DOCKER-BASICS.md#what-is-docker-compose)
- Core concepts (image, container, volume, network) — [DB: Core Concepts](DOCKER-BASICS.md#core-concepts)
- Typical stack architecture — [DB: What a Typical Stack Looks Like](DOCKER-BASICS.md#what-a-typical-stack-looks-like)
- Quick start workflow — [DB: Quick Start](DOCKER-BASICS.md#quick-start-workflow)
- Installing Docker (Linux, macOS, Windows) — [DB: Installing Docker](DOCKER-BASICS.md#installing-docker)
- Alternative runtimes (Podman, Colima, OrbStack, etc.) — [DB: Alternative Container Runtimes](DOCKER-BASICS.md#alternative-container-runtimes)

## Compose File

- File organisation (top-level keys) — [BP: 1.1](BEST-PRACTICES.md#11-file-organisation)
- YAML anchors & extension fields — [BP: 1.2](BEST-PRACTICES.md#12-yaml-anchors--extension-fields) | [GL: YAML anchor](GLOSSARY.md#yaml-anchor) | [GL: Extension field](GLOSSARY.md#extension-field)
- Profiles — [BP: 1.3](BEST-PRACTICES.md#13-profiles) | [GL: Profile](GLOSSARY.md#profile)
- Compose version key — [BP: 1.4](BEST-PRACTICES.md#14-compose-version)
- Annotated template — [docker-compose.yml](../docker-compose.yml)
- Validation (`docker compose config`) — [TB: Step 1](TROUBLESHOOTING.md#step-1-validate-the-compose-file)
- Changes not taking effect — [TB: Common Errors](TROUBLESHOOTING.md#changes-to-compose-file-not-taking-effect)

## Images

- Image pinning (exact tags, never `:latest`) — [BP: 2.1](BEST-PRACTICES.md#21-image-pinning) | [GL: Image tag](GLOSSARY.md#image-tag)
- Tag mismatch gotcha — [BP: 2.1](BEST-PRACTICES.md#21-image-pinning)
- Multi-architecture images — [BP: 2.2](BEST-PRACTICES.md#22-multi-architecture-images)
- Image provenance — [BP: 2.3](BEST-PRACTICES.md#23-image-provenance)
- Image trust framework (T1–T5) — [BP: 18.1](BEST-PRACTICES.md#181-image-trust-framework)
- Pre-adoption checklist — [BP: 18.2](BEST-PRACTICES.md#182-pre-adoption-checklist)
- Security scanning (Trivy, Docker Scout) — [BP: 18.3](BEST-PRACTICES.md#183-security-scanning)
- Supply chain protection (Cosign, digest pinning) — [BP: 18.5](BEST-PRACTICES.md#185-supply-chain-protection)
- "image not found" error — [TB: Common Errors](TROUBLESHOOTING.md#image-not-found-or-manifest-unknown)
- Dangling images — [GL: Dangling image](GLOSSARY.md#dangling-image) | [TB: Cleanup](TROUBLESHOOTING.md#4-cleanup-and-prune-strategy)

## Security

- Mandatory defaults (cap_drop, no-new-privileges) — [BP: 3.1](BEST-PRACTICES.md#31-mandatory-defaults)
- Capability management — [BP: 3.2](BEST-PRACTICES.md#32-capability-management) | [GL: Capabilities](GLOSSARY.md#capabilities-linux)
- Read-only root filesystem — [BP: 3.3](BEST-PRACTICES.md#33-read-only-root-filesystem) | [GL: read_only](GLOSSARY.md#read_only)
- Run as non-root — [BP: 3.4](BEST-PRACTICES.md#34-run-as-non-root)
- Docker socket safety — [BP: 3.5](BEST-PRACTICES.md#35-docker-socket-safety) | [GL: Docker socket](GLOSSARY.md#docker-socket)
- Secrets management — [BP: 3.6](BEST-PRACTICES.md#36-secrets-management) | [GL: Docker secrets](GLOSSARY.md#docker-secrets)
- Network segmentation — [BP: 3.7](BEST-PRACTICES.md#37-network-segmentation) | [BP: 7.2](BEST-PRACTICES.md#72-network-isolation-by-trust-zone)
- AppArmor and Seccomp — [BP: 3.8](BEST-PRACTICES.md#38-apparmor-and-seccomp)
- Documenting security exceptions — [BP: 3.9](BEST-PRACTICES.md#39-documenting-security-exceptions)
- CIS Docker Benchmark mapping — [BP: 17.1](BEST-PRACTICES.md#171-container-isolation-cis-docker-benchmark)
- Pen test readiness — [BP: 17](BEST-PRACTICES.md#17-penetration-testing-readiness)
- Daemon-level hardening — [BP: 17.7](BEST-PRACTICES.md#177-additional-hardening)

## Storage & Volumes

- Bind mounts vs named volumes — [BP: 4.1](BEST-PRACTICES.md#41-bind-mounts-vs-named-volumes) | [GL: Bind mount](GLOSSARY.md#bind-mount) | [GL: Named volume](GLOSSARY.md#named-volume)
- Volume mount patterns — [BP: 4.2](BEST-PRACTICES.md#42-volume-mount-patterns)
- Mount permissions and flags (:ro, :z, :cached) — [BP: 4.3](BEST-PRACTICES.md#43-mount-permissions-and-flags)
- Directory layout — [BP: 4.4](BEST-PRACTICES.md#44-recommended-directory-layout)
- File ownership (UID/GID) — [BP: 4.5](BEST-PRACTICES.md#45-file-ownership)
- Data "disappeared" after recreate — [TB: 1.4](TROUBLESHOOTING.md#14-data-disappeared-after-recreate)
- Volume permissions debugging — [TB: Step 8](TROUBLESHOOTING.md#step-8-check-volumes-and-permissions)
- tmpfs — [GL: tmpfs](GLOSSARY.md#tmpfs)
- Anonymous volumes — [GL: Anonymous volume](GLOSSARY.md#anonymous-volume)

## Host Filesystem

- Linux setup (ext4, XFS, fstab) — [BP: 5.1](BEST-PRACTICES.md#51-linux)
- macOS (VirtioFS, performance) — [BP: 5.2](BEST-PRACTICES.md#52-macos)
- Windows (WSL2, NTFS gotchas) — [BP: 5.3](BEST-PRACTICES.md#53-windows)
- FreeBSD / Unix — [BP: 5.4](BEST-PRACTICES.md#54-freebsd--unix)
- Raspberry Pi / SBC notes — [BP: 5.1](BEST-PRACTICES.md#51-linux)

## Environment & Configuration

- The .env file — [BP: 6.1](BEST-PRACTICES.md#61-the-env-file) | [GL: Environment variable](GLOSSARY.md#environment-variable)
- Variable precedence — [BP: 6.2](BEST-PRACTICES.md#62-environment-variable-precedence)
- Sensitive vs non-sensitive config — [BP: 6.3](BEST-PRACTICES.md#63-sensitive-vs-non-sensitive-config)
- Docker configs — [BP: 6.4](BEST-PRACTICES.md#64-docker-configs-read-only-files)
- .env.example template — [.env.example](../.env.example)

## Networking

- Network types (bridge, host, none, macvlan) — [BP: 7.1](BEST-PRACTICES.md#71-network-types) | [GL: Bridge network](GLOSSARY.md#bridge-network) | [GL: Host network](GLOSSARY.md#host-network)
- Network isolation by trust zone — [BP: 7.2](BEST-PRACTICES.md#72-network-isolation-by-trust-zone)
- Internal networks — [BP: 7.3](BEST-PRACTICES.md#73-internal-networks)
- Host network mode — [BP: 7.4](BEST-PRACTICES.md#74-host-network-mode)
- Port publishing — [BP: 7.5](BEST-PRACTICES.md#75-port-publishing) | [GL: Port mapping](GLOSSARY.md#port-mapping)
- Service can't connect to another service — [TB: 1.7](TROUBLESHOOTING.md#17-service-cant-connect-to-another-service)
- "network not found" error — [TB: Common Errors](TROUBLESHOOTING.md#network--not-found)
- Connectivity debugging — [TB: Step 7](TROUBLESHOOTING.md#step-7-check-networking)
- Port conflicts — [TB: 1.5](TROUBLESHOOTING.md#15-port-conflicts-address-already-in-use) | [TB: Common Errors](TROUBLESHOOTING.md#port-is-already-allocated)

## Resource Limits

- Mandatory limits (mem_limit, cpus, pids_limit) — [BP: 8.1](BEST-PRACTICES.md#81-mandatory-limits)
- Sizing guidelines — [BP: 8.2](BEST-PRACTICES.md#82-sizing-guidelines)
- Memory reservation vs limit — [BP: 8.3](BEST-PRACTICES.md#83-memory-reservation-vs-limit)
- Verifying limits — [BP: 8.4](BEST-PRACTICES.md#84-verifying-limits-are-enforced)
- Ulimits — [BP: 8.5](BEST-PRACTICES.md#85-ulimits) | [GL: Ulimits](GLOSSARY.md#ulimits)
- OOM kills (exit code 137) — [GL: OOM](GLOSSARY.md#oom-out-of-memory) | [TB: Step 5](TROUBLESHOOTING.md#step-5-inspect-container-state)

## Healthchecks & Dependencies

- Healthcheck configuration — [BP: 9.1](BEST-PRACTICES.md#91-healthcheck-configuration) | [GL: Healthcheck](GLOSSARY.md#healthcheck)
- Healthcheck patterns by service type — [BP: 9.2](BEST-PRACTICES.md#92-healthcheck-patterns-by-service-type)
- CMD vs CMD-SHELL — [BP: 9.3](BEST-PRACTICES.md#93-cmd-vs-cmd-shell)
- Dependency ordering — [BP: 9.4](BEST-PRACTICES.md#94-dependency-ordering) | [GL: depends_on](GLOSSARY.md#depends_on)
- Healthcheck debugging — [TB: Step 6](TROUBLESHOOTING.md#step-6-check-healthchecks)
- Healthcheck failures (decision tree) — [TB: Decision Tree](TROUBLESHOOTING.md#6-troubleshooting-decision-tree)

## Logging

- Log rotation (max-size, max-file) — [BP: 10.1](BEST-PRACTICES.md#101-log-rotation) | [GL: Logging driver](GLOSSARY.md#logging-driver)
- Daemon-level default — [BP: 10.2](BEST-PRACTICES.md#102-alternative-daemon-level-default)
- Log drivers (json-file, local, syslog, fluentd) — [BP: 10.3](BEST-PRACTICES.md#103-log-drivers)
- Checking logs for errors — [TB: Step 4](TROUBLESHOOTING.md#step-4-check-logs)

## Graceful Shutdown

- Stop grace period — [BP: 11.1](BEST-PRACTICES.md#111-stop-grace-period) | [GL: stop_grace_period](GLOSSARY.md#stop_grace_period)
- Stop signal — [BP: 11.2](BEST-PRACTICES.md#112-stop-signal)
- Init process (tini) — [BP: 11.3](BEST-PRACTICES.md#113-init-process-init-true) | [GL: init](GLOSSARY.md#init-tini)
- Signal handling in Dockerfiles — [BP: 11.4](BEST-PRACTICES.md#114-signal-handling-in-dockerfiles)

## Updates & Maintenance

- Watchtower (automatic updates) — [BP: 12.1](BEST-PRACTICES.md#121-automatic-updates-with-watchtower) | [GL: Watchtower](GLOSSARY.md#watchtower)
- Selective updates (opt-in/opt-out) — [BP: 12.2](BEST-PRACTICES.md#122-selective-updates)
- Manual update procedure — [BP: 12.3](BEST-PRACTICES.md#123-manual-update-procedure)
- Rollback — [BP: 12.4](BEST-PRACTICES.md#124-rollback)
- Version pinning policy — [BP: 18.4](BEST-PRACTICES.md#184-version-pinning-policy)

## Backup & Recovery

- What to protect (priority, RPO) — [BP: 13.1](BEST-PRACTICES.md#131-what-to-protect)
- Backup tiers (git, tar, database dumps, full disk) — [BP: 13.2](BEST-PRACTICES.md#132-backup-tiers)
- Recovery procedures — [BP: 13.3](BEST-PRACTICES.md#133-recovery-procedures)
- Testing backups — [BP: 13.4](BEST-PRACTICES.md#134-testing-backups)
- Data loss after restart — [TB: 1.4](TROUBLESHOOTING.md#14-data-disappeared-after-recreate) | [TB: Decision Tree](TROUBLESHOOTING.md#6-troubleshooting-decision-tree)

## Monitoring

- Quick health commands — [BP: 14.1](BEST-PRACTICES.md#141-quick-health-commands)
- Alert thresholds — [BP: 14.2](BEST-PRACTICES.md#142-recommended-alert-thresholds)
- Monitoring stack components — [BP: 14.3](BEST-PRACTICES.md#143-monitoring-stack)
- Prometheus config — [monitoring/prometheus/prometheus.yml](../monitoring/prometheus/prometheus.yml)
- Full stack example — [monitoring/docker-compose.yml](../monitoring/docker-compose.yml)

## Cross-Platform

- Feature matrix (Linux vs macOS vs Windows) — [BP: 15.1](BEST-PRACTICES.md#151-feature-matrix)
- What works everywhere — [BP: 15.2](BEST-PRACTICES.md#152-what-works-everywhere)
- Linux-only features — [BP: 15.3](BEST-PRACTICES.md#153-linux-only-for-production)
- Works on Linux, broken on Docker Desktop — [TB: 1.6](TROUBLESHOOTING.md#16-works-on-linux-brokenslow-on-docker-desktop)
- Alternative runtimes — [DB: Alternative Container Runtimes](DOCKER-BASICS.md#alternative-container-runtimes)
- USB / hardware devices — [BP: 16](BEST-PRACTICES.md#16-usb--hardware-devices)

## Troubleshooting

- Orphan containers — [TB: 1.1](TROUBLESHOOTING.md#11-orphan-containers-after-renaming-services) | [GL: Orphan container](GLOSSARY.md#orphan-container)
- Duplicate containers — [TB: 1.2](TROUBLESHOOTING.md#12-duplicate-containers-from-different-project-names)
- Incomplete cleanup — [TB: 1.3](TROUBLESHOOTING.md#13-docker-compose-down-did-not-remove-everything)
- Data loss — [TB: 1.4](TROUBLESHOOTING.md#14-data-disappeared-after-recreate)
- Port conflicts — [TB: 1.5](TROUBLESHOOTING.md#15-port-conflicts-address-already-in-use)
- Docker Desktop differences — [TB: 1.6](TROUBLESHOOTING.md#16-works-on-linux-brokenslow-on-docker-desktop)
- Service connectivity — [TB: 1.7](TROUBLESHOOTING.md#17-service-cant-connect-to-another-service)
- Debugging playbook (8 steps) — [TB: 2](TROUBLESHOOTING.md#2-debugging-playbook)
- Decision tree — [TB: 6](TROUBLESHOOTING.md#6-troubleshooting-decision-tree)
- Exit codes (0, 1, 137, 139, 143) — [TB: Step 5](TROUBLESHOOTING.md#step-5-inspect-container-state)
- Prevention best practices — [TB: 7](TROUBLESHOOTING.md#7-prevention-best-practices)

## Cleanup & Disk Management

- Cleanup levels (safe → aggressive) — [TB: 4](TROUBLESHOOTING.md#4-cleanup-and-prune-strategy) | [GL: Prune](GLOSSARY.md#prune)
- Reset recipes (safe, rebuild, hard, global) — [TB: 5](TROUBLESHOOTING.md#5-reset-recipes)
- Disk usage report — [scripts/docker-disk-report.sh](../scripts/docker-disk-report.sh)
- Safe reset script — [scripts/safe-reset.sh](../scripts/safe-reset.sh)
- Hard reset script — [scripts/hard-reset.sh](../scripts/hard-reset.sh)
- Prune script — [scripts/prune-unused.sh](../scripts/prune-unused.sh)

## LLM Workflows

- Stack design prompts — [BP: 19.1](BEST-PRACTICES.md#191-phase-1--requirements--design)
- Compose file critique prompts — [BP: 19.2](BEST-PRACTICES.md#192-phase-2--compose-file-critique)
- Deployment & debugging prompts — [BP: 19.3](BEST-PRACTICES.md#193-phase-3--deployment--debugging)
- Testing prompts — [BP: 19.4](BEST-PRACTICES.md#194-phase-4--testing)
- Maintenance prompts — [BP: 19.5](BEST-PRACTICES.md#195-phase-5--ongoing-maintenance)

## Checklists

- New service checklist — [BP: 20](BEST-PRACTICES.md#20-checklist-for-new-services)
- Image pre-adoption checklist — [BP: 18.2](BEST-PRACTICES.md#182-pre-adoption-checklist)
- Application security scorecard — [BP: 18.6](BEST-PRACTICES.md#186-application-security-scorecard)

## AI Agent Integration

- Why this repo works as a skill pack — [AGENT-SETUP: 1](AGENT-SETUP.md#1-why-this-repo-works-as-a-skill-pack)
- Tool mapping (Claude, Codex, Copilot, Cursor) — [AGENT-SETUP: 3](AGENT-SETUP.md#3-tool-mapping)
- What goes in the skill pack — [AGENT-SETUP: 4](AGENT-SETUP.md#4-what-goes-in-the-skill-pack)
- Per-tool setup — [AGENT-SETUP: 5](AGENT-SETUP.md#5-per-tool-setup)
- Claude Code setup — [AGENT-SETUP: 5.1](AGENT-SETUP.md#51-claude-code) | [CLAUDE.md](../CLAUDE.md)
- OpenAI Codex setup — [AGENT-SETUP: 5.2](AGENT-SETUP.md#52-openai-codex) | [AGENTS.md](../AGENTS.md)
- GitHub Copilot setup — [AGENT-SETUP: 5.3](AGENT-SETUP.md#53-github-copilot) | [.github/copilot-instructions.md](../.github/copilot-instructions.md)
- Cursor setup — [AGENT-SETUP: 5.4](AGENT-SETUP.md#54-cursor)
- VS Code & Visual Studio setup — [AGENT-SETUP: 5.5](AGENT-SETUP.md#55-vs-code--visual-studio)
- Practical setup plan (phased) — [AGENT-SETUP: 6](AGENT-SETUP.md#6-practical-setup-plan)
- LLM prompt templates — [BP: 19](BEST-PRACTICES.md#19-llm-assisted-stack-design-workflow)

## Contributing & Style

- Voice and style guide — [STYLE.md](STYLE.md)
- Phrase replacements (avoid → prefer) — [STYLE.md: Phrasing Rules](STYLE.md#phrasing-rules)
- Content checklist — [STYLE.md: Checklist](STYLE.md#checklist-for-new-content)
- Local linting (`make lint`) — [Makefile](../Makefile)

---

[← Back to README](../README.md)
