# GitHub metadata

Set these in the repo settings at
github.com/UniversalSyntropy/docker-compose-field-guide, or apply them with the
`gh` CLI commands below.

---

## Description (About section)

```text
A hardened Docker Compose reference for homelabs — best practices, security defaults, recipes, troubleshooting, MCP server for AI agents, and a working quickstart stack.
```

## Topics

```text
docker
docker-compose
homelab
self-hosted
best-practices
security
devops
containers
mcp
mcp-server
model-context-protocol
ai-tools
claude-code
copilot
cursor
yaml
infrastructure
linux
monitoring
templates
```

## Website URL

Leave blank unless a docs site is created.

---

## Apply with gh CLI

Update the description:

```bash
gh repo edit --description "A hardened Docker Compose reference for homelabs — best practices, security defaults, recipes, troubleshooting, MCP server for AI agents, and a working quickstart stack."
```

Add topics (run from inside the repo):

```bash
gh repo edit \
  --add-topic docker \
  --add-topic docker-compose \
  --add-topic homelab \
  --add-topic self-hosted \
  --add-topic best-practices \
  --add-topic security \
  --add-topic devops \
  --add-topic containers \
  --add-topic mcp \
  --add-topic mcp-server \
  --add-topic model-context-protocol \
  --add-topic ai-tools \
  --add-topic claude-code \
  --add-topic copilot \
  --add-topic cursor \
  --add-topic yaml \
  --add-topic infrastructure \
  --add-topic linux \
  --add-topic monitoring \
  --add-topic templates
```

---

## Create a GitHub release

Tag `v1.0.0` for the initial public release. A release makes the repo visible
in GitHub search results, shows up in "Explore", and gives a clear snapshot for
anyone discovering the project.

```bash
gh release create v1.0.0 \
  --title "v1.0.0 — Initial public release" \
  --notes "$(cat <<'NOTES'
First public release of the Docker Compose Field Guide.

## What's included

- **Annotated template** — `docker-compose.yml` with security defaults, resource limits, healthchecks, and inline explanations
- **Best practices guide** — 21 sections covering image pinning, secrets, networking, capabilities, monitoring, and more
- **Troubleshooting playbook** — step-by-step debugging workflow with decision tree
- **Hardened recipes** — Pi-hole, Nextcloud (+MariaDB +Redis), Traefik v3 with HTTPS
- **Quickstart stack** — Homepage dashboard + Uptime Kuma monitoring (working demo)
- **MCP server** — 11 tools for AI coding agents (Claude Code, VS Code, Cursor)
- **Monitoring stack** — Prometheus + Grafana + Node Exporter + cAdvisor
- **Helper scripts** — safe reset, hard reset, disk report, prune
- **Reverse proxy guide** — Traefik architecture, certificate methods, multi-stack networking
- **Secrets management guide** — SOPS + age, Doppler, git-crypt
- **AI agent instructions** — CLAUDE.md, AGENTS.md, copilot-instructions.md
- **CI pipeline** — YAML lint, Markdown lint, ShellCheck, compose validation, live stack test, link check
NOTES
)"
```

---

## Promote

### Reddit

Relevant subreddits (check each subreddit's self-promotion rules before
posting):

| Subreddit | Audience | Lead with |
| --- | --- | --- |
| r/selfhosted | Primary audience | Quickstart stack, recipes |
| r/homelab | Hardware-focused homelab users | Security hardening, before/after example |
| r/docker | Docker practitioners | Annotated template, CI pipeline |
| r/DevOps | Professional DevOps | MCP server, CI pipeline, CIS Benchmark mapping |

**Post format that works:**

1. Descriptive title, not clickbait — "Docker Compose Field Guide — hardened templates, recipes, and an MCP server for AI coding agents"
2. Body: 3-4 sentences on what the repo does, a link, and what makes it different (security-first defaults, working quickstart, MCP integration)
3. Space posts across subreddits over a week — don't post to all on the same day

### Other channels

- **Hacker News** — "Show HN" post with a short title, link to repo, brief description in comments
- **Docker community forums** — post in the Compose or general discussion section
- **GitHub Discussions** on related repos (if they have a "Show and Tell" category)
- **X / Twitter** — with `#docker` `#homelab` `#selfhosted` tags
- **Mastodon** — `#docker` `#selfhosted` `#homelab` tags on relevant instances

---

[Back to README](README.md)
