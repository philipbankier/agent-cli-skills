# Subagent Orchestration: Worktrees, Tmux, Parallel Agents

How to spawn, isolate, and coordinate multiple AI agents working in parallel — across Claude Code, Codex CLI, and Gemini CLI.
Verified against Claude Code v2.1.104, Codex CLI v0.114.0, Gemini CLI v0.33.0 on 2026-04-14.

## When to Reach For This Pattern

You want subagent orchestration when:

- A task is decomposable into independent subtasks (e.g., "analyze each file in this directory and return findings")
- You want N agents to attack the same problem from different angles and merge the results (e.g., the debate engine pattern)
- You're running long-lived experiments and don't want them to step on each other's git state
- You want to bound blast radius — if one agent goes off the rails, the others (and your main worktree) are unaffected

You do NOT want this pattern when:

- The subtasks have data dependencies (use sequential resume instead)
- The total work fits comfortably in a single agent's context window
- You're not doing anything that would benefit from filesystem isolation (use a single agent with tool-call parallelism)

## The Three Building Blocks

Subagent orchestration on these CLIs combines three concerns:

1. **Workspace isolation** — each agent gets its own git working directory so file edits don't collide
2. **Process separation** — each agent runs as its own CLI process so they can run truly in parallel
3. **Display multiplexing** — you (or a coordinator) can watch them all without losing track

Each CLI handles these differently.

## Claude Code: `--worktree` + `--tmux` + `--agents`

Claude Code v2.1.104 ships native support for all three concerns.

```bash
# Spawn an agent in its own worktree, with its own tmux pane
claude --worktree experiment-a --tmux \
  --agents '{"explorer": {"description": "Architecture explorer", "prompt": "You are a code archaeologist..."}}' \
  --agent explorer

# Same, but the worktree gets a meaningful display name
claude --worktree experiment-a --tmux -n "explorer-a" --agent explorer
```

What this does:

- **`--worktree experiment-a`** — creates `.claude/worktrees/experiment-a/` as a real git worktree off the current branch. The agent's edits land inside that worktree, leaving your primary worktree untouched.
- **`--tmux`** — opens a tmux pane (or iTerm2 native pane on macOS) attached to that worktree. Use `--tmux=classic` if you want traditional tmux instead of iTerm2 native panes.
- **`--agents <json>`** — defines an inline custom agent for this run. It's ephemeral — not persisted to `.claude/agents/`. Pair with `--agent <name>` to actually select one of the agents you defined.
- **`-n "explorer-a"`** — gives the session a display name shown in `/resume` and the terminal title. Critical when you have several panes open.

> **Required pairing:** `--tmux` is rejected without `--worktree`. The intent is that tmux pane management is scoped to worktrees.

### Spawning N agents in parallel from a script

```bash
#!/usr/bin/env bash
# spawn-experiments.sh — kick off N Claude Code agents in parallel worktrees

set -euo pipefail

PROMPT="${1:?Usage: spawn-experiments.sh 'task description'}"
N="${2:-3}"

for i in $(seq 1 "$N"); do
  WORKTREE="experiment-$i"
  claude --worktree "$WORKTREE" --tmux \
         -n "exp-$i" \
         --agents "{\"researcher\": {\"description\": \"Approach $i\", \"prompt\": \"You are exploring approach number $i.\"}}" \
         --agent researcher \
         --append-system-prompt "Take a different angle than the others. Note your decisions in NOTES.md inside this worktree." \
         --max-budget-usd 0.50 \
         -p "$PROMPT" &
done

wait

# Diff each worktree against main
for i in $(seq 1 "$N"); do
  echo "=== Worktree experiment-$i ==="
  git -C ".claude/worktrees/experiment-$i" diff main --stat
done
```

Cleanup is your responsibility — `git worktree remove .claude/worktrees/experiment-1` once you've harvested the result.

## Codex CLI: `fork` + `cloud exec` + `sandbox`

Codex doesn't have a native worktree+tmux pattern, but it does have two strong primitives.

### `codex fork` for divergent exploration

```bash
# Step 1: Run a baseline interactive session
codex resume --last     # or start fresh

# Step 2: Fork the session into multiple branches that explore different paths
codex fork --last "Try approach A: prioritize correctness over speed"
codex fork --last "Try approach B: prioritize speed over correctness"
codex fork --last "Try approach C: avoid the framework entirely"
```

`codex fork` creates a new session by branching from a previous interactive session. The original session is left intact. Each fork can diverge in its own direction. This is the closest analog Codex has to "spawn N variants of the same agent."

### `codex cloud exec` for remote parallel execution

```bash
# Submit several cloud tasks without launching the TUI
codex cloud exec "Analyze auth/ for security issues" &
codex cloud exec "Analyze auth/ for performance issues" &
codex cloud exec "Analyze auth/ for code-style issues" &
wait

# List running tasks
codex cloud list

# Apply diffs locally as each completes
for task_id in $(codex cloud list | awk '{print $1}'); do
  codex cloud apply "$task_id"
done
```

`codex cloud` is marked experimental. The architectural idea is that cloud tasks run on remote infrastructure (no local CPU contention) and you pull the resulting diffs back via `cloud apply` or top-level `codex apply`.

### `codex sandbox` for OS-level isolation

When you spawn parallel agents that run shell commands, isolating each one in an OS sandbox prevents one agent's misstep from corrupting the others.

