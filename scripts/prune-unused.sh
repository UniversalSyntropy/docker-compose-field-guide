#!/usr/bin/env bash
# =============================================================================
# PRUNE UNUSED — Remove unused Docker resources with confirmation
# =============================================================================
# Usage:  ./scripts/prune-unused.sh [--aggressive]
#
# Default (safe):
#   - Removes stopped containers
#   - Removes unused networks
#   - Removes dangling images (untagged)
#   - Removes build cache
#
# With --aggressive:
#   - Also removes ALL unused images (not just dangling)
#   - Also removes unused volumes
#
# WARNING: --aggressive can delete data in volumes not attached to running
#          containers. If your containers are stopped, their volumes will
#          appear "unused."
# =============================================================================

set -euo pipefail

AGGRESSIVE=false
if [[ "${1:-}" == "--aggressive" ]]; then
  AGGRESSIVE=true
fi

echo "=== Docker Cleanup ==="
echo ""

# Show current usage
echo "--- Current disk usage ---"
docker system df
echo ""

if [[ "$AGGRESSIVE" == true ]]; then
  echo "Mode: AGGRESSIVE (all unused images + unused volumes)"
  echo ""
  echo "WARNING: This will also remove:"
  echo "  - ALL unused images (not just dangling)"
  echo "  - ALL unused volumes (data loss risk if containers are stopped)"
  echo ""
  read -rp "Are you sure? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
  docker system prune -a --volumes --force
else
  echo "Mode: SAFE (stopped containers + unused networks + dangling images + build cache)"
  echo ""
  read -rp "Proceed? (y/N): " confirm
  if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
  docker system prune --force
fi

echo ""
echo "--- Disk usage after cleanup ---"
docker system df
