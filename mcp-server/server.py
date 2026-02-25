#!/usr/bin/env python3
"""MCP server for the Docker Compose Field Guide.

Exposes best practices, troubleshooting guides, hardened recipes, helper
scripts, and the annotated compose template as MCP tools. All file contents
are read dynamically from disk — the server never needs updating when
repository files change.
"""

import re
import sys
from pathlib import Path

from mcp.server.fastmcp import FastMCP

REPO_ROOT = Path(__file__).resolve().parent.parent

mcp = FastMCP("docker-compose-field-guide")


# --- Compose standards and best practices ---


@mcp.tool()
def get_compose_standards() -> str:
    """Load the Docker Compose coding standards from CLAUDE.md.

    Returns the compose rules that every docker-compose.yml must follow:
    image pinning, resource limits, security defaults, healthchecks,
    log rotation, network isolation, and the validation workflow.
    Call this before writing or reviewing any compose file.
    """
    path = REPO_ROOT / "CLAUDE.md"
    if path.exists():
        return path.read_text(encoding="utf-8")
    return f"[file not found: {path}]"


@mcp.tool()
def get_best_practices() -> str:
    """Load the full best practices guide (BEST-PRACTICES.md).

    Covers 21 sections: image pinning, resource limits, security hardening,
    healthchecks, secrets management, network isolation, logging, YAML
    anchors, dependency ordering, and more. Use this as the primary
    reference when building or auditing compose stacks.
    """
    path = REPO_ROOT / "docs" / "BEST-PRACTICES.md"
    if path.exists():
        return path.read_text(encoding="utf-8")
    return f"[file not found: {path}]"


@mcp.tool()
def get_troubleshooting() -> str:
    """Load the troubleshooting and debugging playbook.

    Step-by-step diagnostic workflow for common Docker Compose failures:
    container won't start, unhealthy status, networking issues, volume
    permission errors, OOM kills, and more.
    """
    path = REPO_ROOT / "docs" / "TROUBLESHOOTING.md"
    if path.exists():
        return path.read_text(encoding="utf-8")
    return f"[file not found: {path}]"


@mcp.tool()
def get_compose_template() -> str:
    """Load the annotated docker-compose.yml reference template.

    A fully commented compose file demonstrating every best practice:
    YAML anchors, security defaults, resource limits, healthchecks,
    secrets, network isolation, and dependency ordering. Copy and adapt
    this template when starting a new stack.
    """
    path = REPO_ROOT / "docker-compose.yml"
    if path.exists():
        return path.read_text(encoding="utf-8")
    return f"[file not found: {path}]"


# --- Guides ---


@mcp.tool()
def list_guides() -> str:
    """List all available documentation guides.

    Returns the filenames and first-line titles of all Markdown files in
    the docs/ directory. Use get_guide() to retrieve a specific one.
    """
    docs_dir = REPO_ROOT / "docs"
    if not docs_dir.is_dir():
        return "[docs/ directory not found]"
    lines = []
    for f in sorted(docs_dir.glob("*.md")):
        first_line = f.read_text(encoding="utf-8").split("\n", 1)[0]
        title = first_line.lstrip("# ").strip() if first_line.startswith("#") else f.name
        lines.append(f"{f.name}: {title}")
    if not lines:
        return "[no guide files found]"
    return "\n".join(lines)


@mcp.tool()
def get_guide(filename: str) -> str:
    """Load a specific documentation guide by filename.

    Args:
        filename: The guide filename (e.g. 'REVERSE-PROXY.md', 'GLOSSARY.md').
                  Use list_guides() to see available files.
    """
    path = REPO_ROOT / "docs" / filename
    if not path.exists():
        return f"[guide not found: {filename}]"
    # Prevent path traversal
    if not path.resolve().is_relative_to(REPO_ROOT / "docs"):
        return "[invalid path]"
    return path.read_text(encoding="utf-8")


# --- Recipes ---


@mcp.tool()
def list_recipes() -> str:
    """List available hardened Docker Compose recipes.

    Returns the filenames of all .yml recipe files in the recipes/
    directory. Each recipe is a production-ready compose stack for a
    popular homelab application. Use get_recipe() to retrieve one.
    """
    recipes_dir = REPO_ROOT / "recipes"
    if not recipes_dir.is_dir():
        return "[recipes/ directory not found]"
    files = sorted(f.name for f in recipes_dir.glob("*.yml"))
    if not files:
        return "[no recipe files found]"
    return "\n".join(files)


