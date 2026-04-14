> Part of the [gemini-cli skill](../SKILL.md).

# Gemini CLI Subcommand Reference

Complete reference for `gemini skills`, `gemini extensions`, `gemini hooks`, and `gemini mcp`.
Last verified against `gemini --help`, `gemini skills --help`, `gemini extensions --help`,
and `gemini hooks --help` for **Gemini CLI v0.33.0** on 2026-04-14.

## Subcommand Tree

```
gemini [query..]                # Launch Gemini CLI (interactive by default; use -p for headless)
│
├── mcp                         Manage MCP servers
├── extensions, extension       Manage Gemini CLI extensions
│   ├── install <source>        Install from git URL or local path
│   ├── uninstall <names..>     Uninstall one or more extensions
│   ├── list                    List installed extensions
│   ├── update [<name>] [--all] Update one or all extensions
│   ├── disable <name>          Disable an installed extension
│   ├── enable <name>           Enable a disabled extension
│   ├── link <path>             Live-link an extension from a local path
│   ├── new <path> [template]   Create a new extension from a boilerplate
│   ├── validate <path>         Validate an extension structure
│   └── config [name] [setting] Configure extension settings
├── skills, skill               Manage agent skills
│   ├── list [--all]            List discovered agent skills
│   ├── enable <name>           Enable an agent skill
│   ├── disable <name>          Disable an agent skill
│   ├── install <source>        Install an agent skill from git URL or local path
│   ├── link <path>             Live-link a skill from a local path
│   └── uninstall <name>        Uninstall an agent skill
└── hooks, hook                 Manage Gemini CLI hooks
    └── migrate                 Migrate hooks from Claude Code to Gemini CLI
```

---

## `gemini skills` — Agent Skill Management

The full skill lifecycle, with `git URL` install support out of the box.

```bash
gemini skills list                    # list discovered skills
gemini skills list --all              # include disabled skills

gemini skills enable my-skill         # enable a skill
gemini skills disable my-skill        # disable a skill
gemini skills disable my-skill --scope user|project   # narrow the scope

gemini skills install https://github.com/owner/some-skill.git
gemini skills install ./local/skill-dir
gemini skills install <source> --scope user|project --path subpath/

gemini skills link ./skill-dev               # symlink for live development;
                                              # local edits reflected immediately

gemini skills uninstall my-skill
gemini skills uninstall my-skill --scope user|project
```

### Why this matters cross-CLI

Gemini CLI is the **only** one of the three major CLIs that ships a native `skills install <git-url>` command. Claude Code uses `claude plugin install owner/plugin@marketplace` against marketplace registries; Codex CLI does not have a first-party skill installer at all (skills live in MCP servers or AGENTS.md). A portable skill packaging recipe that installs cleanly across all three is documented in `cross-platform/patterns/skill-installation.md` (added later in this commit batch).

### `--scope` flag

`enable`, `disable`, `install`, `uninstall` accept `--scope user` or `--scope project` to narrow the change to per-user or per-project state. Default scope depends on where the skill currently lives.

### `link` for local development

`gemini skills link <path>` symlinks a skill directory into Gemini's skill registry. Edits to the source directory are reflected immediately — no reinstall needed. Use this during skill development; switch to `install` for stable consumption.

---

## `gemini extensions` — Extensions System

Extensions are bigger than skills: they bundle skills + MCP servers + commands + themes + hooks into a single installable unit.

```bash
gemini extensions list                            # list installed
gemini extensions install <source>                # git URL or local path
gemini extensions install <source> --auto-update --pre-release
gemini extensions update                          # update all
gemini extensions update <name>                   # update one
gemini extensions update --all                    # explicit "all"

gemini extensions enable <name>                   # enable
gemini extensions enable <name> --scope user|project
gemini extensions disable <name>
gemini extensions disable <name> --scope user|project

gemini extensions uninstall name1 name2 name3     # uninstall multiple at once

gemini extensions link <path>                     # live-link from local path

gemini extensions new ./my-extension              # scaffold a new extension
gemini extensions new ./my-extension <template>   # scaffold from a named template

gemini extensions validate ./my-extension         # validate structure before publishing

gemini extensions config <name>                   # show extension config
gemini extensions config <name> <setting>         # show a specific setting
```

