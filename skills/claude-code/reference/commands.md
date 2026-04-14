> Part of the [cc-cli-skill](../SKILL.md) skill.

# Claude Code Top-Level Subcommands

Reference for `claude <subcommand>` calls — the things that aren't `claude -p` or interactive mode.
Last verified against `claude --help` for **Claude Code v2.1.104** on 2026-04-14.

## Subcommand Inventory

| Subcommand | Purpose |
|------------|---------|
| `agents` | List configured agents |
| `auth` | Manage authentication (login/logout/status) |
| `auto-mode` | Inspect auto mode classifier configuration |
| `doctor` | Health check the auto-updater and stdio MCP servers |
| `install` | Install Claude Code native build (stable / latest / specific version) |
| `mcp` | Add, list, configure, and inspect MCP servers |
| `plugin` / `plugins` | Manage plugins, marketplaces, validation |
| `setup-token` | Set up a long-lived authentication token (requires Claude subscription) |
| `update` / `upgrade` | Check for updates and install if available |

---

## `claude agents`

Lists configured agents in the current workspace.

```bash
claude agents
claude agents --setting-sources user,project,local
```

Flags:
- `--setting-sources <sources>` — comma-separated list of which setting sources to load when resolving agent definitions (`user`, `project`, `local`)

---

## `claude auth`

Authentication management subcommands.

```bash
claude auth login        # interactive sign-in flow
claude auth logout       # clear stored credentials
claude auth status       # show current authentication state
```

Use `claude setup-token` instead when you specifically need a long-lived token (CI workflows, headless servers).

---

## `claude auto-mode`

Inspect the auto-mode classifier configuration. Auto mode is the system that decides which permission and tool set to apply automatically based on context.

```bash
claude auto-mode config        # print effective config (your settings + defaults)
claude auto-mode defaults      # print built-in defaults as JSON
claude auto-mode critique      # get AI feedback on your custom rules
```

Use `auto-mode config` first when debugging unexpected permission decisions — the JSON output shows exactly which rules are in effect.

---

## `claude doctor`

Health check for the auto-updater and stdio MCP servers configured in `.mcp.json`.

```bash
claude doctor
```

> **Trust warning from `--help`:** doctor skips the workspace trust dialog and spawns stdio servers from `.mcp.json` for health checks. Only run in directories you trust.

Useful when:
- The CLI claims it's up to date but you suspect otherwise
- An MCP server isn't loading and you want to confirm it can spawn at all
- Setting up a new project and want to validate the `.mcp.json` is wired correctly

---

## `claude install [target]`

Install or reinstall the Claude Code native build. Use a `[target]` to pin a version channel.

```bash
claude install                       # install latest
claude install stable                # install latest stable
claude install latest                # install absolute latest (may be a preview)
claude install 2.1.104               # pin a specific version
claude install --force               # reinstall even if already present
```

Pair with `claude doctor` afterward to confirm the new build is healthy.

---

## `claude mcp`

The umbrella for managing MCP (Model Context Protocol) servers.

```bash
# Add an HTTP MCP server:
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# Add an HTTP server with custom headers:
claude mcp add --transport http corridor https://app.corridor.dev/api/mcp \
  --header "Authorization: Bearer ..."

# Add a stdio server with environment variables:
claude mcp add -e API_KEY=xxx my-server -- npx my-mcp-server

# Add a stdio server with subprocess flags:
claude mcp add my-server -- my-command --some-flag arg1

# Add a server from raw JSON (stdio or SSE):
claude mcp add-json my-server '{"command": "...", "args": [...]}'

# Import MCP servers from Claude Desktop (Mac and WSL only):
claude mcp add-from-claude-desktop

# Get details about a specific server:
claude mcp get my-server
```

> **Trust warning from `--help` for `claude mcp get`:** spawns stdio servers from `.mcp.json` to inspect them. Only run in trusted directories.

The `claude mcp` umbrella also has `list`, `remove`, and other management verbs — run `claude mcp --help` for the full surface in your installed version.

---

## `claude plugin` (alias `plugins`)

Plugin lifecycle management against Claude Code marketplaces.

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

> **Restart caveat:** plugin updates require a Claude Code restart to apply. Plan automation around this.

Plugins are how the official Claude Code skill marketplace ([anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official)) and community marketplaces (e.g., the awesome-claude-code ecosystem) ship reusable skill bundles, hooks, and slash commands.

---

## `claude setup-token`

Set up a long-lived authentication token. Requires an active Claude subscription.

```bash
claude setup-token
```

Use this for headless / CI environments where you need stable auth that survives across machines without an interactive OAuth flow each time. The resulting token can be supplied via `ANTHROPIC_API_KEY` or `apiKeyHelper` in your settings file (see also `--bare` mode in [print-mode-flags.md](print-mode-flags.md)).

---

## `claude update` (alias `upgrade`)

Check for updates and install them if available.

```bash
claude update
claude upgrade           # alias, same behavior
```

Use `claude doctor` first if you want to verify the auto-updater is healthy before triggering an update.

---

## See Also

- [print-mode-flags.md](print-mode-flags.md) — full flag reference for `claude -p`
- [json-output.md](json-output.md) — JSON response shapes
- [streaming-events.md](streaming-events.md) — stream-json event reference
