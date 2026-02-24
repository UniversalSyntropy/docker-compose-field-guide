# Docker Compose Field Guide — local validation
# Run these before pushing. CI runs the same checks.
#
# Usage:
#   make lint          — run all checks
#   make lint-yaml     — YAML lint only
#   make lint-md       — Markdown lint only
#   make lint-shell    — ShellCheck only
#   make lint-lines    — giant-line regression check
#   make compose-check — validate Compose files
#   make link-check    — check internal doc links

.PHONY: lint lint-yaml lint-md lint-shell lint-lines compose-check link-check

lint: lint-yaml lint-md lint-shell lint-lines compose-check
	@echo ""
	@echo "All checks passed."

# ── YAML ──────────────────────────────────────────────────────────────
lint-yaml:
	@echo "=== YAML lint ==="
	@command -v yamllint >/dev/null 2>&1 \
		&& yamllint -d '{extends: default, rules: {line-length: {max: 300}, truthy: disable, document-start: disable}}' . \
		|| docker run --rm -v "$(CURDIR):/work:ro" -w /work pipelinecomponents/yamllint yamllint -d '{extends: default, rules: {line-length: {max: 300}, truthy: disable, document-start: disable}}' .

# ── Markdown ──────────────────────────────────────────────────────────
lint-md:
	@echo "=== Markdown lint ==="
	@command -v markdownlint-cli2 >/dev/null 2>&1 \
		&& markdownlint-cli2 '**/*.md' \
		|| docker run --rm -v "$(CURDIR):/work:ro" -w /work davidanson/markdownlint-cli2 '**/*.md'

# ── Shell ─────────────────────────────────────────────────────────────
lint-shell:
	@echo "=== ShellCheck ==="
	@command -v shellcheck >/dev/null 2>&1 \
		&& shellcheck scripts/*.sh \
		|| docker run --rm -v "$(CURDIR):/work:ro" koalaman/shellcheck scripts/*.sh

# ── Giant-line regression ─────────────────────────────────────────────
lint-lines:
	@echo "=== Giant-line check (max 300 chars) ==="
	@status=0; \
	for f in $$(find . -type f \( -name '*.md' -o -name '*.yml' -o -name '*.yaml' -o -name '*.sh' -o -name '*.json' -o -name '*.jsonc' -o -name '.env*' \) ! -path './.git/*'); do \
		result=$$(awk 'length > 300 {printf "  line %d: %d chars\n", NR, length}' "$$f"); \
		if [ -n "$$result" ]; then \
			echo "FAIL: $$f"; \
			echo "$$result"; \
			status=1; \
		fi; \
	done; \
	if [ "$$status" -eq 0 ]; then echo "PASS: No lines exceed 300 characters."; fi; \
	exit "$$status"

# ── Compose validation ────────────────────────────────────────────────
compose-check:
	@echo "=== Compose validation ==="
	@docker compose config --quiet 2>/dev/null \
		|| echo "SKIP: docker-compose.yml requires .env + secrets (see README Quick Start)"
	@docker compose -f monitoring/docker-compose.yml config --quiet
	@for f in recipes/*.yml; do \
		echo "Validating $$f..."; \
		docker compose -f "$$f" config --quiet 2>/dev/null \
			|| echo "SKIP: $$f requires secrets (see recipe header)"; \
	done

# ── Link check (local — offline, internal links only) ─────────────────
link-check:
	@echo "=== Internal link check ==="
	@command -v lychee >/dev/null 2>&1 \
		&& lychee --no-progress --offline '**/*.md' \
		|| docker run --rm -v "$(CURDIR):/work:ro" -w /work lycheeverse/lychee --no-progress --offline '**/*.md'
