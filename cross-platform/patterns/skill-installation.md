# Cross-CLI Skill Installation

How each CLI installs and discovers reusable skills, and how to package a single skill so it works across all three.
Verified against Claude Code v2.1.104, Codex CLI v0.114.0, Gemini CLI v0.33.0 on 2026-04-14.

## TL;DR Per-CLI

| CLI | Native install command | Source types | Sharing model |
|-----|----------------------|--------------|---------------|
| **Claude Code** | `claude plugin install owner/plugin` (or `owner/plugin@marketplace`) | Marketplace registry | Plugins (which can bundle skills) |
| **Codex CLI** | None | — | MCP servers + AGENTS.md |
| **Gemini CLI** | `gemini skills install <git-url-or-path>` | Direct git URL or local path | Skills + Extensions |

Gemini is the only one of the three that ships a native `skills install <git-url>` command. Claude Code requires marketplace registration. Codex doesn't have a first-party skill installer at all — its closest analog is registering an MCP server.

## Claude Code: `claude plugin`

Claude Code's reusable-skill mechanism is **plugins**, managed through `claude plugin` (alias `claude plugins`). Plugins are distributed via marketplaces — there's an official marketplace and the community runs others.

```bash
claude plugin list                              # list installed plugins
claude plugin install owner/plugin              # install from default marketplace
claude plugin install owner/plugin@marketplace  # install from a specific marketplace
claude plugin enable <plugin>                   # enable a disabled plugin
claude plugin disable <plugin>                  # disable an enabled plugin
claude plugin update <plugin>                   # update to latest (restart required)
claude plugin uninstall <plugin>                # uninstall (alias: remove)
claude plugin validate <path>                   # validate a plugin or marketplace
claude plugin marketplace                       # manage marketplaces
```

A plugin can contain:

- One or more skills (`SKILL.md` files)
- Slash commands
- Hooks
- Sub-agents

**Restart caveat:** plugin updates require a Claude Code restart to apply. Plan automation around this.

> **Direct git installation is not native.** If you want to install a plugin from a git URL that isn't in any marketplace, you need to either: (a) register your own marketplace and add the plugin to it, or (b) clone manually into your plugin directory. Gemini is the only CLI with a one-shot `install <git-url>` command.

### Where Claude Code looks for skills

- Project: `.claude/skills/<skill-name>/SKILL.md`
- User: `~/.claude/skills/<skill-name>/SKILL.md`
- Plugin: managed by `claude plugin` against the marketplace

A bare skill (just `SKILL.md` with frontmatter) can be dropped into either of the first two paths and Claude Code will discover it via the description matching mechanism.

## Codex CLI: no native skill installer

Codex doesn't have a first-party `skills` subcommand. Its analogs:

### MCP servers as skill substitutes

