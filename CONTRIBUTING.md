# Contributing

Thanks for considering a contribution. This guide is a community reference —
improvements to accuracy, clarity, and coverage are always welcome.

## Running checks locally

```bash
make lint          # runs all checks (YAML, Markdown, ShellCheck, line length, Compose validation)
make link-check    # check internal doc links (optional, not in default lint)
```

CI runs the same checks on every push and pull request.
If a check fails, the output tells you which file and line caused the issue.

## What's welcome

- Corrections to security advice or outdated information
- New examples or recipes (Compose snippets, helper scripts)
- Improvements to clarity, grammar, or formatting
- CI and tooling improvements
- Platform-specific notes (Linux, macOS, Windows/WSL2, Raspberry Pi)

## What needs discussion first

Open an issue before submitting a PR if you want to:

- Restructure the docs or change the overall organization
- Add a new top-level section to BEST-PRACTICES.md
- Change the scope of the guide (e.g. adding Kubernetes or Swarm coverage)
- Add heavy dependencies to the CI pipeline

## Pull request expectations

- **One logical change per PR.** Separate formatting fixes from content changes.
- **Describe what and why** in the PR description.
- **Run `make lint`** before pushing. All checks must pass.
- **If you change security advice**, explain the rationale and cite a source
  (CIS Benchmark, OWASP, Docker docs, or equivalent).

## Style

Follow the voice and writing guidelines in [docs/STYLE.md](docs/STYLE.md).

Key points:

- Write for someone who knows basic Linux but may not know Docker internals
- Be direct — no hype, no filler
- Prefer "you" over "the user"
- Include the *why*, not just the *what*

## Commit messages

No enforced format. Keep them short and descriptive.
A good commit message says what changed and why in one line.
