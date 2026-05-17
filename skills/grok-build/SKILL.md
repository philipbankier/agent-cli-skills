---
name: grok-build-automation
description: Automate xAI Grok Build with headless mode, JSON output, session resume, ACP integration, Claude-compatible skills/plugins, and local verification caveats. Use when scripting Grok Build, comparing agent CLIs, or integrating Grok into bot-friendly workflows.
---

# Grok Build Automation

> **Verification status (2026-05-17):** Headless mode, output formats, prompt files,
> prompt JSON arrays, actual-session-id resume, model listing, and ACP initialize
> were verified locally against `grok 0.1.211 (2f2cd6d5c2)`. xAI docs were
> cross-checked on 2026-05-17; the relevant pages were last updated 2026-05-14.
> Richer local flags such as `--check`, `--best-of-n`, `--permission-mode`,
> `--worktree`, and `--sandbox` are help-exposed, but only partially workflow
> verified. Treat them as advanced surfaces until reproduced in your environment.

## Overview

Grok Build is xAI's coding-agent CLI. It supports an interactive TUI, a headless
single-prompt mode for scripts, and an ACP stdio server for editor or orchestrator
integrations.

Basic invocation:

```bash
grok -p "Your prompt here"
grok -p "Explain this codebase" --output-format json
grok -p "Explain the architecture" --output-format streaming-json
```

**Key differentiators from other CLI agents:**

- **Bot-friendly headless mode** - `grok -p` exits after one prompt and supports
  `plain`, `json`, and `streaming-json`.
- **ACP first-class path** - `grok agent stdio` speaks JSON-RPC over stdio for
  editor and orchestrator integrations.
- **Claude Code compatibility** - official docs say Grok reads Claude skills,
  plugins, MCPs, hooks, agents, and instruction files alongside `.grok/`.
- **Large local flag surface** - the installed binary exposes `--best-of-n`,
  `--check`, `--agents`, `--permission-mode`, `--worktree`, `--sandbox`,
  `memory`, `sessions`, and `models`.

**When to use this skill:**

- Running Grok Build from shell scripts or bot workflows
- Capturing machine-readable output from Grok
- Continuing a verified session from an actual `sessionId`
- Integrating Grok with an ACP client
- Auditing how Grok discovers existing Claude Code skills/plugins/hooks

**Prerequisites:**

- Grok Build installed with xAI's installer: `curl -fsSL https://x.ai/cli/install.sh | bash`
- Authenticated with `grok login`, cached local auth, or `GROK_CODE_XAI_API_KEY`
- For automation, run `grok inspect` first to see loaded instructions, skills,
  plugins, hooks, and MCP servers.

---

## Decision Router

### "I want to call Grok from a script or bot"

-> Read [reference/cli-flags.md](reference/cli-flags.md)

Key flags: `-p`, `--output-format`, `--disable-web-search`, `--no-plan`, `--max-turns`

### "I need JSON or streaming events"

-> Read [reference/json-output.md](reference/json-output.md)

Use `--output-format json` for a final JSON object or `streaming-json` for JSONL.

### "I want to continue previous context"

-> Read [reference/cli-flags.md](reference/cli-flags.md#session-flags)

Verified path: capture the generated `sessionId` from JSON output, then resume
with `--resume <sessionId>`.

### "I want to embed Grok behind another tool"

-> Read [reference/subcommands.md](reference/subcommands.md#acp-grok-agent-stdio)

Use `grok agent stdio` and JSON-RPC ACP messages.

### "Something behaved strangely"

-> Read [reference/known-issues.md](reference/known-issues.md)

Start with loaded Claude-compatible config, hooks, and plugins; they are a common
source of noisy stderr and surprising behavior.

---

## Quick Start Recipes

### Recipe 1: Simple Headless Call

```bash
grok -p "Reply with exactly OK" \
  --output-format plain \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

### Recipe 2: Final JSON Object

```bash
grok -p "Reply with exactly OK" \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10 | jq .
```

Verified output shape:

```json
{
  "text": "OK",
  "stopReason": "EndTurn",
  "sessionId": "...",
  "requestId": "...",
  "thought": "..."
}
```

### Recipe 3: Streaming JSONL

```bash
grok -p "Reply with exactly OK" \
  --output-format streaming-json \
  --disable-web-search \
  --no-plan \
  --max-turns 10 | jq -c .
```

Observed event types were `thought`, `text`, and `end`.

### Recipe 4: Prompt File

```bash
printf 'Reply with exactly OK\n' > prompt.txt

grok --prompt-file prompt.txt \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

### Recipe 5: Resume a Verified Session

```bash
session_id=$(
  grok -p "Remember the word BRAVO. Reply with exactly stored." \
    --output-format json \
    --disable-web-search \
    --no-plan \
    --max-turns 10 |
    jq -r '.sessionId'
)

grok -p "What word did I ask you to remember? Reply with just the word." \
  --resume "$session_id" \
  --output-format plain \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Local result: `BRAVO`.

### Recipe 6: ACP Initialize Smoke Test

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}}}' |
  grok agent stdio
```

Expect a JSON-RPC response with `protocolVersion: 1`, auth methods such as
`cached_token` or `grok.com`, and model metadata under `_meta.modelState`.

---

## Critical Gotchas

1. **Run `grok inspect` before trusting a smoke test** - Grok can load existing
   Claude-compatible skills, plugins, MCPs, hooks, agents, and instruction files.
   In the verified local environment, Grok loaded many `~/.claude` resources and
   emitted plugin/skill/hook warnings on stderr.

2. **Use `--max-turns 10` or higher for trivial smoke tests** - `--max-turns 1`
   can fail before completion because Grok counts internal prompt messages.

3. **Resume by actual `sessionId`, not a named `--session-id`, until verified** -
   the installed CLI accepted `--session-id`, but the locally tested named-session
   workflow did not resume as expected. The JSON `sessionId` path worked.

4. **`--check` is not a cheap validation flag** - local tests with `--check` used
   extra turns, attempted self-verification behavior, and produced a cancelled
   JSON response in one smoke test. Treat it as workflow-specific.

5. **`--best-of-n` fans out and needs a higher turn budget** - `--best-of-n 2`
   hit `max_turns exceeded` at 10 turns and passed at 20 turns.

6. **Permission and sandbox flags need task-specific verification** - `--sandbox`
   and `--permission-mode` are exposed by local help and official docs discuss
   permission modes, but the local write/sandbox probes were not stable enough
   to document as hard guarantees.

---

## File Map

| File | Description | Load When |
|---|---|---|
| `reference/cli-flags.md` | Verified headless flags plus help-exposed advanced flags | Need exact syntax |
| `reference/json-output.md` | `json`, `streaming-json`, prompt JSON, parsing patterns | Consuming output in scripts |
| `reference/subcommands.md` | `agent`, `models`, `sessions`, `memory`, `worktree`, ACP | Using non-headless commands |
| `reference/code-snippets.md` | Bash and Node starting points | Building integrations |
| `reference/known-issues.md` | Local and upstream gotchas | Debugging behavior drift |

## Sources

- xAI Grok Build overview: <https://docs.x.ai/build/overview>
- xAI headless and scripting docs: <https://docs.x.ai/build/cli/headless-scripting>
- xAI skills/plugins docs: <https://docs.x.ai/build/features/skills-plugins-marketplaces>
- xAI modes and commands docs: <https://docs.x.ai/build/modes-and-commands>