```bash
codex sandbox macos -- codex exec --full-auto "Run the test suite"
codex sandbox linux -- codex exec --full-auto "Run the test suite"
codex sandbox windows -- codex exec --full-auto "Run the test suite"
```

See [os-sandboxing.md](os-sandboxing.md) for the full sandboxing comparison.

## Gemini CLI: `--include-directories` + extensions for parallel runs

Gemini doesn't have native worktree or fork primitives. Workarounds:

### Workspace expansion via `--include-directories`

```bash
# Run several Gemini agents in parallel, each scoped to a different directory
gemini -p "Analyze auth/" --include-directories ./src/auth -y &
gemini -p "Analyze billing/" --include-directories ./src/billing -y &
gemini -p "Analyze users/" --include-directories ./src/users -y &
wait
```

This isn't true workspace isolation (they're all writing to the same git tree if they make edits), so pair with `--approval-mode plan` to keep them read-only:

```bash
for area in auth billing users; do
  gemini -p "Audit $area for security issues" \
    --include-directories "./src/$area" \
    --approval-mode plan \
    -o json > "audit-$area.json" &
done
wait
```

### Extensions for restricted-tool parallel runs

```bash
# Spawn agents with different extension sets for different roles
gemini -p "Run security review" -e security-extension-pack &
gemini -p "Run perf review" -e perf-extension-pack &
wait
```

`-e` restricts which extensions are loaded for that run. Useful when different parallel agents should have different tool palettes.

## Cross-CLI Comparison

| Concern | Claude Code | Codex CLI | Gemini CLI |
|---------|------------|-----------|------------|
| Filesystem isolation | `--worktree <name>` (native git worktree) | None (use OS sandbox or git worktree manually) | None (use `--approval-mode plan` for safety) |
| Display multiplexing | `--tmux` (with `--worktree`) | None | None |
| Spawn N variants of one agent | `--agents <json>` + N parallel `claude -p` calls in worktrees | `codex fork` from a baseline session | N parallel `gemini -p` calls with different prompts |
| Cloud-side parallel execution | None | `codex cloud exec` | None |
| OS-level sandboxing | `--permission-mode plan` (in-CLI gating) | `codex sandbox <os>` (true OS sandbox) | `--sandbox` (CLI-level) |
| Best for parallel agents | When you want full local isolation per agent | When you want remote execution with diff harvesting | When you want lightweight read-only audits |

## Decision Tree

```
Need parallel agents?
├── Need local filesystem isolation?
│   ├── Yes  → Claude Code --worktree + --tmux
│   └── No   → Any CLI in parallel with shared workspace
│
├── Need remote execution to avoid local CPU/memory contention?
│   └── Codex CLI cloud exec
│
├── Need to fork from a known-good baseline session?
│   ├── Codex CLI codex fork
│   └── (Claude Code: --fork-session with --resume / --continue)
│
└── Need read-only audits across many directories?
    └── Gemini CLI -p + --include-directories + --approval-mode plan
```

## Working Example: 3-Agent Audit + Coordinator

This pattern fans out three agents, each with a different focus, then runs a coordinator pass over all three results.

```bash
#!/usr/bin/env bash
set -euo pipefail
OUTDIR=$(mktemp -d)
trap 'rm -rf "$OUTDIR"' EXIT

CODEBASE="${1:-./src}"

# Phase 1: Three parallel Claude Code agents in isolated worktrees
for ANGLE in security performance maintainability; do
  claude --worktree "audit-$ANGLE" --tmux \
         -n "audit-$ANGLE" \
         --append-system-prompt "Focus exclusively on $ANGLE. Output findings as JSON." \
         --output-format json \
         --json-schema '{"type":"object","properties":{"findings":{"type":"array","items":{"type":"object","properties":{"severity":{"type":"string"},"file":{"type":"string"},"issue":{"type":"string"},"recommendation":{"type":"string"}}}}},"required":["findings"]}' \
         --max-budget-usd 0.75 \
         -p "Audit $CODEBASE for $ANGLE issues. Be specific." \
         > "$OUTDIR/$ANGLE.json" &
done
wait

# Phase 2: Coordinator pass synthesizes the three audits into a ranked list
COMBINED=$(jq -s '{security: .[0], performance: .[1], maintainability: .[2]}' \
  "$OUTDIR/security.json" "$OUTDIR/performance.json" "$OUTDIR/maintainability.json")

echo "$COMBINED" | claude -p \
  --append-system-prompt "You are a coordinator. Synthesize these three audits into a single ranked action list." \
  --output-format json \
  --max-budget-usd 0.50 \
  > "$OUTDIR/synthesis.json"

cat "$OUTDIR/synthesis.json" | jq '.'

# Cleanup worktrees
for ANGLE in security performance maintainability; do
  git worktree remove --force ".claude/worktrees/audit-$ANGLE" 2>/dev/null || true
done
```

## See Also

- [cost-control.md](cost-control.md) — bounding spend across N parallel agents
- [os-sandboxing.md](os-sandboxing.md) — true OS isolation when one of the agents must run untrusted code
- [parallel-agents.md](parallel-agents.md) — earlier write-up focused on the multi-perspective debate engine
- [../../skills/claude-code/reference/print-mode-flags.md](../../skills/claude-code/reference/print-mode-flags.md#combination-38-worktree--tmux-parallel-run) — Combination 38 reference
- [../../skills/codex-cli/reference/subcommands.md](../../skills/codex-cli/reference/subcommands.md) — `codex fork`, `codex cloud`, `codex sandbox` reference
