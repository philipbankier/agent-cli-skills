# Gemini CLI Top-Level Flag Reference

Complete reference for `gemini` top-level flags.
Last verified against `gemini --help` for **Gemini CLI v0.33.0** on 2026-04-14.

For subcommand-specific surfaces (`gemini skills`, `gemini extensions`, `gemini hooks`, `gemini mcp`),
see [subcommands.md](subcommands.md).

## Core Flags

| Flag | Short / alias | Description | Default |
|------|--------------|-------------|---------|
| `--prompt <text>` | `-p` | Run in non-interactive (headless) mode with the given prompt. Appended to stdin if any. | — |
| `--prompt-interactive <text>` | `-i` | Execute the provided prompt then continue in interactive mode | — |
| `--model <name>` | `-m` | Model to use (passed through to the API; common values: `gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-3-pro`, etc.) | per config |
| `--debug` | `-d` | Run in debug mode (open debug console with F12) | `false` |
| `--sandbox` | `-s` | Run in sandbox | `false` |
| `--yolo` | `-y` | Auto-approve all actions (YOLO mode) | `false` |
| `--approval-mode <mode>` | — | Approval policy: `default`, `auto_edit`, `yolo`, `plan` | `default` |
| `--policy <files>` | — | Additional policy files or directories to load (comma-separated or repeated) | — |
| `--acp` | — | Start the agent in ACP mode | `false` |
| `--experimental-acp` | — | DEPRECATED — use `--acp` | `false` |
| `--allowed-mcp-server-names <list>` | — | Restrict which MCP servers can be reached | all |
| `--allowed-tools <list>` | — | DEPRECATED — use the Policy Engine instead | — |
| `--extensions <list>` | `-e` | Restrict which extensions are loaded for this run | all |
| `--list-extensions` | `-l` | List all available extensions and exit | — |
| `--resume <id>` | `-r` | Resume a previous session. Use `latest` for most recent or a numeric index (e.g. `--resume 5`) | — |
| `--list-sessions` | — | List available sessions for the current project and exit | — |
| `--delete-session <index>` | — | Delete a session by index (use `--list-sessions` to see indices) | — |
| `--include-directories <list>` | — | Additional directories to include in the workspace (comma-separated or repeated) | — |
| `--screen-reader` | — | Enable screen reader mode for accessibility | `false` |
| `--output-format <fmt>` | `-o` | Output format: `text`, `json`, `stream-json` | `text` |
| `--raw-output` | — | Disable model-output sanitization (allows ANSI escapes). **Security risk if model output is untrusted.** | `false` |
| `--accept-raw-output-risk` | — | Suppress the `--raw-output` security warning | `false` |
| `--version` | `-v` | Show version | — |
| `--help` | `-h` | Show help | — |

## Approval Mode Choices

`--approval-mode` accepts these values (verified via `--help`):

| Mode | Behavior |
|------|----------|
| `default` | Prompt for approval before destructive actions |
| `auto_edit` | Auto-approve edit tools but still prompt for everything else |
| `yolo` | Auto-approve all tools (equivalent to `-y / --yolo`) |
| `plan` | Read-only mode — no edits, no destructive actions |

## Output Formats

| Format | Flag | Description |
|--------|------|-------------|
| Text | `-o text` (default) | Plain text response |
| JSON | `-o json` | Single JSON object with response and metadata |
| Stream JSON | `-o stream-json` | Streaming JSON events |

For exact JSON shapes, see [json-output.md](json-output.md).

## Sessions

```bash
gemini --list-sessions                  # show available sessions with indices
gemini -r latest                        # resume the most recent
gemini -r 5                             # resume session at index 5
gemini --delete-session 5               # delete session at index 5
gemini -r latest -p "Continue with..."  # resume + new prompt in headless mode
```

Sessions are scoped per project — `--list-sessions` shows the sessions for whichever project Gemini detects in the current directory.

## Extensions Subset for One Run

```bash
gemini -l                                       # list all available extensions
gemini -e my-ext1,my-ext2 -p "task"             # run with only those two extensions loaded
```

For full extension lifecycle management, see [subcommands.md](subcommands.md#gemini-extensions--extensions-system).

## Workspace Expansion

```bash
gemini --include-directories ../shared,../docs -p "Reference these directories"
```

Useful for monorepo work where you need Gemini to see code outside the immediate cwd.

## Sandbox

```bash
gemini -s -p "Run untrusted task"
```

Pair with `--approval-mode plan` for read-only sandboxed runs.

## ACP Mode

`--acp` starts the agent in ACP mode (Agent Communication Protocol). `--experimental-acp` is the deprecated form — use `--acp` instead.

## Authentication

| Method | How |
|--------|-----|
| Google OAuth | `gemini` (first run opens browser) — uses your Google account, includes the free tier (1000 model requests/day) |
| API Key (env) | `GEMINI_API_KEY=your-key gemini -p "prompt"` |

> **Note:** v0.33.0's `gemini --help` does **not** document a `-f` / `--free` flag. Earlier docs in this repo claimed one existed; that was incorrect.

## Common Combinations

```bash
# Headless JSON for scripting
gemini -p "Analyze this file" -o json < main.py

# Streaming JSON for token-level UIs
gemini -p "Explain step by step" -o stream-json

# Plan mode + headless = read-only review
gemini -p "Review this PR diff" --approval-mode plan < pr.diff

# YOLO + Flash model = fastest fully-automated batch
gemini -p "Classify this issue" -y -m gemini-2.5-flash < issue.txt

# Resume previous session with new prompt
gemini -r latest -p "What was our conclusion?"

# Restricted MCP environment for safety
gemini -p "Fetch data" --allowed-mcp-server-names http-fetcher
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error or API failure |
| 42 | Input error (invalid prompt or arguments) |
| 53 | Turn limit exceeded |

> Exit codes 42 and 53 documented from earlier community testing; not strictly verifiable from `--help` alone. Treat any non-zero exit as failure in scripts and surface the actual error from stderr.

## Rate Limits by Auth Method

| Auth | Requests/Day | Requests/Minute |
|------|-------------|-----------------|
| Google Account | 1000 model requests | 60 |
| API Key (unpaid) | 250 | 10 |
| API Key (paid) | Varies by plan | Varies by plan |

> "Requests" here means *model* requests, not user prompts. A single complex prompt with tool use can trigger many model requests. Use `/stats model` in interactive mode to see the breakdown.

## Model Selection

`-m / --model` accepts any model name the CLI's API client supports. Common values seen in the wild include `gemini-2.5-pro`, `gemini-2.5-flash`, `gemini-3-pro`, and Auto-routing aliases like `auto-gemini-3` / `auto-gemini-2-5`.

> `--help` does not enumerate accepted model names. The CLI passes whatever string you give to `-m` through to the API; if the API rejects it, you get an error. Always verify model availability against the current Gemini API documentation, not against what's hardcoded in any docs file (including this one).
