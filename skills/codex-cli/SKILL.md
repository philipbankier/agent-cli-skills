---
name: codex-cli-automation
description: Automate OpenAI's Codex CLI with non-interactive exec mode, session resume, AGENTS.md configuration, and structured output. Use when building automation, CI/CD pipelines, multi-step workflows, or programmatic OpenAI integrations via the terminal.
---

# Codex CLI Automation

## Overview

Codex CLI ships with an **exec mode** (`codex exec` or `codex e`) designed for non-interactive, programmatic use.
Instead of launching the interactive TUI, exec mode accepts a prompt, processes it, writes the response to stdout,
and exits. This makes it the foundation for scripting, automation, CI/CD pipelines, and any workflow where a human
is not sitting at the terminal.

Basic invocation:

```bash
codex exec "Your prompt here"
codex e "Your prompt here"                    # shorthand
echo "Your prompt" | codex exec -             # pipe from stdin
```

**Key differentiators from other CLI agents:**
- **Session resume** — both `codex resume --last` (interactive TUI) and `codex exec resume --last` (non-interactive automation) continue where you left off across invocations
- **Output to file** — `-o output.txt` writes the final assistant message to a file
- **AGENTS.md** — Configuration file shared with Copilot and Cursor (write once, use everywhere)
- **Sandbox modes** — Granular control: read-only, workspace-write, or full-access

**When to use this skill:**

- Calling OpenAI models from shell scripts, Makefiles, or CI/CD pipelines
- Building multi-step automated workflows with session resume
- Batch processing files or datasets through Codex
- Configuring AGENTS.md for cross-tool consistency
- Embedding Codex in larger automation pipelines

**Prerequisites:**

- Codex CLI installed: `npm install -g @openai/codex` or `brew install --cask codex`
- Authenticated: `codex login` (ChatGPT account) or `OPENAI_API_KEY` environment variable
- For CI/CD: API key authentication recommended

---

## Decision Router

### What are you trying to do?

### "I want to call Codex programmatically from scripts or CI/CD"
-> Read [guides/automate-cli.md](guides/automate-cli.md)
Key commands: `codex exec`, `--full-auto`, `--json`, `-o`

### "I want to build multi-step workflows that maintain context across invocations"
-> Read [guides/session-management.md](guides/session-management.md)
Key commands: `codex exec resume --last`, `--ephemeral`, `-o`

### "I want to configure AGENTS.md for my project (works with Copilot and Cursor too)"
-> Read [guides/agents-md.md](guides/agents-md.md)
Pattern: hierarchical config from global to project to subdirectory

### "What flags are available for codex exec?"
-> Read [reference/exec-mode-flags.md](reference/exec-mode-flags.md)
Complete flag reference for non-interactive mode

### "What does the JSON output look like?"
-> Read [reference/json-output.md](reference/json-output.md)
Output shapes for `--json` (JSONL event stream)

### "Give me copy-paste code examples"
-> Read [reference/code-snippets.md](reference/code-snippets.md)
Ready-to-run patterns for common integration scenarios

### "I want to use codex sandbox / codex cloud / codex apply / codex fork / codex features / codex app / codex resume"
-> Read [reference/subcommands.md](reference/subcommands.md)
Full subcommand tree with verified `--help` output for everything that isn't `codex exec`

---

## Quick Start Recipes

These four recipes cover roughly 80% of use cases.

### Recipe 1: Simple CLI Automation

```bash
# One-shot query with plain text output
codex exec "Summarize this codebase"

# Pipe file content via stdin
cat main.py | codex exec - "List all function names in this file"

# Auto-approve all actions (use in sandboxed environments only)
codex exec "Refactor auth.ts to use async/await" --full-auto

# Full autonomy mode (no approvals, no sandbox)
codex exec "Fix all lint errors" \
  --dangerously-bypass-approvals-and-sandbox
```

### Recipe 2: JSON Output for Scripting

```bash
# Get structured JSONL output (event types: thread.started, turn.started, item.completed, turn.completed)
codex exec "Analyze this code for security issues" --json

# Save final message to file for downstream processing
codex exec "Generate a changelog from recent commits" -o changelog.md
```

### Recipe 3: Multi-Step Session Resume

```bash
# Step 1: Analyze the codebase
codex exec "Analyze the authentication module and identify improvement areas"

# Step 2: Resume and implement changes
codex exec resume --last "Now implement the top 3 improvements you identified"

# Step 3: Resume and write tests
codex exec resume --last "Write tests for the changes you just made"
```

### Recipe 4: CI/CD Integration

```bash
# In GitHub Actions (uses OPENAI_API_KEY from secrets)
codex exec "Review this PR diff for security issues. Output findings as JSON." \
  --json \
  --full-auto \
  -o review-findings.json

# Process multiple files
for f in src/*.ts; do
  codex exec "Check this file for type errors" \
    --ephemeral \
    < "$f"
done
```

---

## Core Concepts

### Exec Mode vs Interactive Mode

The `exec` subcommand (or `e` shorthand) switches Codex from its interactive TUI into
non-interactive mode:

- Input comes from the command argument or stdin (with `-`)
- Output goes to stdout (or file with `-o`)
- The process exits after producing a response
- Approvals depend on sandbox/approval settings

### Sandbox Modes

Codex has three sandbox levels, controllable via `-s`:

