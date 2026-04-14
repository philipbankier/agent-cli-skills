# The Agent CLI Ecosystem

A curated map of the surrounding ecosystem and where this repo fits.
Star counts and `pushed_at` dates verified via `gh api` on 2026-04-14.

## How to Read This

The CLI agent ecosystem is fragmented across many independent projects. Some are official; some are community-curated lists; some are skill marketplaces; some are runtime infrastructure. This page sorts them by **what they do** and explains where `agent-cli-skills` sits relative to each.

Our position: **verified, cross-CLI documentation and patterns.** We are not a marketplace, we are not a runtime, and we are not an "awesome list" trying to index every project. We explain how the CLIs work, what flags do what, where the gotchas are, and how to write code that works across all three. Every claim is verified against live `--help` output or an authoritative source.

## Official Repositories

| Project | Stars | Description | What we add on top |
|---------|------:|-------------|--------------------|
| [anthropics/skills](https://github.com/anthropics/skills) | ~116k | The official Agent Skills repo from Anthropic. Defines the `SKILL.md` frontmatter spec and ships canonical examples. | We document how `SKILL.md` skills work in practice across all three CLIs, including the platform-specific differences in discovery and packaging. |
| [openai/codex](https://github.com/openai/codex) | (varies) | Official Codex CLI source. Authoritative for `codex` flags, releases, issues. | We document the *cross-CLI* equivalences for Codex flags and call out behaviors that aren't in `--help`. |
| [google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli) | (varies) | Official Gemini CLI source. Authoritative for `gemini` flags, releases, issues. | We document the cross-CLI equivalences and surface features that aren't well-known (e.g., `gemini hooks migrate`). |
| [modelcontextprotocol](https://github.com/modelcontextprotocol) | (varies) | The official MCP spec — the protocol layer all three CLIs use for tool integration. | We document the practical cross-CLI usage of MCP through each CLI's `mcp` subcommand. |

## Curation & Discovery (Awesome Lists)

These projects index everything in the ecosystem. They are great for *finding* things; they don't try to teach you how each CLI works. We complement them — they're the index, we're the docs.

| Project | Stars | What it does |
|---------|------:|--------------|
| [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) | ~38k | The de facto curated list of skills, hooks, slash commands, sub-agents, plugins, and applications for Claude Code. Updated frequently. |
| [punkpeye/awesome-mcp-servers](https://github.com/punkpeye/awesome-mcp-servers) | ~85k | The largest curated MCP server directory. 30+ categories. |

> If you're looking for a specific skill or MCP server to use, start with these. If you're trying to understand *how* the CLIs work or write portable cross-CLI code, this repo is the better starting point.

## Methodology + Skill Frameworks

| Project | Stars | What it does | Relationship to us |
|---------|------:|--------------|--------------------|
| [obra/superpowers](https://github.com/obra/superpowers) | ~149k | An agentic skills framework + software development methodology. Auto-activating skills via context matching, mandatory workflow phases (Design → Plan → Execute), TDD enforcement. | Their skill-loading and methodology layer is more opinionated than ours. We document the underlying CLI primitives they build on top of. They are "how to *use* skills"; we are "how skills *work* across CLIs." |
| [rohitg00/skillkit](https://github.com/rohitg00/skillkit) | ~770 | A portable skill standard. `skillkit` aims to install a single skill across 40+ AI tools (Claude, Cursor, Codex, Copilot, etc.). | Closely related to our cross-platform skill installation guide. We document the *native* installation paths and the gaps; SkillKit is one tool that tries to bridge those gaps. |

## Runtime Infrastructure: API Proxies

| Project | Stars | What it does | When to use |
|---------|------:|--------------|-------------|
| [router-for-me/CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) | ~26k | Production-ready Go proxy that exposes Claude/Codex/Gemini/Qwen/iFlow CLI OAuth credentials as OpenAI/Claude/Gemini-compatible API endpoints. Multi-account load balancing, format translation, Docker deployment. | When you want to use your CLI subscription with an SDK-based application (LiteLLM, LangChain, your own app). |
| [ranaroussi/cc-bridge](https://github.com/ranaroussi/cc-bridge) | ~49 | A simpler, Claude-only HTTP bridge that wraps `claude -p` as an Anthropic-compatible API. | When you want to *understand* how CLI-to-API bridging works at the simplest level, or build your own. CLIProxyAPI is the production answer. |

We document the "when to use which" decision in [`patterns/api-proxy-pattern.md`](patterns/api-proxy-pattern.md) and the LiteLLM integration story in [`patterns/litellm-integration.md`](patterns/litellm-integration.md).

## Plugin & Extension Ecosystems

These are platform-specific. They live inside the marketplace systems each CLI provides:

- **Claude Code**: official marketplace via `claude plugin marketplace`, plus community-curated alternates listed in awesome-claude-code
- **Codex CLI**: no first-party plugin system; capabilities flow through MCP server registration
- **Gemini CLI**: native `gemini extensions install <git-url>` with no marketplace gatekeeper

For a side-by-side comparison of how to package and install a skill that works on all three, see [`patterns/skill-installation.md`](patterns/skill-installation.md).

## Where We Sit

A simple way to think about the ecosystem layers and where each project lives:

```
┌─────────────────────────────────────────────────────────────────┐
│  Discovery / curation                                           │
│  ─────────────────                                              │
│  awesome-claude-code, awesome-mcp-servers                       │
│  ("here is everything that exists")                             │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  Methodology / framework                                        │
│  ────────────────────                                           │
│  obra/superpowers, skillkit                                     │
│  ("here is how to USE skills with a workflow")                  │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  Documentation / verified knowledge   ← THIS REPO               │
│  ──────────────────────────────────                             │
│  agent-cli-skills                                               │
│  ("here is how each CLI actually works, what every flag does,   │
│   what's verified, and how to write portable cross-CLI code")   │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  Runtime infrastructure                                         │
│  ─────────────────────                                          │
│  CLIProxyAPI, cc-bridge                                         │
│  ("here is how to expose CLI auth as an SDK-compatible API")    │
└─────────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────────┐
│  Official sources                                               │
│  ────────────────                                               │
│  anthropics/claude-code, openai/codex, google-gemini/gemini-cli │
│  modelcontextprotocol                                           │
│  ("here is the source of truth — but no cross-CLI synthesis")   │
└─────────────────────────────────────────────────────────────────┘
```

## What This Repo Does Differently

- **Verified > comprehensive.** Every flag, subcommand, and example is checked against live `--help` output before it lands in the docs. We've caught and removed multiple fabricated entries (e.g., `--max-turns` in Claude Code, `-f/--free` in Gemini CLI) that survived earlier audit rounds because they only checked names, not behaviors.
- **Cross-CLI > single-CLI.** We are not a Claude-only or Codex-only resource. The hard problems — porting hooks, packaging skills, choosing between sandbox layers — only exist in the cross-CLI space.
- **Patterns > recipes.** A recipe is "here is a script that does X." A pattern is "here is the abstraction the CLIs converged on, here are the per-CLI knobs that implement it, here is when to reach for it." Patterns survive version bumps; recipes don't.
- **Per-version verification.** Each commit pins which CLI version the content was verified against. If you upgrade and behavior changes, you have a clear pivot point.

## See Also

- [comparison.md](comparison.md) — feature-by-feature comparison matrix
- [migration-guide.md](migration-guide.md) — porting automations between CLIs
- [patterns/](patterns/) — all the cross-platform pattern guides
- [../skill-authoring/cross-platform.md](../skill-authoring/cross-platform.md) — designing skills that work across all three CLIs
