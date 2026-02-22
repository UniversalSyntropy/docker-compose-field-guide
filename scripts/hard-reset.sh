#!/usr/bin/env bash
# =============================================================================
# HARD RESET — Tear down a Compose stack, rebuild images, delete project volumes
# =============================================================================
# Usage:  ./scripts/hard-reset.sh [path/to/docker-compose.yml]
#
# WARNING: This deletes all project volumes. Any data stored in named volumes
#          (databases, configs, etc.) will be permanently lost.
#
# What it does:
#   1. Asks for confirmation
#   2. Stops all containers, removes orphans, volumes, and locally-built images
#   3. Rebuilds and starts all containers
#   4. Shows status when done
# =============================================================================

set -euo pipefail

COMPOSE_FILE="${1:-docker-compose.yml}"

if [[ ! -f "$COMPOSE_FILE" ]]; then
  echo "Error: $COMPOSE_FILE not found"
  echo "Usage: $0 [path/to/docker-compose.yml]"
  exit 1
fi

echo "=== Hard Reset ==="
echo "Compose file: $COMPOSE_FILE"
echo ""
echo "WARNING: This will delete all project volumes and rebuild images."
echo "         Any data in named volumes will be permanently lost."
echo ""
read -rp "Are you sure? (y/N): " confirm

if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
  echo "Aborted."
  exit 0
fi

echo ""
echo "--- Tearing down (containers + orphans + volumes + local images) ---"
docker compose -f "$COMPOSE_FILE" down --remove-orphans --volumes --rmi local

echo ""
echo "--- Rebuilding and starting ---"
docker compose -f "$COMPOSE_FILE" up -d --build

echo ""
echo "--- Current status ---"
docker compose -f "$COMPOSE_FILE" ps
