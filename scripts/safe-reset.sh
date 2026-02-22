#!/usr/bin/env bash
# =============================================================================
# SAFE RESET — Restart a Compose stack without losing persistent data
# =============================================================================
# Usage:  ./scripts/safe-reset.sh [path/to/docker-compose.yml]
#
# What it does:
#   1. Stops all containers and removes orphans
#   2. Recreates containers from the current compose file
#   3. Shows status when done
#
# What it does NOT do:
#   - Delete volumes (your data is preserved)
#   - Delete images (no re-download needed)
#   - Touch anything outside the Compose project
# =============================================================================

set -euo pipefail

COMPOSE_FILE="${1:-docker-compose.yml}"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Error: $COMPOSE_FILE not found"
  echo "Usage: $0 [path/to/docker-compose.yml]"
  exit 1
fi

echo "=== Safe Reset ==="
echo "Compose file: $COMPOSE_FILE"
echo ""

echo "--- Stopping containers and removing orphans ---"
docker compose -f "$COMPOSE_FILE" down --remove-orphans

echo ""
echo "--- Starting fresh containers ---"
docker compose -f "$COMPOSE_FILE" up -d --remove-orphans

echo ""
echo "--- Current status ---"
docker compose -f "$COMPOSE_FILE" ps
