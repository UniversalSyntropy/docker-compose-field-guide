# MCP server

A [Model Context Protocol](https://modelcontextprotocol.io/) server that
exposes the Docker Compose Field Guide as tools for AI coding agents. Works
with Claude Code, VS Code, Cursor, and any MCP-compatible client.

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

The `check_compose_text` tool is a linter. Pass it a compose YAML string and
it checks for missing resource limits, `:latest` tags, inline passwords,
missing healthchecks, and other field guide violations.

---

## Register with Claude Code

Register globally so every Claude Code session has access:

```bash
claude mcp add \
  --transport stdio \
  --scope user \
  docker-compose-field-guide -- \
  python3.10 <PATH_TO_REPO>/mcp-server/server.py
```

Replace `<PATH_TO_REPO>` with the absolute path to your clone of this repo.

After registration, the agent can call tools like `get_best_practices` or
`check_compose_text` in any project without extra configuration.

## Register with VS Code and GitHub Copilot

VS Code with Copilot uses MCP servers registered in `settings.json`. Add this
to your user settings (`Cmd+Shift+P` → "Preferences: Open User Settings (JSON)"):

```json
{
  "mcp": {
    "servers": {
      "docker-compose-field-guide": {
        "command": "python3.10",
        "args": ["<PATH_TO_REPO>/mcp-server/server.py"],
        "type": "stdio"
      }
    }
  }
}
```

Replace `<PATH_TO_REPO>` with the absolute path to your clone.

Copilot agents that support MCP tool use can then call field guide tools
directly during chat and inline editing sessions.

## Register with Cursor

Create a `.cursor/mcp.json` file in your home directory or project root:

```json
{
  "mcpServers": {
    "docker-compose-field-guide": {
      "command": "python3.10",
      "args": ["<PATH_TO_REPO>/mcp-server/server.py"]
    }
  }
}
```

Replace `<PATH_TO_REPO>` with the absolute path to your clone.

Cursor agents can then call `get_best_practices`, `check_compose_text`, and
all other tools during chat and composer sessions.

---

## Test the server

Use the MCP Inspector for interactive testing:

```bash
npx @modelcontextprotocol/inspector python3.10 mcp-server/server.py
```

Or use the test suite from the
[ai-tools](https://github.com/UniversalSyntropy/ai-tools) repo:

```bash
cd <PATH_TO_AI_TOOLS>/mcp-test-suite
python3.10 src/client.py python3.10 <PATH_TO_REPO>/mcp-server/server.py
```

Expected output: `Discovered 11 tool(s)` with all tools listed.

Run the dedicated validator to confirm required tools are present:

```bash
python3.10 src/validate_field_guide.py <PATH_TO_REPO>/mcp-server/server.py
```

Expected output: `Server status: HEALTHY` with all required tools passing.

---

## How it works

The server uses [FastMCP](https://github.com/modelcontextprotocol/python-sdk)
to expose repository files as MCP tools over Stdio transport. All file contents
are read dynamically from disk on every tool call — the server never needs
updating when repository files change.

## Using MCP with LLM prompts

If your coding agent has access to this MCP server, you can skip pasting
context into prompts. Instead of copying the best practices document into a
prompt, the agent calls `get_best_practices` or `check_compose_text` directly.

For example, instead of the manual prompts in
[Section 19 of the best practices](../docs/BEST-PRACTICES.md#19-llm-assisted-stack-design-workflow),
ask your agent:

> "Use the docker-compose-field-guide MCP to review this compose file
> against field guide standards."

The agent calls `check_compose_text` and `get_best_practices` to provide
the same review without manual context.

---

[Back to README](../README.md)
