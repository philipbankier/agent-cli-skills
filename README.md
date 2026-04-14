# agent-cli-skills

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Claude Code](https://img.shields.io/badge/Claude%20Code-skill-blue)](skills/claude-code/)
[![Codex CLI](https://img.shields.io/badge/Codex%20CLI-skill-green)](skills/codex-cli/)
[![Gemini CLI](https://img.shields.io/badge/Gemini%20CLI-skill-red)](skills/gemini-cli/)

**The open-source skill library for AI CLI agents.**

Teach Claude Code, Codex CLI, and Gemini CLI to automate themselves — non-interactive scripting, structured output, multi-agent orchestration, CI/CD integration, and skill authoring.

### Verified Against

Flags, JSON output shapes, and examples have been tested against these versions. **Last verified: 2026-04-14.**

| CLI | Tested against | Latest upstream | Status |
|-----|----------------|-----------------|--------|
| Claude Code | v2.1.104 | v2.1.104 | Fully tested — flags verified live, examples run with captured output |
| Codex CLI | v0.114.0 | v0.120.0 | Local install verified live; gap to upstream tracked in this commit batch |
| Gemini CLI | v0.33.0 | v0.37.1 | Subcommand APIs verified live; example scripts community-contributed, not run end-to-end |

> **Gemini CLI example contributors welcome!** Subcommand surface (`gemini skills`, `gemini extensions`, `gemini hooks`) is now verified, but the multi-agent example scripts have not been run end-to-end. If you have Gemini CLI configured, please run them and submit a PR with corrections and sample output.

CLI interfaces change between versions. If you find a discrepancy, [open an issue](../../issues/new/choose) with your CLI version.

## Why This Exists

An agent can run `claude --help` and figure things out. So why does this repo exist?

**`--help` doesn't tell you what fails silently.** Nested `claude -p` calls produce empty output from within Claude Code. `codex exec` defaults to `danger-full-access` sandbox. `grep -o '{.*}'` breaks on multi-line JSON from CLI output. `--permission-mode delegate` doesn't exist despite looking plausible. These gotchas only surface by running the tools and failing — we've done that so your agent doesn't have to.

**Cross-platform patterns don't exist anywhere else.** No CLI's docs explain how to port a script from Claude to Codex, set up CLIProxyAPI with LiteLLM, or build a multi-agent debate engine across all three CLIs. Each vendor documents their own tool in isolation.

**Pre-computed research saves tokens.** An agent exploring from scratch burns thousands of tokens and dozens of tool calls to discover what each flag does. These skills front-load that research into a single file read.

This repo is also a practical guide to **writing skills** for each CLI platform, including a cross-platform skill design guide for building portable agent extensions.

## Quick Install

Each skill is independently installable. The install scripts use sparse checkout to install only the skill you need at the correct path for discovery:

```bash
# Install the Claude Code skill → .claude/skills/claude-code-automation/
curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-claude.sh | bash

# Install the Codex CLI skill → .agents/skills/codex-cli-automation/
curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-codex.sh | bash

# Install the Gemini CLI skill → .gemini/skills/gemini-cli-automation/
curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-gemini.sh | bash
```

## What's Inside

### Skills (per-CLI, independently installable)

| Skill | CLI | Non-Interactive | Structured Output | Streaming | Unique Strength |
|-------|-----|-----------------|-------------------|-----------|-----------------|
| [**claude-code**](skills/claude-code/SKILL.md) | Claude Code | `claude -p` | `--json-schema` | NDJSON | CC-Bridge API wrapper, SDK integration |
| [**codex-cli**](skills/codex-cli/SKILL.md) | Codex CLI | `codex exec` | `--json` | JSON events | Session resume, AGENTS.md (cross-tool config) |
| [**gemini-cli**](skills/gemini-cli/SKILL.md) | Gemini CLI | `gemini -p` | `--output-format json` | JSONL | Free tier (1000 req/day), extensions system |

### CLI Comparison At-a-Glance

| Feature | Claude Code | Codex CLI | Gemini CLI |
|---------|-------------|-----------|------------|
| Non-interactive flag | `claude -p "prompt"` | `codex exec "prompt"` | `gemini -p "prompt"` |
| JSON output | `--output-format json` | `--json` | `--output-format json` |
| Auto-approve | `--dangerously-skip-permissions` | `--full-auto` + `--dangerously-bypass-approvals-and-sandbox` | `-y` / `--yolo` |
| Config file | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` |
| Skill directory | `.claude/skills/` | `.agents/skills/` | `.gemini/skills/` |
| Install | `npm i -g @anthropic-ai/claude-code` | `npm i -g @openai/codex` | `npm i -g @google/gemini-cli` |

See [cross-platform/comparison.md](cross-platform/comparison.md) for the full feature matrix.

### Cross-Platform Guides

- [CLI Comparison Matrix](cross-platform/comparison.md) — side-by-side feature reference
- [Migration Guide](cross-platform/migration-guide.md) — porting automations between CLIs
- [Multi-Agent Patterns](cross-platform/patterns/parallel-agents.md) — orchestration across all 3
- [CI/CD Templates](cross-platform/patterns/ci-cd-matrix.md) — GitHub Actions for each CLI
- [Structured Output Patterns](cross-platform/patterns/structured-output.md) — JSON schema per CLI
- [Subagent Orchestration](cross-platform/patterns/subagent-orchestration.md) — worktrees, tmux, parallel agents across all three CLIs
- [Cost Control](cross-platform/patterns/cost-control.md) — bound spend, optimize prompt caching, pick the right knobs
- [OS Sandboxing](cross-platform/patterns/os-sandboxing.md) — in-CLI gating vs OS-level isolation (the only place `codex sandbox` is fully documented)
- [Skill Installation](cross-platform/patterns/skill-installation.md) — packaging one skill that installs cleanly on all three CLIs
- [Hook Migration](cross-platform/patterns/hook-migration.md) — `gemini hooks migrate` and manual port recipes
- [API Proxy Pattern](cross-platform/patterns/api-proxy-pattern.md) — CLIProxyAPI, CC-Bridge, and when to use each
- [LiteLLM Integration](cross-platform/patterns/litellm-integration.md) — Use CLI subscriptions as LiteLLM backends
- [Ecosystem Map](cross-platform/ecosystem.md) — how this repo relates to anthropics/skills, obra/superpowers, awesome-claude-code, CLIProxyAPI, and the rest of the CLI agent landscape

### Verified Known Issues

Per-CLI lists of confirmed-real GitHub issues with reproducible workarounds. Every entry is verified via `gh api` against the upstream issue tracker.

- [Claude Code known issues](skills/claude-code/reference/known-issues.md)
- [Codex CLI known issues](skills/codex-cli/reference/known-issues.md)
- [Gemini CLI known issues](skills/gemini-cli/reference/known-issues.md)

### Skill Authoring

Want to build your own skills? These guides cover each platform's skill format and an advanced cross-platform approach:

- [Write skills for Claude Code](skill-authoring/claude-code.md)
- [Write skills for Codex CLI](skill-authoring/codex-cli.md)
- [Write skills for Gemini CLI](skill-authoring/gemini-cli.md)
- [Cross-platform skill design](skill-authoring/cross-platform.md) — one skill, three CLIs

## Flagship Example: Multi-Perspective Debate Engine

The debate engine spawns 5 AI "debaters" in parallel — Optimist, Skeptic, Historian, Futurist, and Practitioner — each with structured JSON output. A Moderator synthesizes the arguments. Available for all three CLIs:

```bash
# Claude Code
./skills/claude-code/examples/debate-engine/debate.sh "Should AI replace teachers?"

# Codex CLI
./skills/codex-cli/examples/debate-engine/debate.sh "Should AI replace teachers?"

# Gemini CLI
./skills/gemini-cli/examples/debate-engine/debate.sh "Should AI replace teachers?"
```

Each version uses the same pattern but with platform-specific flags and idioms. Compare them to understand the differences between CLIs.

## Project Structure

```
agent-cli-skills/
├── skills/
│   ├── claude-code/          # Claude Code automation skill
│   ├── codex-cli/            # Codex CLI automation skill
│   └── gemini-cli/           # Gemini CLI automation skill
├── cross-platform/           # Comparison, migration, shared patterns
├── skill-authoring/          # How to write skills for each CLI
├── install/                  # One-liner install scripts
├── CONTRIBUTING.md
└── LICENSE
```

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Most valuable contributions:
- New multi-agent examples for any CLI
- Flag documentation updates as CLIs evolve
- Code snippets in additional languages
- Corrections to gotchas or flag interactions
- New cross-platform patterns

## Disclaimer

> **This is an independent community project and is not affiliated with, endorsed by, or approved by Anthropic, OpenAI, or Google.** Use at your own risk.

- **Terms of Service** — Using CLI agents for automation may be subject to each vendor's usage policies. Review [Anthropic's](https://www.anthropic.com/legal/aup), [OpenAI's](https://openai.com/policies/usage-policies), and [Google's](https://ai.google.dev/terms) terms before deploying in production.
- **CC-Bridge** — The bridge proxies Claude Code's CLI authentication. This is a community pattern, not an officially supported integration.
- **No stability guarantees** — CLI interfaces can change between versions without notice.

## Sources & Credits

- [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) — Multi-provider credential proxy (Claude, Codex, Gemini, Qwen)
- [CC-Bridge](https://github.com/ranaroussi/cc-bridge) by Ran Aroussi
- [Print Mode State Machine](https://gist.github.com/danialhasan/abbf1d7e721475717e5d07cee3244509) by Danial Hasan
- [Claude Code documentation](https://docs.anthropic.com/en/docs/claude-code) by Anthropic
- [Codex CLI documentation](https://developers.openai.com/codex/cli/) by OpenAI
- [Gemini CLI documentation](https://github.com/google-gemini/gemini-cli) by Google

## License

MIT — see [LICENSE](LICENSE).
