# Voice & Style Guide

How this repo should sound — and why it matters. Use this when writing new sections, reviewing PRs, or prompting AI tools to contribute.

---

## The Short Version

Write like a helpful colleague who has done this before. Be honest about trade-offs, specific about context, and brief enough that someone scanning at 2am can find what they need.

---

## Voice Profile

| Do | Don't |
|----|-------|
| Friendly — like explaining something to a colleague | Casual-chaotic — no forced jokes, no profanity |
| Practical — concrete actions over abstract advice | Preachy — don't lecture; show the better way |
| Confident — say what works and why | Absolute — avoid "always", "never", "the best" without scope |
| Helpful — anticipate follow-up questions | Patronising — don't over-explain things the audience already knows |
| Honest about trade-offs | Overconfident — don't promise "secure" or "production-ready" without caveats |
| Specific about scope (homelab vs public internet) | Vague — "just use best practices" is not guidance |

---

## Audience

This repo targets people who:

- Run a homelab or self-hosted setup (Raspberry Pi, NUC, NAS, small server)
- Know the basics of Linux and the terminal
- Have run at least one Docker container before
- Want to do things properly but don't have time to read the CIS Benchmark end-to-end

It is **not** aimed at:

- Complete beginners who have never used a terminal (though [DOCKER-BASICS.md](DOCKER-BASICS.md) offers a starting point)
- Large-scale production / enterprise Kubernetes deployments
- Swarm, Nomad, or other orchestrators

---

## Phrasing Rules

### Prefer

| Instead of | Write |
|------------|-------|
| production-ready | hardened baseline / production-oriented starting point |
| secure | more secure baseline / reduces your attack surface |
| best practice | common best practice / recommended default |
| robust, scalable, enterprise-grade | *(describe the actual behaviour)* |
| seamless | *(explain what's simplified and what still needs work)* |
| comprehensive | covers the common cases / detailed reference |
| ensure | check / verify / confirm |
| utilize | use |
| leverage | use |
| implement | add / set up / configure |

### Scope your claims

- **Good:** "This works well for a homelab LAN. If you expose services publicly, add a reverse proxy with TLS."
- **Bad:** "This makes your stack secure."

- **Good:** "A safe default for most services. Some apps (e.g., Mosquitto, MariaDB) need extra capabilities — see the capability table."
- **Bad:** "Always drop all capabilities."

- **Good:** "`read_only: true` prevents writes to the container filesystem. Many apps break on first try — that's normal. Add `tmpfs` mounts for `/tmp` and `/run`, then test."
- **Bad:** "Make your containers read-only for security."

### Be explicit about context

Every recommendation should make it clear:

1. **Who** it applies to (all services? databases? homelab only?)
2. **Why** it matters (what goes wrong without it)
3. **When** to relax it (and what compensates)

### Keep it scannable

- Short paragraphs (3–4 lines max in running text)
- Bullets over prose where possible
- Tables for comparisons
- Code blocks for anything the reader will type
- `> **Gotcha:**` callouts for non-obvious failure modes
- "If X, do Y" structure for decision guidance

---

## Recurring Phrases to Avoid

These phrases weaken trust because they sound like marketing copy or AI filler. Replace them with specifics.

| Avoid | Why it's weak | Replace with |
|-------|--------------|-------------|
| "robust" | Means nothing without context | Describe the actual resilience mechanism |
| "seamless" | Almost never true | Describe what's simplified and what's still manual |
| "enterprise-grade" | Scope mismatch — this is a homelab guide | Drop it, or say "borrowed from enterprise practice" |
| "bulletproof" | No security is | "reduces risk" / "raises the bar" |
| "cutting-edge" | Vague hype | Name the specific tool or feature |
| "best-in-class" | Compared to what? | Drop it |
| "powerful" | Says nothing about what it does | Describe the capability |
| "simple" / "easy" / "just" | Dismisses real difficulty | "Straightforward if you..." / explain the steps |
| "production-ready" (unqualified) | Implies testing that hasn't been done | "production-oriented baseline" or list what's missing |
| "state-of-the-art" | Vague | Name the standard (CIS, OWASP, etc.) |

---

## Tone Benchmarks

These repos model specific aspects of the voice we're aiming for. Borrow the *style patterns*, not the content.

| Benchmark | What to learn from it |
|-----------|----------------------|
| [DoTheEvo/selfhosted-apps-docker](https://github.com/DoTheEvo/selfhosted-apps-docker) | Practical human voice, "guide-by-example" methodology, clear core concepts section |
| [jgwehr/homelab-docker](https://github.com/jgwehr/homelab-docker) | Values-first framing ("security, privacy, data-ownership"), "Practical Security" as a category name, honest about trade-offs |
| [docker/awesome-compose](https://github.com/docker/awesome-compose) | Clarity through brevity, unambiguous warnings, clean sample formatting |
| [Haxxnet/Compose-Examples](https://github.com/Haxxnet/Compose-Examples) | Discoverability, consistent per-service structure, the `DOCKER_VOLUME_STORAGE` convention |

**The blend we want:** Easy to find what I need (Haxxnet) + clean and consistent (awesome-compose) + sounds like a helpful human who has done this before (DoTheEvo) + doesn't pretend homelab ops are simple (jgwehr).

---

## Checklist for New Content

Before merging new copy, check:

- [ ] No filler adjectives (robust, powerful, seamless, enterprise-grade)
- [ ] Claims are scoped (who, when, under what conditions)
- [ ] Trade-offs are stated, not hidden
- [ ] Homelab vs internet-facing distinction is clear where relevant
- [ ] Sections are scannable (bullets, tables, short paragraphs)
- [ ] Code examples are copy-pasteable and tested
- [ ] Gotcha callouts explain *why* something fails, not just *that* it fails
- [ ] No "just do X" — explain the steps or link to them

---

[← Back to README](../README.md)
