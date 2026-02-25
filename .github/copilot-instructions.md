# Docker Compose Field Guide — Copilot instructions

This repo is a detailed Docker Compose reference. Follow these standards when working on Docker Compose tasks.

## Compose standards

- Pin images to exact version tags — never `:latest`
- No `version:` key (deprecated in Compose v2)
- Avoid `container_name` unless tooling requires it
- Set `mem_limit`, `cpus`, `pids_limit` on every service
- Set `restart: unless-stopped` on every service
- Configure log rotation: `max-size: "10m"`, `max-file: "3"`
- Add healthchecks on all services with endpoints
- Use Docker secrets for passwords — never inline or in `.env`
- Apply security defaults: `cap_drop: [ALL]`, `no-new-privileges:true`
- Use `read_only: true` + `tmpfs` where possible
- Only publish ports that need external access

## Workflow

1. Plan first, YAML second
2. Validate before running: `docker compose config --quiet`
3. Patch minimally during debugging — don't rewrite working services
4. Test after every change

## Safety

Warn before running destructive commands:

- `docker compose down -v` — deletes volumes (data loss)
- `docker system prune` / `docker volume prune` — removes unused resources
- `--force-recreate` — restarts all containers

## Troubleshooting

Follow this order: validate → inspect → logs → minimal patch → revalidate.

See [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md) for the full debugging playbook.

## MCP server

This repo includes an MCP server at `mcp-server/server.py`. If registered in
your VS Code MCP settings, call `get_best_practices`, `get_compose_template`,
`list_recipes`, or `check_compose_text` to load context or lint compose YAML.

See [mcp-server/README.md](../mcp-server/README.md) for setup.

## Documentation map

- Best practices: [BEST-PRACTICES.md](../docs/BEST-PRACTICES.md)
- Troubleshooting: [TROUBLESHOOTING.md](../docs/TROUBLESHOOTING.md)
- Docker basics: [DOCKER-BASICS.md](../docs/DOCKER-BASICS.md)
- Glossary: [GLOSSARY.md](../docs/GLOSSARY.md)
- Index: [INDEX.md](../docs/INDEX.md)
- Template: [docker-compose.yml](../docker-compose.yml)
- Monitoring: [monitoring/](../monitoring/)
- Scripts: [scripts/](../scripts/)
- MCP server: [mcp-server/](../mcp-server/README.md)
