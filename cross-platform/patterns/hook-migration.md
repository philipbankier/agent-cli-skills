# Cross-CLI Hook Migration

How to port hooks between Claude Code, Codex CLI, and Gemini CLI — and how to write hooks that are portable from day one.
Verified against Claude Code v2.1.104, Codex CLI v0.114.0, Gemini CLI v0.33.0 on 2026-04-14.

## The Surprising State of the Art

Of the three major CLIs, exactly one ships a **native** cross-CLI hook port command:

```bash
gemini hooks migrate
```

That's it. There is no `claude hooks import-from-gemini`, no `codex hooks migrate`, no shared spec. The Claude Code → Gemini direction is the only one with a one-shot tool.

This guide covers:

1. The native `gemini hooks migrate` command (what it does and what it doesn't)
2. Manual port recipes for the other directions
3. How to write hooks portably from day one so you avoid migration entirely

## Native: `gemini hooks migrate` (Claude → Gemini)

```bash
cd path/to/project-with-claude-hooks
git status                # MUST be clean — review the migration diff afterwards
gemini hooks migrate
git diff                  # inspect what got translated
```

What it does:

- Reads Claude Code hook configurations from `.claude/` and/or settings files in the current project
- Translates them into Gemini's hook format and writes them into the project's Gemini configuration
- Best-effort mapping of event types and trigger semantics

What it does **not** guarantee:

- 100% lossless translation — Claude-Code-specific event types may not have direct Gemini equivalents
- Behavioral parity — even when an event maps cleanly, the surrounding execution context (cwd, env, available tools) differs between CLIs
- Idempotency on re-run — running `migrate` twice may double-write entries; commit before running

**Always commit before running and review the diff afterwards.** Treat the output as a starting point that you then test and fix, not as a finished port.

## Manual: Claude → Codex

There's no native command. Translate by hand:

| Claude Code | Codex CLI equivalent |
|------------|---------------------|
| Pre-tool-use hook | Custom slash command in `~/.codex/config.toml` that wraps `codex exec` with the same prompt |
| Post-tool-use hook | Same — wrap the agent invocation, append a post-step to the slash-command pipeline |
| Stop hook (formatter / linter) | Append the formatter/linter invocation to your `AGENTS.md` instructions, or wrap the agent run in a shell script |
| Pre-tool-use safety check | `codex exec --sandbox read-only` (in-CLI), or `codex sandbox <os>` (OS-level) |
| Notification hook | Pipe `codex exec --json` through a notifier process |

The mental model: Codex doesn't have a first-class "hook" abstraction the way Claude and Gemini do. You translate hook intent into either (a) wrapper shell scripts, (b) MCP server tools, or (c) `AGENTS.md` instructions.

### Recipe: porting a Claude Code stop hook to Codex

Claude Code stop hook (in `.claude/hooks/`):

```json
{
  "name": "format-and-test",
  "events": ["Stop"],
  "command": "npm run format && npm test"
}
```

Codex CLI equivalent (wrapper shell script):

```bash
#!/usr/bin/env bash
set -euo pipefail

# Run the Codex agent
codex exec --full-auto "$@"

# Equivalent of the Stop hook: always run after the agent completes
npm run format
npm test
```

Save as `~/bin/codex-with-stop-hook` and use it instead of `codex exec` directly.

## Manual: Codex → Claude

Codex's `AGENTS.md` instructions become Claude's `CLAUDE.md` instructions. Most of what passes for "hook behavior" in Codex is just "instructions in `AGENTS.md` saying to run X after Y."

| Codex CLI pattern | Claude Code equivalent |
|-------------------|----------------------|
| `AGENTS.md` always-on instructions | `CLAUDE.md` always-on instructions |
| Custom slash command in config.toml | `.claude/commands/<name>.md` slash command |
| `codex exec --full-auto` wrapper script | `.claude/hooks/` real hook with `events` array |
| MCP server providing a tool | `claude mcp add` to register the same MCP server in Claude Code |

The Claude Code hook system is the more expressive of the two — anything Codex can do via wrapper scripts, Claude can do as a real hook.

## Manual: Gemini → Claude

Use the Claude Code hooks system directly. Gemini's hook format is similar in spirit (event types + commands), but the event vocabulary differs. Manual mapping required:

| Gemini CLI hook event | Claude Code hook event |
|----------------------|----------------------|
| Pre-task | Pre-tool-use |
| Post-task | Post-tool-use / Stop |
| Tool-call | Pre-tool-use |
| Session-end | Stop |

There is no `claude hooks migrate` equivalent. You'll re-create each hook in the Claude Code format under `.claude/hooks/` (or via the settings file) and validate by running an actual session.

## Writing Portable Hooks From Day One

If you suspect you'll need to support multiple CLIs eventually, structure your hook logic outside any one CLI's hook format:

### Pattern: shell script wrapper that all three CLIs invoke

```bash
#!/usr/bin/env bash
# scripts/post-agent-checks.sh — runs after the agent finishes, regardless of which CLI

set -euo pipefail

EVENT_TYPE="${1:?usage: $0 <event-type> [agent-output-file]}"
OUTPUT_FILE="${2:-}"

case "$EVENT_TYPE" in
  pre-tool-use)
    # Lint check, blocking
    if [[ -n "$OUTPUT_FILE" ]]; then
      ./scripts/lint-staged.sh
    fi
    ;;
  post-tool-use)
    npm run format
    ;;
  stop)
    npm run format && npm test
    ;;
  *)
    echo "Unknown event: $EVENT_TYPE" >&2
    exit 1
    ;;
esac
```

Each CLI's hook config then just calls the script:

**Claude Code (`.claude/hooks/*.json` or settings):**
```json
{
  "name": "post-checks",
  "events": ["Stop"],
  "command": "./scripts/post-agent-checks.sh stop"
}
```

**Codex CLI** — wrap `codex exec` in a shell script that calls the same script after.

**Gemini CLI** — register the same script as a stop-equivalent hook (`gemini hooks` config).

This way the actual logic (`scripts/post-agent-checks.sh`) is one file, version-controlled, testable in isolation, and identical across CLIs. Only the per-CLI registration glue differs.

### Pattern: idempotent hooks that don't depend on agent context

The other portable trick is making your hooks *not depend* on event-type-specific context. If your hook is "always format and test after any change," it doesn't care whether it was triggered by a stop event or a post-tool-use event — it just runs. Such hooks port trivially because there's no event-vocabulary mismatch to translate.

## Common Mistakes

- **Running `gemini hooks migrate` on uncommitted changes** — if the translation produces something wrong, you can't `git diff` to see what changed. Always commit before running.
- **Assuming Claude → Codex is a CLI-supported port** — it's not. There's no `codex hooks` command at all. Translation is manual.
- **Writing hooks that depend on CLI-specific event metadata** — a hook that reads `$CLAUDE_TOOL_NAME` or similar will not port. Wrap such logic in a shell script that takes its needed context as positional args.
- **Forgetting that hooks run as subprocesses with the agent's environment** — a hook that depends on shell aliases or interactive-only variables will silently fail. Test from a non-interactive shell first.
- **Letting `gemini hooks migrate` run on a project that has both Claude *and* Gemini hooks already configured** — it may overwrite or merge in unexpected ways. Treat it as a one-time port from a Claude-only project.

## Verification After Migration

Whichever direction you migrate, run an end-to-end test that exercises each migrated hook:

1. Trigger the corresponding agent action in the destination CLI
2. Confirm the hook fires by inspecting hook output / logs
3. Confirm the hook produces the same observable side effect as the original

For Claude Code v2.1.104, you can use `--include-hook-events` with `--output-format=stream-json --verbose` to see hook lifecycle events in the stream:

```bash
claude -p "Edit a file" \
  --output-format stream-json \
  --verbose \
  --include-hook-events \
  | jq -r 'select(.type | startswith("hook"))'
```

For Codex and Gemini, hook events surface in their respective debug/log output.

## See Also

- [skill-installation.md](skill-installation.md) — companion guide for cross-CLI skill packaging
- [../../skills/gemini-cli/reference/subcommands.md](../../skills/gemini-cli/reference/subcommands.md#gemini-hooks--hook-management) — `gemini hooks migrate` reference
- [../../skills/claude-code/reference/print-mode-flags.md](../../skills/claude-code/reference/print-mode-flags.md#combination-36-include-hook-events-in-stream) — `--include-hook-events` reference
- [../../skill-authoring/cross-platform.md](../../skill-authoring/cross-platform.md) — designing skills/hooks for portability from day one
