#!/usr/bin/env bash
# =============================================================================
# DOCKER DISK REPORT — Show what Docker is using on disk
# =============================================================================
# Usage:  ./scripts/docker-disk-report.sh
#
# Shows:
#   - Summary of disk usage by category (images, containers, volumes, build cache)
#   - Top 10 largest images
#   - Volumes not attached to any running container
#   - Reclaimable space estimate
# =============================================================================

set -euo pipefail

echo "=== Docker Disk Usage Report ==="
echo ""

echo "--- Summary ---"
docker system df
echo ""

echo "--- Top 10 Largest Images ---"
docker images --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.ID}}" \
  | head -11
echo ""

echo "--- Dangling Images (no tag, safe to remove) ---"
DANGLING=$(docker images -f "dangling=true" -q | wc -l)
echo "Count: $DANGLING"
if [[ "$DANGLING" -gt 0 ]]; then
  echo "Remove with: docker image prune"
fi
echo ""

echo "--- Volumes Not Attached to Running Containers ---"
RUNNING_VOLS=$(docker ps -q | xargs -r docker inspect --format '{{range .Mounts}}{{.Name}} {{end}}' 2>/dev/null | tr ' ' '\n' | sort -u)
ALL_VOLS=$(docker volume ls -q)

ORPHAN_COUNT=0
while IFS= read -r vol; do
  [[ -z "$vol" ]] && continue
  if ! echo "$RUNNING_VOLS" | grep -qx "$vol"; then
    echo "  $vol"
    ORPHAN_COUNT=$((ORPHAN_COUNT + 1))
  fi
done <<< "$ALL_VOLS"

if [[ "$ORPHAN_COUNT" -eq 0 ]]; then
  echo "  (none)"
else
  echo ""
  echo "  $ORPHAN_COUNT volume(s) not attached to running containers."
  echo "  Review carefully — stopped containers may still need these."
  echo "  Remove with: docker volume prune"
fi
echo ""

echo "--- Compose Projects ---"
docker compose ls 2>/dev/null || echo "(docker compose ls not available)"
echo ""

echo "--- Reclaimable Space ---"
docker system df --format "{{.Type}}\t{{.Reclaimable}}" 2>/dev/null || docker system df