@mcp.tool()
def get_recipe(filename: str) -> str:
    """Load a specific hardened Docker Compose recipe.

    Args:
        filename: The recipe filename (e.g. 'pihole.yml', 'nextcloud.yml').
                  Use list_recipes() to see available files.
    """
    path = REPO_ROOT / "recipes" / filename
    if not path.exists():
        return f"[recipe not found: {filename}]"
    if not path.resolve().is_relative_to(REPO_ROOT / "recipes"):
        return "[invalid path]"
    return path.read_text(encoding="utf-8")


# --- Scripts ---


@mcp.tool()
def list_scripts() -> str:
    """List available Docker helper scripts.

    Returns the filenames and first-line descriptions of shell scripts
    in the scripts/ directory. These cover disk reporting, cleanup,
    and safe reset operations. Use get_script() to retrieve one.
    """
    scripts_dir = REPO_ROOT / "scripts"
    if not scripts_dir.is_dir():
        return "[scripts/ directory not found]"
    lines = []
    for f in sorted(scripts_dir.glob("*.sh")):
        # Try to extract the description from the script header
        content = f.read_text(encoding="utf-8")
        desc = f.name
        for line in content.split("\n"):
            line = line.strip()
            if line.startswith("# ") and not line.startswith("#!"):
                desc = line.lstrip("# ").strip()
                break
        lines.append(f"{f.name}: {desc}")
    if not lines:
        return "[no script files found]"
    return "\n".join(lines)


@mcp.tool()
def get_script(filename: str) -> str:
    """Load a specific Docker helper script.

    Args:
        filename: The script filename (e.g. 'safe-reset.sh', 'prune-unused.sh').
                  Use list_scripts() to see available files.
    """
    path = REPO_ROOT / "scripts" / filename
    if not path.exists():
        return f"[script not found: {filename}]"
    if not path.resolve().is_relative_to(REPO_ROOT / "scripts"):
        return "[invalid path]"
    return path.read_text(encoding="utf-8")


# --- Compose validation ---


@mcp.tool()
def check_compose_text(text: str) -> str:
    """Check a docker-compose.yml snippet against field guide standards.

    Args:
        text: The compose YAML text to check (full file or snippet).

    Returns a list of issues found, or confirmation that the text follows
    the standards. Does not write to disk or run Docker commands.
    """
    issues = []

    # Check for deprecated version key
    if re.search(r"^version:", text, re.MULTILINE):
        issues.append("Remove the 'version:' key — it is deprecated in Compose v2")

    # Check for :latest tags
    if re.search(r"image:\s*\S+:latest\b", text):
        issues.append("Pin images to exact version tags — never use :latest")

    # Check for missing restart policy
    if "services:" in text and "restart:" not in text:
        issues.append("Set 'restart: unless-stopped' on every service")

    # Check for missing resource limits
    if "services:" in text:
        if "mem_limit" not in text and "memory" not in text:
            issues.append("Set mem_limit on every service to prevent OOM kills")
        if "cpus" not in text:
            issues.append("Set cpus on every service to prevent CPU starvation")
        if "pids_limit" not in text:
            issues.append("Set pids_limit on every service to prevent fork bombs")

    # Check for missing healthcheck
    if "services:" in text and "healthcheck:" not in text:
        issues.append("Add healthchecks on services with HTTP or CLI endpoints")

    # Check for missing log rotation
    if "services:" in text and "logging:" not in text and "x-logging:" not in text:
        issues.append("Configure log rotation (max-size: 10m, max-file: 3)")

    # Check for missing security hardening
    if "services:" in text:
        if "cap_drop" not in text:
            issues.append("Add 'cap_drop: [ALL]' and re-add only needed capabilities")
        if "no-new-privileges" not in text:
            issues.append("Add 'security_opt: [no-new-privileges:true]'")

    # Check for inline passwords
    password_patterns = [
        r"PASSWORD=(?!.*_FILE)[^\$\{]\w+",
        r"password:\s*['\"]?\w{4,}['\"]?",
    ]
    for pattern in password_patterns:
        if re.search(pattern, text, re.IGNORECASE):
            issues.append(
                "Avoid inline passwords — use Docker secrets with the _FILE suffix"
            )
            break

    # Check for 0.0.0.0 port binding
    if re.search(r'["\']?0\.0\.0\.0:', text):
        issues.append(
            "Avoid binding to 0.0.0.0 — use 127.0.0.1 or omit the host for LAN access"
        )

    if issues:
        return "Issues found:\n" + "\n".join(f"- {i}" for i in issues)
    return "No issues found — the compose text follows field guide standards."


def main():
    mcp.run(transport="stdio")


if __name__ == "__main__":
    main()
