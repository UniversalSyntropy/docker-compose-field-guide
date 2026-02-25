# MCP Server

A [Model Context Protocol](https://modelcontextprotocol.io/) server that
exposes the Docker Compose Field Guide as tools for AI coding agents. Works
with Claude Code, VS Code with Copilot, and any MCP-compatible client.

## Requirements

- Python 3.10+
- `mcp>=1.0.0` (`pip install mcp`)

## Available tools

| Tool | What it returns |
| --- | --- |
| `get_compose_standards` | Compose coding standards from CLAUDE.md |
| `get_best_practices` | Full best practices guide (21 sections) |
| `get_troubleshooting` | Troubleshooting and debugging playbook |
| `get_compose_template` | Annotated docker-compose.yml reference template |
| `list_guides` | All documentation guides (filename + title) |
| `get_guide` | A specific guide by filename |
| `list_recipes` | Available hardened recipe filenames |
| `get_recipe` | A specific recipe by filename |
| `list_scripts` | Helper scripts with descriptions |
| `get_script` | A specific helper script |
| `check_compose_text` | Validate compose YAML against field guide standards |

## Register globally with Claude Code

```bash
claude mcp add \
  --transport stdio \
  --scope user \
  docker-compose-field-guide -- \
  python3.10 /path/to/docker-compose-field-guide/mcp-server/server.py
```

After registration, every Claude Code session can call tools like
`get_best_practices` or `check_compose_text` without any project-specific
configuration.

## Register with VS Code

Add to your VS Code `settings.json`:

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

## Test the server

Use the MCP Inspector for interactive testing:

```bash
npx @modelcontextprotocol/inspector python3.10 mcp-server/server.py
```

Or use the test suite from the
[ai-tools](https://github.com/UniversalSyntropy/ai-tools) repo:

```bash
cd /path/to/ai-tools/mcp-test-suite
python3.10 src/client.py python3.10 /path/to/docker-compose-field-guide/mcp-server/server.py
```

## How it works

The server uses [FastMCP](https://github.com/modelcontextprotocol/python-sdk)
to expose repository files as MCP tools over Stdio transport. All file contents
are read dynamically from disk on every tool call — the server never needs
updating when repository files change.

[Back to README](../README.md)
