# Multi-agent skill pack

How to use this repo as a shared knowledge base for AI coding agents — Claude Code, GitHub Copilot, OpenAI Codex, Cursor, and others.

> **Why this matters:** Different tools use different names (skills, rules, instructions, agents, memories), but the goal is the same — teach the agent your standards so it produces consistent, safe, reviewable work without you repeating yourself every session.

---

## Table of contents

1. [Why this repo works as a skill pack](#1-why-this-repo-works-as-a-skill-pack)
2. [The core idea](#2-the-core-idea)
3. [Tool mapping](#3-tool-mapping)
4. [What goes in the skill pack](#4-what-goes-in-the-skill-pack)
5. [Per-tool setup](#5-per-tool-setup)
6. [Practical setup plan](#6-practical-setup-plan)
7. [Repo structure for multi-agent support](#7-repo-structure-for-multi-agent-support)
8. [MCP server](#8-mcp-server)

---

## 1. Why this repo works as a skill pack

> **In a nutshell:** This repo already contains everything a coding agent needs to work reliably with Docker Compose — standards, examples, troubleshooting workflows, safety rules, and validation commands. Wrapping it as a skill pack makes that knowledge accessible to the agent automatically.

A coding agent working on Docker Compose stacks benefits from:

- **Standards** — so it doesn't invent its own conventions
- **Troubleshooting workflows** — so it follows a structured debugging process instead of guessing
- **Safety rules** — so it warns before destructive commands (`down -v`, `prune`)
- **Validation commands** — so it checks its own work
- **Examples** — so it has known-good templates to reference

This repo already has all of that. The skill pack setup connects it to the tools you use.

---

## 2. The core idea

Use this repo as the **source of truth**, then expose it to each coding agent using that tool's preferred mechanism.

```text
                    ┌─────────────────────────────┐
                    │  This Repo (source of truth) │
                    │  Standards + Examples +       │
                    │  Troubleshooting + Safety     │
                    └──────────┬──────────────────┘
                               │
          ┌────────────┬───────┼───────┬────────────┐
          │            │       │       │            │
     CLAUDE.md    AGENTS.md  copilot  Cursor     Prompt
    (Claude Code) (Codex)  instructions Rules    Files
```

The core content stays the same across tools. Only the delivery format changes.

---

## 3. Tool mapping

| Tool | Instruction file | Mechanism | Docs |
|------|-----------------|-----------|------|
| **Claude Code** | `CLAUDE.md` | Project instructions + Skills | [Claude Code docs](https://docs.anthropic.com/en/docs/claude-code) |
| **OpenAI Codex** | `AGENTS.md` | Agent instructions (read before work) | [Codex docs](https://docs.openai.com/codex) |
| **GitHub Copilot** | `.github/copilot-instructions.md` | Repo-level custom instructions | [Copilot docs](https://docs.github.com/en/copilot/customizing-copilot) |
| **Cursor** | `.cursor/rules/*.mdc` | Rules (static) + Skills (dynamic) | [Cursor docs](https://docs.cursor.com) |
| **VS Code** | `.github/copilot-instructions.md` | Copilot custom instructions + prompt files | [VS Code Copilot docs](https://code.visualstudio.com/docs/copilot) |
| **Visual Studio** | `.github/copilot-instructions.md` | Same Copilot files as VS Code | [Visual Studio Copilot docs](https://learn.microsoft.com/en-us/visualstudio/ide/copilot) |

> **One set of Copilot instructions works across GitHub, VS Code, Visual Studio, and JetBrains** — you don't need separate files for each IDE.

---

## 4. What goes in the skill pack

Keep the core content the same across tools. Here's what every agent instruction file should cover:

### 4.1 Project scope

- Docker Engine 24+ with Docker Compose v2
- What's in scope / out of scope
- Homelab / self-hosted focus

### 4.2 Compose standards

- No deprecated `version:` key
- Avoid `container_name` unless justified
- Internal-only ports by default
- Healthchecks on all services with HTTP endpoints
- Named volumes or bind mounts for all stateful data
- `restart: unless-stopped` on every service
- Log rotation on every service
- Resource limits (`mem_limit`, `cpus`, `pids_limit`) on every service

### 4.3 Workflow rules

- Plan first, YAML second
- Validate before running (`docker compose config`)
- Patch minimally during debugging — don't rewrite working services
- Test after every change

### 4.4 Safety rules

- Warn before `down -v` (deletes volumes)
- Warn before any `prune` command
- Require rollback notes for risky changes
- Never force-push without confirmation
- Back up before destructive operations

### 4.5 Validation commands

```bash
docker compose config --quiet          # Syntax check
docker compose up -d --wait            # Deploy and wait for healthy
docker compose ps                      # Status check
docker compose logs --tail=50 <svc>    # Log check
```

### 4.6 Troubleshooting loop

Follow this order, every time:

1. **Validate** — `docker compose config`
2. **Inspect** — `docker compose ps`, check exit codes
3. **Logs** — `docker compose logs <service>`
4. **Minimal patch** — fix the specific issue, nothing more
5. **Revalidate** — confirm the fix, check nothing else broke

### 4.7 Scaling guardrails

- Only scale stateless services
- Remove `container_name` from anything that might scale
- Compose is not native autoscaling — it's manual `--scale`

---

## 5. Per-tool setup

### 5.1 Claude Code

Claude Code uses `CLAUDE.md` for project instructions and Skills for reusable task behaviours.

**What to do:**

- Add a `CLAUDE.md` in the repo root (included in this repo)
- Reference the best practices, troubleshooting, and networking docs
- Optionally create Claude Skills for repeatable tasks (e.g., "design a Compose stack", "debug a restart loop")

**Good split:**

- `CLAUDE.md` → project policy and constraints (always active)
- Skills → repeatable task workflows (loaded on demand)

**Included in this repo:** [CLAUDE.md](../CLAUDE.md)

### 5.2 OpenAI Codex

Codex reads `AGENTS.md` files before doing work — it's the direct equivalent of project instructions.

**What to do:**

- Add `AGENTS.md` at the repo root (included in this repo)
- Keep it concise and operational — Codex works best with concrete instructions
- Tell Codex which commands are safe to run and which need confirmation

**Included in this repo:** [AGENTS.md](../AGENTS.md)

### 5.3 GitHub Copilot

Copilot uses `.github/copilot-instructions.md` for repo-level instructions.

**What to do:**

- Create `.github/copilot-instructions.md` (included in this repo)
- Optionally add path-specific instructions in `.github/instructions/*.instructions.md`
- Optionally create custom Copilot agents for focused tasks

**Optional path-specific instructions:**

```text
.github/instructions/
├── examples.instructions.md     # "These are known-good templates"
├── scripts.instructions.md      # "These are helper scripts, keep them simple"
└── monitoring.instructions.md   # "This is a Prometheus + Grafana stack"
```

**Included in this repo:** [.github/copilot-instructions.md](../.github/copilot-instructions.md)

### 5.4 Cursor

Cursor has both Rules (always-on constraints) and Skills (reusable task workflows).

**Good split:**

| Type | Use for | Examples |
|------|---------|----------|
| **Rules** (static) | Compose standards, security defaults, validation requirements | "Always validate before deploying", "Never use `:latest`" |
| **Skills** (dynamic) | Repeatable workflows loaded on demand | "Design a stack from brief", "Debug a failing service", "Harden a compose file" |

**What to do:**

- Put repo policy into `.cursor/rules/` (adapt from `CLAUDE.md` or `AGENTS.md`)
- Put reusable workflows into Cursor Skills
- Keep skills small and focused — one clear job each

### 5.5 VS Code and Visual Studio

Both use Copilot's instruction files — the same files from [5.3](#53-github-copilot) work automatically.

**What to do:**

- Reuse `.github/copilot-instructions.md` (already created)
- Optionally add `.github/instructions/*.instructions.md` for path-specific guidance
- File-based instructions are the recommended approach (settings-based options are being deprecated)

---

## 6. Practical setup plan

### Phase 1 — Shared base (start here)

Create the core instruction files with the same standards adapted to each tool:

| File | Tool | Status |
|------|------|--------|
| `CLAUDE.md` | Claude Code | Included in this repo |
| `AGENTS.md` | Codex | Included in this repo |
| `.github/copilot-instructions.md` | Copilot (GitHub, VS Code, Visual Studio) | Included in this repo |

### Phase 2 — Tool-specific optimisation

Add when you need them:

- `.github/instructions/*.instructions.md` — path-specific Copilot guidance
- `.cursor/rules/` — Cursor rules
- Claude Skills — packaged reusable workflows
- Custom Copilot agents — focused task agents

### Phase 3 — Skill pack packaging (optional)

If you want to share your skill pack with others or across repos:

```text
skill-pack/
├── README.md                    # What this pack does
├── core-principles.md           # Shared standards
├── checklists.md                # Validation and safety checklists
├── prompts/
│   ├── design-stack.md          # "Design a Compose stack from this brief"
│   ├── debug-stack.md           # "Debug this failing stack"
│   ├── review-security.md       # "Review this compose file for security"
│   └── scaling-readiness.md     # "Check if this stack can scale"
├── runbooks/
│   ├── safe-reset.md
│   ├── hard-reset.md
│   └── prune-strategy.md
└── mappings/
    ├── claude-code.md           # How to use with Claude Code
    ├── codex.md                 # How to use with Codex
    ├── copilot.md               # How to use with Copilot
    └── cursor.md                # How to use with Cursor
```

---

## 7. Repo structure for multi-agent support

This repo includes the Phase 1 files. Here's where they sit:

```text
├── CLAUDE.md                              ← Claude Code project instructions
├── AGENTS.md                              ← OpenAI Codex agent instructions
├── docs/
│   └── AGENT-SETUP.md                    ← This file (setup guide)
├── .github/
│   ├── copilot-instructions.md            ← GitHub Copilot repo instructions
│   └── workflows/validate.yml             ← CI validation
└── ... (all other repo files)
```

The instruction files are deliberately concise — they reference the detailed documentation rather than duplicating it. This keeps them maintainable and ensures agents always work from the latest version of the standards.

---

## 8. MCP server

The `mcp-server/` directory contains a
[Model Context Protocol](https://modelcontextprotocol.io/) server that exposes
the field guide as tools for AI agents. This works across Claude Code, VS Code
with Copilot, and any MCP-compatible client.

The MCP server provides 11 tools including `get_best_practices`,
`get_compose_template`, `list_recipes`, and `check_compose_text` (a linter
that checks compose YAML against field guide standards).

See [mcp-server/README.md](../mcp-server/README.md) for setup instructions.

### Register globally

Once registered, every session gets access to the field guide tools — no
per-project configuration needed.

**Claude Code:**

```bash
claude mcp add \
  --transport stdio \
  --scope user \
  docker-compose-field-guide -- \
  python3.10 /path/to/docker-compose-field-guide/mcp-server/server.py
```

**VS Code** — add to your user `settings.json`:

```json
{
  "mcp": {
    "servers": {
      "docker-compose-field-guide": {
        "command": "python3.10",
        "args": ["/path/to/docker-compose-field-guide/mcp-server/server.py"],
        "type": "stdio"
      }
    }
  }
}
```

---

## See also

- [Best Practices](BEST-PRACTICES.md) — the standards these agents enforce
- [Troubleshooting](TROUBLESHOOTING.md) — the debugging workflow agents should follow
- [LLM-Assisted Workflow](BEST-PRACTICES.md#19-llm-assisted-stack-design-workflow) — prompt templates for stack design and review
- [MCP Server](../mcp-server/README.md) — expose field guide tools via Model Context Protocol

---

[← Back to README](../README.md)