Codex consumes capabilities through MCP. Register an external MCP server with `codex mcp` (or have your project's `~/.codex/config.toml` reference one), and the agent can use the tools that server exposes.

```bash
codex mcp                # umbrella for adding/listing/configuring MCP servers
```

This is closer to "tool integration" than "skill" — there's no equivalent to a SKILL.md instruction file.

### `AGENTS.md` for project instructions

What Codex CLI calls "skill content" is most often baked into `AGENTS.md` files. These get loaded hierarchically (global → project → subdirectory). They're not discoverable per-task the way Claude/Gemini skills are; they're always-on context for the project.

```
~/.codex/AGENTS.md         # global default behavior
./AGENTS.md                # project-level
./auth/AGENTS.md           # subdirectory-level
```

For instructions that should apply only when a particular task is in flight, the closest pattern is to add a slash-command alias in `~/.codex/config.toml` that invokes `codex exec` with a specific prompt and flag set.

## Gemini CLI: `gemini skills install`

Gemini is the easy case. The full skill lifecycle is a top-level subcommand and supports git URLs and local paths natively.

```bash
gemini skills list                          # list discovered skills
gemini skills list --all                    # include disabled

gemini skills install https://github.com/owner/skill.git
gemini skills install ./local/skill-dir
gemini skills install <source> --scope user|project --path subpath/

gemini skills enable my-skill
gemini skills disable my-skill --scope user|project

gemini skills link ./skill-dev              # symlink for live development
gemini skills uninstall my-skill --scope user|project
```

`gemini skills install <git-url>` works without a marketplace, without a pre-registration step, without a restart. Just give it a git URL and the skill is available.

For richer bundles (skills + MCP servers + commands + themes + hooks), use `gemini extensions install <source>` instead — extensions are the superset.

```bash
gemini extensions install <git-url-or-path>
gemini extensions install <source> --auto-update --pre-release
gemini extensions new ./my-extension              # scaffold from boilerplate
gemini extensions validate ./my-extension         # validate before publishing
```

## Portable Skill Packaging Recipe

If you want to publish one skill that installs cleanly on all three CLIs, structure it like this:

```
my-skill/
├── SKILL.md                  # frontmatter (name, description) + instructions
├── README.md                 # human-facing intro
├── plugin.json               # Claude Code plugin manifest (so it can be marketplaced)
├── extension.json            # Gemini extension manifest (optional, if you want extension features)
├── mcp-server.json           # MCP server config (optional, for Codex consumption via MCP)
└── examples/                 # working example invocations per CLI
    ├── claude-code.md
    ├── codex-cli.md
    └── gemini-cli.md
```

### `SKILL.md` frontmatter that works on both Claude and Gemini

```markdown
---
name: my-skill
description: Does X when the user is doing Y. Pulls in Z context. Use when ...
---

# My Skill

## Overview
...

## When to use
...

## Workflow
...
```

The minimum required frontmatter on both Claude Code and Gemini is `name` and `description`. The description is what each CLI's discovery mechanism matches against task context, so write it the way you'd write a search query: describe the trigger condition, not the implementation.

### Claude Code installation

If you've published as a plugin in a marketplace:

```bash
claude plugin install owner/my-skill
# or
claude plugin install owner/my-skill@your-marketplace
```

If not, drop the directory at:

```bash
mkdir -p .claude/skills/my-skill
cp -r my-skill/* .claude/skills/my-skill/
```

### Gemini CLI installation

```bash
# Direct from git
gemini skills install https://github.com/owner/my-skill.git

# Or local clone
git clone https://github.com/owner/my-skill.git
gemini skills install ./my-skill

# Or live-link for development
gemini skills link ./my-skill
```

### Codex CLI installation

There's no skill installer. Choose an integration path:

- **MCP path** — wrap the skill's behavior in an MCP server and register it via `codex mcp`. The skill's instructions become tool descriptions and prompt templates inside the MCP server.
- **`AGENTS.md` path** — append the skill's instructions to your project's `AGENTS.md`. Loses per-task discovery, but the agent always has the context.
- **Slash-command path** — define a custom command in `~/.codex/config.toml` that invokes `codex exec` with the skill's instructions baked into `--system-prompt` or `--append-system-prompt`. This is the closest to per-task triggering.

## Validation Before Publishing

| CLI | Validation command |
|-----|-------------------|
| Claude Code | `claude plugin validate <path>` |
| Codex CLI | None (no plugin/skill format to validate) |
| Gemini CLI | `gemini extensions validate <path>` (note: skills don't have a separate validator) |

Run both Claude and Gemini validators in CI before publishing. They catch different things — Claude's validator focuses on the plugin manifest format, Gemini's focuses on extension structure.

## Discovery Behavior

| CLI | When does the skill load? |
|-----|---------------------------|
| Claude Code | Skills are matched against the agent's task description. The matching is done by the agent itself based on the SKILL.md frontmatter description. |
| Codex CLI | N/A — `AGENTS.md` is always loaded; MCP server tools are listed but not "discovered" the way skills are. |
| Gemini CLI | Same as Claude — agent matches against the description field at task time. |

The implication: write skill descriptions for **agents to read**, not for humans browsing a list. Lead with the trigger condition ("Use this skill when the user wants to ..."). Avoid generic descriptions like "A useful skill for X" — those don't match against task context well.

## Common Mistakes

- **Publishing a plugin without a marketplace entry** — Claude Code can't install it without one. Either register it in a marketplace (or your own) or document the manual `.claude/skills/<name>/` install path.
- **Forgetting that Claude Code plugins require restart** — `claude plugin update` requires a CLI restart to apply the new version. CI scripts that update plugins mid-run will silently keep using the old one until restart.
- **Putting CLI-specific instructions in shared SKILL.md** — if your skill targets all three CLIs, fence the platform-specific bits into clearly labeled sections, the way `cross-platform.md` skill-authoring guide describes.
- **Confusing `gemini skills install` with `gemini extensions install`** — they're separate registries. A skill installed via `skills install` won't show up under `extensions list`. Use extensions when you want the superset (skills + MCP + commands + themes + hooks); use skills when you only need the SKILL.md.

## See Also

- [hook-migration.md](hook-migration.md) — porting hooks across the three CLIs
- [../../skill-authoring/cross-platform.md](../../skill-authoring/cross-platform.md) — designing a skill that works across all three CLIs
- [../../skills/gemini-cli/reference/subcommands.md](../../skills/gemini-cli/reference/subcommands.md#gemini-skills--agent-skill-management) — full `gemini skills` and `gemini extensions` reference
- [../../skills/claude-code/reference/commands.md](../../skills/claude-code/reference/commands.md#claude-plugin-alias-plugins) — full `claude plugin` reference
