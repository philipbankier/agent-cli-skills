# Contributing to agent-cli-skills

Thanks for your interest in contributing! This repo is a community resource — all contributions that improve the quality, accuracy, or breadth of these skills are welcome.

## What Makes a Good Contribution

An agent can run `--help` on any CLI. The value of this repo is content that `--help` *doesn't* provide:

- **Gotchas and silent failures** — flag interactions that break unexpectedly, defaults that surprise you, behaviors not documented in `--help`. These are the highest-value contributions.
- **Battle-tested patterns** — real scripts that have been run end-to-end, not plausible-looking code assembled from docs. If you haven't run it, say so.
- **Cross-platform knowledge** — migration recipes, comparison tables, and patterns that span multiple CLIs. No vendor documents this.
- **Real output samples** — captured from actual CLI runs, not hand-written. Include the CLI version you tested against.

Content that just mirrors `--help` output has low value — focus on what you learned *after* reading the help.

## What We Need Most

1. **Gotcha discoveries** — Found a non-obvious flag interaction or silent failure? Add it to the Critical Gotchas section of the relevant SKILL.md. This is the most valuable contribution.
2. **New examples** — Multi-agent orchestration, CI/CD patterns, or creative automation scripts. Must be runnable, not theoretical.
3. **Flag documentation updates** — CLI tools evolve fast. If you find a flag that's changed, been added, or removed, update the relevant reference file.
4. **Cross-platform patterns** — Patterns that work across all three CLIs, especially migration recipes.
5. **Gemini CLI testing** — The Gemini skill is community-contributed and not yet run end-to-end. Run the examples, submit corrections and sample output.
6. **Code snippets** — Working examples in additional languages (Rust, Ruby, etc.).

## Structure

Each CLI has its own skill under `skills/`:

```
skills/
├── claude-code/    # Claude Code (claude -p)
├── codex-cli/      # Codex CLI (codex exec)
└── gemini-cli/     # Gemini CLI (gemini -p)
```

Cross-platform content lives in `cross-platform/` and `skill-authoring/`.

## Guidelines

- **Test your examples** — Every code snippet and command should be runnable. If it requires specific setup, document it.
- **Follow the existing pattern** — Each skill has the same structure: SKILL.md (entry point) → guides/ → reference/ → examples/. Keep it consistent.
- **Agent-friendly writing** — These docs are consumed by AI agents as much as humans. Use decision routers, copy-paste recipes, and explicit gotcha callouts.
- **One PR per concern** — Keep PRs focused. A flag update, a new example, and a gotcha fix should be separate PRs.

## Getting Started

1. Fork the repo
2. Create a branch: `git checkout -b my-contribution`
3. Make your changes
4. Test any code examples you added or modified against the actual CLI (`--help` output, real invocations)
5. If you changed flags for one CLI, check whether `cross-platform/comparison.md` and `cross-platform/migration-guide.md` need updating too
6. Submit a PR with a clear description of what changed and why

## Reporting Issues

Found an inaccurate flag, broken example, or missing feature? [Open an issue](../../issues/new/choose) using the appropriate template. Include the CLI version you tested against.

## Security

If you find a security issue in the install scripts or example code, please report it via [GitHub Issues](../../issues). This repo contains documentation and example scripts, not production services, so public reporting is appropriate.

## Code of Conduct

Be helpful, be accurate, be kind. We follow the spirit of the [Contributor Covenant](https://www.contributor-covenant.org/) — treat everyone with respect, assume good intent, and focus on making the project better.
