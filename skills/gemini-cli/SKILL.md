---
name: gemini-cli-automation
description: Automate Google's Gemini CLI with non-interactive headless mode, extensions, GEMINI.md configuration, and structured output. Use when building automation, CI/CD pipelines, batch processing, or programmatic Gemini integrations via the terminal. Covers free tier usage (1000 requests/day).
---

# Gemini CLI Automation

> **Verification status (2026-04-14):** Subcommand surface (`gemini --help`, `gemini skills --help`, `gemini extensions --help`, `gemini hooks --help`) verified live against **Gemini CLI v0.33.0** — see [reference/subcommands.md](reference/subcommands.md). Multi-agent example scripts under `examples/` are still community-contributed and have **not** been run end-to-end. Upstream is currently v0.37.2; the gap is tracked in [reference/changelog.md](reference/changelog.md). If you have Gemini CLI configured, please run the example scripts and submit a PR with corrections.

## Overview

Gemini CLI ships with a **headless mode** (`gemini -p` or piped input) designed for non-interactive, programmatic use.
Instead of launching the interactive TUI, headless mode accepts a prompt, processes it, writes the response to stdout,
and exits. This makes it the foundation for scripting, automation, CI/CD pipelines, and any workflow where a human
is not sitting at the terminal.

Basic invocation:

```bash
gemini -p "Your prompt here"
echo "Your prompt" | gemini
```

**Key differentiators from other CLI agents:**
- **Free tier** — 1000 model requests/day with a Google account, no API key needed
- **1M token context window** — Largest context of any CLI agent (Gemini 2.5 Pro)
- **Extensions** — Bundle skills, MCP servers, commands, themes, and hooks into installable packages
- **Model selection** — Switch between Gemini 3 Pro (quality) and Gemini 2.5 Flash (speed) with `-m`

**When to use this skill:**

- Calling Gemini from shell scripts, Makefiles, or CI/CD pipelines
- Batch processing large files or entire codebases (leveraging the 1M token context)
- High-volume automation within the free tier (1000 requests/day)
- Building or installing Gemini extensions
- Configuring GEMINI.md for project-wide AI instructions

**Prerequisites:**

- Gemini CLI installed: `npm install -g @google/gemini-cli` or `brew install gemini-cli`
- Authenticated: `gemini login` (Google account) or `GEMINI_API_KEY` environment variable
- Node.js 18+

---

## Decision Router

### What are you trying to do?

### "I want to call Gemini programmatically from scripts or CI/CD"
-> Read [guides/automate-cli.md](guides/automate-cli.md)
Key flags: `-p`, `--output-format`, `-y`/`--yolo`, `--approval-mode`, `-m`

### "I want to build or install Gemini extensions"
-> Read [guides/extensions.md](guides/extensions.md)
Pattern: Extensions bundle skills + MCP servers + commands + themes + hooks

### "I want to configure GEMINI.md for my project"
-> Read [guides/gemini-md.md](guides/gemini-md.md)
Pattern: hierarchical config with `@import` syntax

### "What flags are available for gemini in headless mode?"
-> Read [reference/cli-flags.md](reference/cli-flags.md)
Complete flag reference for non-interactive mode

### "What does the JSON output look like?"
-> Read [reference/json-output.md](reference/json-output.md)
Output shapes for `--output-format json` and `--output-format stream-json`

### "Give me copy-paste code examples"
-> Read [reference/code-snippets.md](reference/code-snippets.md)
Ready-to-run patterns for common integration scenarios

### "I want to manage skills, extensions, hooks, or migrate hooks from Claude Code"
-> Read [reference/subcommands.md](reference/subcommands.md)
Full subcommand tree for `gemini skills`, `gemini extensions`, `gemini hooks` (including
the cross-CLI `gemini hooks migrate` command), and `gemini mcp`. Verified live against
v0.33.0.

---

## Quick Start Recipes

These four recipes cover roughly 80% of use cases.

### Recipe 1: Simple CLI Automation

```bash
# One-shot query with plain text output
gemini -p "Summarize this codebase"

# Pipe content through Gemini
cat main.py | gemini -p "List all function names in this file"

# Auto-approve all actions (yolo mode)
gemini -p "Refactor auth.ts to use async/await" -y  # or --yolo

# Use the fast model for quick tasks
gemini -p "What language is this file?" -m gemini-2-5-flash < main.py
```

### Recipe 2: JSON Output for Scripting

```bash
# Structured JSON output
gemini -p "Analyze this code for security issues" --output-format json | jq '.'

# Streaming JSON output
gemini -p "Explain this codebase step by step" --output-format stream-json
```

### Recipe 3: Free Tier Batch Processing

```bash
# Process multiple files within the free tier (1000 requests/day)
for f in src/*.py; do
  echo "Processing $f..."
  gemini -p "List all function names" -m gemini-2-5-flash < "$f"
  sleep 1  # Rate limit: 60 requests/minute
done
```

### Recipe 4: Large Context Analysis

```bash
# Leverage the 1M token context window
# Concatenate an entire codebase for holistic analysis
find src -name "*.ts" -exec cat {} + | \
  gemini -p "Analyze this entire codebase. Identify architectural patterns, potential issues, and suggest improvements."
```

---

## Core Concepts

### Headless Mode

Gemini CLI enters non-interactive mode automatically when:
- The `-p` / `--prompt` flag is used
- Input is piped (non-TTY stdin)

In headless mode:
- Input comes from the flag argument and/or stdin
- Output goes to stdout (format controlled by `--output-format`)
- The process exits after producing a response

### Output Format Spectrum

