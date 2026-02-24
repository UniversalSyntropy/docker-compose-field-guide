# Docker Compose troubleshooting guide

Common gotchas, debugging playbook, cleanup strategies, and error reference for Docker Compose stacks. See the [glossary](GLOSSARY.md) for definitions of any unfamiliar term.

---

## Table of contents

1. [Common gotchas](#1-common-gotchas)
2. [Debugging playbook](#2-debugging-playbook)
3. [Common errors and fixes](#3-common-errors-and-fixes)
4. [Cleanup and prune strategy](#4-cleanup-and-prune-strategy)
5. [Reset recipes](#5-reset-recipes)
6. [Troubleshooting decision tree](#6-troubleshooting-decision-tree)
7. [Prevention best practices](#7-prevention-best-practices)

---

## 1. Common gotchas

### 1.1 Orphan containers after renaming services

**Symptom:** Compose warns about orphan containers. Old containers still exist after changing service names.

**Why:** Compose tracks services by project name + service name. Renaming a service or changing the project name makes old containers "orphans" that Compose no longer manages.

**Fix:**

```bash
docker compose down --remove-orphans
docker compose up -d --remove-orphans
```

**Prevention:**

- Set a stable project name (`name:` in compose file or `COMPOSE_PROJECT_NAME` in `.env`)
- Avoid renaming services casually
- Use `profiles:` instead of separate partially-overlapping compose files

### 1.2 Duplicate containers from different project names

**Symptom:** Duplicate containers running the same image. Port conflicts. Compose says "container already exists."

**Why:** The same stack was started from a different folder, with a different `-p` flag, or with a different `COMPOSE_PROJECT_NAME`. Compose treats each project name as a separate stack, creating parallel containers.

**Fix:**

```bash
# Find all running Compose projects
docker compose ls

# Identify and shut down the duplicate
docker compose -p old-project-name down --remove-orphans
```

**Prevention:**

- Always run from the same directory, OR
- Set an explicit `COMPOSE_PROJECT_NAME` in `.env`
- Add a note in your project docs: "Always run from the project root directory"

### 1.3 `docker compose down` did not remove everything

**Symptom:** Containers gone but disk usage still high. Old images, volumes, and build cache remain.

**Why:** `docker compose down` removes project containers and networks by default. It does **not** remove images, volumes, or build cache unless you add flags.

**Fix (project-scoped):**

```bash
docker compose down --remove-orphans --volumes --rmi local
```

**Fix (global cleanup):**

```bash
docker system prune          # Safe: stopped containers, unused networks, dangling images
docker system prune -a       # Aggressive: also removes all unused images
```

> **Warning:** `--volumes` and `-a` are destructive. Understand what they delete before running.

### 1.4 Data "disappeared" after recreate

**Symptom:** App starts fresh. Database or config seems reset after `up --force-recreate` or `down -v`.

**Why:** Data was stored in:

- An **anonymous volume** (not named — gets a random ID)
- The **container filesystem** (not a volume at all)
- A **named volume** removed by `down -v`

**Fix:** Restore from backup if available.

**Prevention:**

- Use explicit named volumes or bind mounts for all persistent data
- Document which services are stateful and which volumes hold critical data
- Never run `down -v` without understanding what it deletes
- Back up volumes before any destructive operation

### 1.5 Port conflicts ("address already in use")

**Symptom:** Compose fails to start a service with "bind: address already in use."

**Common causes:**

- Another app or container is using the port
- An orphan container from a duplicate project
- A previous `docker compose up` that didn't fully shut down

**Fix:**

```bash
# Find what's using the port
docker ps --format "table {{.Names}}\t{{.Ports}}"

# Or check the host directly
sudo lsof -i :8080    # Linux/macOS
sudo ss -tlnp | grep 8080

# Remove orphans and retry
docker compose down --remove-orphans
docker compose up -d
```

### 1.6 "Works on Linux, broken/slow on Docker Desktop"

**Symptom:** Slow bind mounts on macOS/Windows. File watcher issues. Host networking assumptions fail.

**Why:** Docker Desktop runs Linux containers inside a VM. Filesystem access, networking, and device passthrough behave differently from native Linux.

**Fix:**

- Use named volumes for heavy I/O (databases, large data directories)
- Tune polling/watch settings for development tools
- See the [cross-platform compatibility](BEST-PRACTICES.md#15-cross-platform-compatibility) section

### 1.7 Service can't connect to another service

**Symptom:** "Connection refused" between containers. App tries `localhost:5432` for the database and fails.

**Why:** Inside a Compose network, `localhost` means the container itself, not another container. Services reach each other by **service name**.

**Fix:** Use the service name as the hostname:

```yaml
# In your app's config or environment
DATABASE_URL=postgres://app:password@database:5432/app
#                                     ^^^^^^^^
#                                     Service name, NOT localhost
```

**Rule:** Never use `localhost` to reach another container. Use the service name defined in the compose file.

---

## 2. Debugging playbook

Follow these steps in order when something isn't working.

### Step 1: Validate the Compose file

```bash
docker compose config
```

This catches:

- YAML syntax errors
- Environment variable interpolation issues
- Merge/anchor problems
- Duplicate or conflicting keys

> **Tip:** Use `docker compose config --quiet` in CI to validate before deploying.

### Step 2: Check what's running

```bash
docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"
```

Look for:

- Exited or restarting containers
- Duplicate stacks (same image, different project names)
- Unexpected port bindings

### Step 3: Check the Compose project

A lot of "weirdness" is actually a project name mismatch.

```bash
docker compose ls
```

Compare the project name with:

- Your current directory name
- `name:` in the compose file
- `COMPOSE_PROJECT_NAME` in `.env`
- Any scripts using `-p`

### Step 4: Check logs

```bash
docker compose logs                      # All services
docker compose logs -f app               # Follow one service
docker compose logs --tail=100 app       # Last 100 lines
```

Look for:

- Startup ordering failures
- Healthcheck failures
- Permission denied errors
- Missing environment variables
- Database authentication failures
- Port bind errors

### Step 5: Inspect container state

When a container is restart-looping:

```bash
docker compose ps                                         # Status overview
docker inspect <container> --format='{{.State.ExitCode}}'  # Exit code
docker inspect <container> --format='{{json .State.Health}}' | python3 -m json.tool  # Health
docker inspect <container> | grep -i oom                   # OOM kill check
```

Common exit codes:

| Code | Meaning |
|------|---------|
| 0 | Clean exit |
| 1 | Application error |
| 137 | SIGKILL (OOM killed or `docker stop` timeout) |
| 139 | Segfault |
| 143 | SIGTERM (graceful shutdown) |

### Step 6: Check healthchecks

A service may be "running" but still **unhealthy**.

```bash
docker compose ps                        # Shows health status
docker inspect --format='{{json .State.Health}}' <container>
```

Common healthcheck issues:

- Command path wrong inside the image (binary doesn't exist)
- Service starts slowly (needs longer `start_period`)
- Checking `localhost` when it should be `127.0.0.1` (or vice versa)
- Endpoint requires authentication but probe doesn't provide it
- Using `CMD-SHELL` in a distroless/minimal image with no shell

### Step 7: Check networking

```bash
# From inside a container, test connectivity to another service
docker exec -it app ping database
docker exec -it app wget -qO- http://database:5432 2>&1 | head -5

# List networks and which containers are on each
docker network ls
docker network inspect <network_name> --format='{{range .Containers}}{{.Name}} {{end}}'
```

### Step 8: Check volumes and permissions

```bash
# Check mount configuration
docker inspect <container> --format='{{json .Mounts}}' | python3 -m json.tool

# Check inside the container
docker exec -it <container> ls -la /data
docker exec -it <container> id    # What user is the container running as?
```

Common issues:

- UID/GID mismatch between host directory and container user
- `read_only: true` when the app needs to write somewhere
- SELinux context issues on Fedora/RHEL (need `:z` or `:Z` suffix)

---

## 3. Common errors and fixes

### "port is already allocated"

```text
Error response from daemon: driver failed programming external connectivity:
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Fix:**

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}" | grep 8080
docker compose down --remove-orphans
# Then retry, or change the port mapping
```

### "network ... not found"

```text
Error response from daemon: network abc123 not found
```

**Fix:**

```bash
docker compose down --remove-orphans
docker network prune
docker compose up -d
```

If it persists, check for project name mismatches (`docker compose ls`).

### Service stuck in "Restarting"

**Fix workflow:**

```bash
docker compose logs <service>                    # Check the error
docker inspect <container> --format='{{.State.ExitCode}}'  # Check exit code
docker inspect <container> | grep -i oom         # Check OOM
```

Common causes:

- Missing environment variable or misconfigured env
- Dependency not ready (database not accepting connections yet)
- Permission denied on mounted volumes
- Out of memory (exit code 137)

### "Cannot connect to database/cache"

**Fix:**

1. Use the service DNS name (`database`, `redis`), not `localhost`
2. Check the dependency is healthy: `docker compose ps`
3. Verify credentials: `docker compose config | grep PASSWORD`
4. Check both services are on the same network

### Changes to compose file not taking effect

**Fix:**

```bash
docker compose down --remove-orphans
docker compose up -d --force-recreate
```

If the issue is stale data in a volume:

```bash
docker compose down -v    # WARNING: deletes volumes
docker compose up -d
```

### "image not found" or "manifest unknown"

**Fix:**

```bash
# Verify the exact tag exists
docker manifest inspect <image>:<tag>

# Check for typos, or tag naming differences
# (e.g., 2.1.2 vs 2.1.2-alpine)
```

---

## 4. Cleanup and prune strategy

From safest to most aggressive:

### Level 1: Project cleanup (safe)

Removes only containers and networks for the current Compose project:

```bash
docker compose down --remove-orphans
```

### Level 2: Project cleanup + volumes + images

Also removes project volumes and locally-built images:

```bash
docker compose down --remove-orphans --volumes --rmi local
```

> **Warning:** `--volumes` deletes persistent data. Back up first.

### Level 3: Remove stopped containers globally

```bash
docker container prune
```

### Level 4: Targeted resource cleanup

```bash
docker image prune          # Dangling images only
docker image prune -a       # All unused images (not just dangling)
docker volume prune          # Volumes not attached to any container
docker network prune         # Unused networks
```

> **Warning:** `docker volume prune` can remove volumes not currently attached to any container. If your containers are stopped, their volumes may appear "unused."

### Level 5: Full global cleanup (use carefully)

```bash
docker system prune                # Stopped containers + unused networks + dangling images + build cache
docker system prune -a --volumes   # Everything above + ALL unused images + ALL unused volumes
```

> **Warning:** `docker system prune -a --volumes` is the nuclear option. It will remove anything not currently attached to a running container. Treat it as a maintenance operation, not a daily workflow.

### Disk usage report

See what Docker is using before deciding what to prune:

```bash
docker system df             # Summary
docker system df -v          # Detailed breakdown
```

---

## 5. Reset recipes

### Safe reset (keep persistent data)

```bash
docker compose down --remove-orphans
docker compose up -d --remove-orphans
```

### Rebuild reset (keep persistent data, rebuild images)

```bash
docker compose down --remove-orphans
docker compose up -d --build --force-recreate --remove-orphans
```

### Hard reset (delete project volumes too)

```bash
# WARNING: This deletes all data in project volumes
docker compose down --remove-orphans --volumes --rmi local
docker compose up -d --build
```

### Global disk cleanup (not project-specific)

```bash
# Show what will be affected
docker system df

# Remove everything unused
docker system prune -a --volumes
```

---

## 6. Troubleshooting decision tree

```text
Stack won't start?
  └─→ Run: docker compose config
      └─→ YAML error? Fix syntax
      └─→ Valid? Check: docker compose up (without -d) to see errors live

Service starts then dies?
  └─→ Run: docker compose logs <service>
      └─→ Permission denied? Check volume ownership + user
      └─→ Connection refused? Check service names + network
      └─→ OOM killed (exit 137)? Increase mem_limit
      └─→ Missing env var? Check .env + docker compose config

Port conflict?
  └─→ Run: docker ps --format "table {{.Names}}\t{{.Ports}}"
      └─→ Orphan container? docker compose down --remove-orphans
      └─→ Another app? Change port mapping or stop the app

Duplicate containers?
  └─→ Run: docker compose ls
      └─→ Multiple projects? Shut down the extra: docker compose -p <name> down

Disk full?
  └─→ Run: docker system df
      └─→ Images? docker image prune -a
      └─→ Build cache? docker builder prune
      └─→ Volumes? docker volume prune (careful!)
      └─→ Logs? Check log rotation config

Data missing after restart?
  └─→ Was -v used with down? Data is gone — restore from backup
  └─→ Data in anonymous volume? Migrate to named volume or bind mount
  └─→ Data in container filesystem? Add a volume mount

Healthcheck failing?
  └─→ Run: docker inspect --format='{{json .State.Health}}' <container>
      └─→ Command not found? Use CMD not CMD-SHELL in minimal images
      └─→ Connection refused? Increase start_period
      └─→ Auth required? Use an unauthenticated endpoint
```

---

## 7. Prevention best practices

| Practice | Why |
|----------|-----|
| Set an explicit project name | Prevents duplicate stacks from directory name drift |
| Document which services are stateful | Makes it clear what needs backup and what's safe to delete |
| Use healthchecks + sensible `start_period` | Prevents dependency race conditions on startup |
| Avoid `container_name` unless required | Allows scaling and parallel stacks |
| Prefer internal-only ports | Reduces accidental exposure |
| Run `docker compose config` in CI | Catches config errors before deployment |
| Back up volumes before destructive commands | `down -v` and `prune` are irreversible |
| Use `--remove-orphans` with `up` and `down` | Prevents orphan container accumulation |
| Never use `localhost` to reach another container | Use the service name instead |
| Check `docker compose ls` when things look wrong | Project name mismatches cause most "phantom" issues |

---

## See also

- [Docker Basics](DOCKER-BASICS.md) — core concepts, installation, alternative runtimes
- [Best Practices](BEST-PRACTICES.md) — detailed reference for building stacks right
- [Helper Scripts](../scripts/) — automated reset, cleanup, and disk reporting

---

[← Back to README](../README.md)