| Mode | Flag | What It Allows |
|------|------|----------------|
| **Read-only** | `-s read-only` | Can read files, cannot write or execute |
| **Workspace-write** | `-s workspace-write` (default) | Can write within project, no system access |
| **Full access** | `-s danger-full-access` | Unrestricted — use with caution |

### Approval Modes

Combined with sandbox, these control autonomy:

- **Default** — Prompts for approval on writes and executions
- **`--full-auto`** — Applies automation presets (workspace-write sandbox, on-request approvals)
- **`--dangerously-bypass-approvals-and-sandbox`** — No approvals, no sandbox. Only use in isolated environments.

For true full autonomy: `codex exec --full-auto --dangerously-bypass-approvals-and-sandbox "task"`. Without both flags, approval prompts may still appear.

### AGENTS.md Configuration

Codex loads `AGENTS.md` files hierarchically:

1. `~/.codex/AGENTS.override.md` (global override)
2. `~/.codex/AGENTS.md` (global defaults)
3. Git root → current directory: `AGENTS.override.md` then `AGENTS.md` at each level

Files concatenate from root downward. This is shared with Copilot and Cursor — write it once, all three tools use it.

### Session Resume

Codex persists sessions to disk by default. Two top-level resume commands exist — pick the one that matches your context:

```bash
# Interactive (launches TUI):
codex resume --last                # Continue the most recent session
codex resume                       # Picker for all sessions in this directory

# Non-interactive (exec mode, for scripts):
codex exec resume --last "follow-up prompt"
codex exec resume <session-id> "follow-up prompt"
```

Use `--ephemeral` when you want stateless, fire-and-forget invocations.

---

## Critical Gotchas

1. **Full auto requires multiple conditions** — `--full-auto` alone isn't enough for
   complete autonomy. You also need `--dangerously-bypass-approvals-and-sandbox` and a trusted
   workspace. Without all conditions met, you'll still get approval prompts.

2. **`-o` writes the final message only** — The `-o` / `--output-last-message` flag captures
   only the assistant's last message, not the full conversation. For complete output, use
   `--json` and capture stdout.

4. **Stdin requires the `-` flag** — Unlike Claude Code where piping to `-p` works directly,
   Codex exec needs `echo "prompt" | codex exec -` with an explicit dash.

5. **AGENTS.md has a size limit** — Combined instructions cap at `project_doc_max_bytes`
   (32 KiB default). If your AGENTS.md chain exceeds this, later files silently get truncated.

6. **Session resume is directory-scoped** — both `codex resume --last` and `codex exec resume --last`
   find the most recent session in the *current* directory. Changing directories changes which
   session is "last". This catches people who `cd` between steps in a workflow.

8. **`resume` and `exec resume` are different commands** — `codex resume` launches the
   interactive TUI on a previous session. `codex exec resume` continues a session in
   non-interactive exec mode. Use the one that matches your context; they are not aliases.

7. **API key auth is separate from ChatGPT auth** — API key billing goes to your OpenAI Platform
   account, not your ChatGPT subscription. They're different billing systems.

9. **`--enable`/`--disable` toggle feature flags per-invocation, not permanently** —
   `codex exec --enable my-feature ...` is equivalent to `-c features.my-feature=true` for that
   one run. To persist a flag across runs, use `codex features enable <name>` (writes to
   `~/.codex/config.toml`). `codex features list` shows current state and lifecycle stage.

10. **`codex sandbox <os>` is OS-level, not CLI permission gating** — The `codex sandbox`
    subcommand wraps an arbitrary command in macOS Seatbelt / Linux Landlock+seccomp /
    Windows restricted token. This is *separate* from `codex exec --sandbox {read-only|...}`,
    which is in-CLI permission policy. Use `codex sandbox` when you want OS-level isolation
    around any command (not just an agent run).

11. **`codex cloud apply` and `codex apply` do similar things** — Both materialize a Codex-
    produced diff onto your local working tree via `git apply`. `codex apply <task-id>` is the
    direct top-level form; `codex cloud apply <task-id>` is the cloud-task-aware form.

---

## File Map

Load these files only when the decision router points you to them:

| File | Description | Load When |
|---|---|---|
| `guides/automate-cli.md` | End-to-end guide for CLI automation and scripting | Building shell scripts, CI/CD pipelines, batch jobs |
| `guides/session-management.md` | Session resume, multi-step workflows, output capture | Building multi-turn automated workflows |
| `guides/agents-md.md` | AGENTS.md configuration patterns and hierarchy | Configuring project or team-wide instructions |
| `reference/exec-mode-flags.md` | Complete flag reference for `codex exec` (v0.114.0 verified) | Need exact flag syntax or interactions for non-interactive mode |
| `reference/subcommands.md` | Top-level + per-subcommand reference (`sandbox`, `cloud`, `apply`, `fork`, `resume`, `features`, `app`, `app-server`, `debug`, `mcp`, `mcp-server`, `review`) | Using any `codex` subcommand other than `exec` |
| `reference/json-output.md` | JSONL output shapes for `--json` | Parsing structured responses |
| `reference/code-snippets.md` | Copy-paste code examples in Bash, Python, JS | Need a working starting point |
| `reference/known-issues.md` | Verified gotchas (deprecated `--on-failure`, sandbox-vs-sandbox confusion, resume-vs-exec-resume distinction) | Debugging unexpected behavior or porting from older Codex versions |