| Format | Flag | Shape | Use When |
|---|---|---|---|
| `text` | Default | Raw text string | Simple scripts, human-readable output |
| `json` | `--output-format json` | Single JSON object with response + stats | Parsing metadata, structured workflows |
| `stream-json` | `--output-format stream-json` | Streaming JSON events | Real-time progress, session metadata |

### Model Selection

Switch models with the `-m` flag:

| Model | Flag | Best For |
|---|---|---|
| Gemini 3 Pro | `-m gemini-3-pro-preview` | Complex reasoning, agentic coding |
| Gemini 2.5 Pro | Default | General-purpose (largest context: 1M tokens) |
| Gemini 2.5 Flash | `-m gemini-2-5-flash` | Speed, lower latency, cost-efficient |
| Auto (Gemini 3) | `-m auto-gemini-3` | System picks best Gemini 3 model |

### Free Tier Quotas

| Auth Method | Requests/Day | Requests/Minute | Models |
|---|---|---|---|
| Google Account (Gemini Code Assist) | 1000 | 60 | Full Gemini family |
| Gemini API Key (unpaid) | 250 | 10 | Flash only |
| Vertex AI Express | 90-day trial | Variable | Full family |

**Important**: A single prompt can trigger multiple model requests (tool calls, multi-step reasoning). Monitor with `/stats model` in interactive mode.

### Extensions

Gemini's unique extension system bundles multiple capabilities:

- **Skills** — Specialized knowledge packages (like this one)
- **MCP Servers** — Model Context Protocol integrations
- **Commands** — Custom slash commands
- **Themes** — Visual customization
- **Hooks** — Event-driven automation

Install extensions with:
```bash
gemini extensions install https://github.com/user/extension
```

### GEMINI.md Configuration

Project-specific instructions loaded automatically:

- **Global**: `~/.gemini/GEMINI.md`
- **Project**: `GEMINI.md` at project root
- **Modular**: Use `@file.md` import syntax for large configs

Manage in interactive mode:
- `/memory show` — View current context
- `/memory reload` — Rescan files
- `/memory add <text>` — Append to global config

---

## Critical Gotchas

1. **One prompt != one request** — Complex prompts with tool use can trigger dozens of API
   requests. A "1000 requests/day" limit may mean far fewer prompts. Track with `/stats model`.

2. **Free tier model restrictions** — Unpaid API key access is limited to Flash models only.
   Use Google Account auth for access to the full Gemini family.

3. **`-y`/`--yolo` approves everything** — Gemini's `-y` flag (also `--yolo`) is all-or-nothing.
   For more granular control, use `--approval-mode` with choices: `default`, `auto_edit`, `yolo`, `plan` (read-only).

4. **Sessions are supported** — Use `-r`/`--resume` to continue a previous session, `--list-sessions`
   to see available sessions, and `--delete-session` to clean up. Sessions work in headless mode too.

5. **Exit codes are meaningful** — `0`=success, `1`=error, `42`=input error (bad prompt/args),
   `53`=turn limit exceeded. Check these in scripts.

6. **`@import` syntax in GEMINI.md** — You can break large config files into modules with
   `@file.md` imports. This is unique to Gemini CLI.

7. **Extensions can include MCP servers** — Unlike Claude Code and Codex CLI where MCP is
   configured separately, Gemini bundles MCP servers into extensions for easier distribution.

8. **`gemini hooks migrate` is a one-shot port from Claude Code** — `gemini hooks migrate`
   translates Claude Code hook configurations into Gemini's hooks system in place. This is
   the **only** native cross-CLI hook port command in any of the three CLIs. Run it from a
   project that has Claude hooks configured, commit before running, and review the diff —
   the translation isn't 100% lossless across platforms (especially for hooks that depend on
   Claude-specific event types).

9. **`gemini skills install <git-url>` is unique** — Gemini ships a native `skills install`
   command that pulls skills directly from a git URL or local path. Claude Code requires a
   marketplace registration (`claude plugin install owner/plugin@marketplace`); Codex CLI has
   no first-party skill installer. If you publish a portable skill, Gemini gives you the
   shortest install path.

10. **`extensions validate <path>` and `extensions new <path> [template]`** — Gemini ships
    boilerplate scaffolding (`new`) and structural validation (`validate`) for extensions
    out of the box. Use them as a pre-publish CI step.

11. **`-r/--resume` accepts `latest` or numeric index** — Unlike Claude Code's UUID-or-name
    style, Gemini sessions are addressable by numeric index (`gemini -r 5`) or the literal
    string `latest`. Use `--list-sessions` to see indices.

---

## File Map

Load these files only when the decision router points you to them:

| File | Description | Load When |
|---|---|---|
| `guides/automate-cli.md` | End-to-end guide for CLI automation and scripting | Building shell scripts, CI/CD pipelines, batch jobs |
| `guides/extensions.md` | Gemini extensions system guide | Building or installing extensions |
| `guides/gemini-md.md` | GEMINI.md configuration patterns | Configuring project or team-wide instructions |
| `reference/cli-flags.md` | Complete top-level flag reference for headless mode | Need exact flag syntax for `gemini -p` |
| `reference/subcommands.md` | Full subcommand tree for `gemini skills`, `gemini extensions`, `gemini hooks`, `gemini mcp` (v0.33.0 verified) | Managing skills, extensions, hooks, or MCP servers |
| `reference/json-output.md` | JSON and stream-json output shapes | Parsing structured responses |
| `reference/code-snippets.md` | Copy-paste code examples in Bash, Python, JS | Need a working starting point |
| `reference/known-issues.md` | Verified gotchas (code removal bug #23497, deprecated flags, lossy `gemini hooks migrate`) | Debugging unexpected behavior — check here before assuming it's your code |
| `reference/changelog.md` | Per-version notes for v0.34–v0.37 from official release notes | Deciding what's in the upstream gap before you upgrade |