### Notable design choices

- **`new` command for scaffolding** — `extensions new <path> [template]` creates a working extension from a boilerplate. Useful for generating a starting point that already passes `validate`.
- **`validate` command** — `extensions validate <path>` checks the extension structure before you publish or install it. Worth wiring into a pre-publish CI step.
- **`uninstall` accepts multiple names** — `gemini extensions uninstall a b c` removes all three in one call.
- **`--auto-update` and `--pre-release`** — opt into automatic updates or preview channels per-extension at install time.

---

## `gemini hooks` — Hook Management

```bash
gemini hooks migrate                # migrate hooks from Claude Code to Gemini CLI
```

### `gemini hooks migrate` is the only cross-CLI hook port command

This is the **strongest cross-platform feature** in any of the three CLIs and is essentially undocumented outside `--help`. Neither Claude Code → Codex nor Codex → Gemini has a native equivalent. If you've invested in Claude Code hooks and want to move them to Gemini, this is your one-shot tool.

Run it from a project directory that has a Claude Code hooks configuration; the command translates the relevant config into Gemini's hooks system in place. Always commit before running and review the diff afterwards — the translation isn't 100% lossless across platforms, especially for hooks that depend on Claude-specific event types.

A full discussion of cross-CLI hook portability and manual port recipes for the other directions is documented in `cross-platform/patterns/hook-migration.md` (added later in this commit batch).

---

## `gemini mcp`

```bash
gemini mcp                # manage MCP servers (analogous to `claude mcp` and `codex mcp`)
```

Per-subcommand help for `gemini mcp` is best obtained interactively via `gemini mcp --help`; the verbs match the Claude/Codex MCP management surface (add/list/get/remove). MCP itself is the same protocol across all three CLIs — a server registered for one of them works for the others with minor config translation.

---

## Top-Level Flags Worth Knowing

These are documented in [cli-flags.md](cli-flags.md), but the most important for automation:

| Flag | Purpose |
|------|---------|
| `-p, --prompt <text>` | Headless mode — non-interactive prompt |
| `-i, --prompt-interactive <text>` | Run a prompt then stay interactive |
| `-m, --model <name>` | Pick model (`gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-3-pro`, etc.) |
| `-y, --yolo` | Auto-approve all actions (use with care) |
| `--approval-mode {default,auto_edit,yolo,plan}` | Granular approval policy |
| `--policy <files>` | Additional policy files to load (comma-separated or repeated) |
| `-r, --resume <id>` | Resume a previous session (`latest` or numeric index) |
| `--list-sessions` | List available sessions and exit |
| `--delete-session <index>` | Delete a session by index |
| `-e, --extensions <list>` | Restrict which extensions are loaded for this run |
| `-l, --list-extensions` | List all available extensions and exit |
| `--include-directories <list>` | Add additional directories to the workspace |
| `-s, --sandbox` | Run in sandbox |
| `--allowed-mcp-server-names <list>` | Restrict which MCP servers are reachable |
| `-o, --output-format {text,json,stream-json}` | Output format |
| `--raw-output` | Disable model output sanitization (security risk; pair with `--accept-raw-output-risk`) |
| `--acp` / `--experimental-acp` | Start the agent in ACP mode (`--experimental-acp` is deprecated, use `--acp`) |

---

## See Also

- [cli-flags.md](cli-flags.md) — full top-level flag reference
- [json-output.md](json-output.md) — `--output-format json` and `stream-json` shapes
- [../guides/automate-cli.md](../guides/automate-cli.md) — non-interactive scripting patterns
- [../guides/extensions.md](../guides/extensions.md) — extension authoring deep dive
- [../guides/gemini-md.md](../guides/gemini-md.md) — `GEMINI.md` configuration
