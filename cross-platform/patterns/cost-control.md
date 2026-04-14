# Cost Control Across Claude Code, Codex CLI, and Gemini CLI

How to bound spend, optimize prompt cache reuse, and pick the right knobs for CI workloads.
Verified against Claude Code v2.1.104, Codex CLI v0.114.0, Gemini CLI v0.33.0 on 2026-04-14.

## Knob Inventory by CLI

| Concern | Claude Code | Codex CLI | Gemini CLI |
|---------|------------|-----------|------------|
| Hard spending cap | `--max-budget-usd <amount>` (only with `-p`) | None directly — bound via `--ephemeral` + per-task billing | None directly |
| Per-turn reasoning budget | `--effort {low,medium,high,max}` | Implicit per-model | Implicit per-model |
| Disable ambient state for clean runs | `--bare` (skip hooks/LSP/plugin sync/auto-memory/CLAUDE.md) | `--ephemeral` (skip session persist), `-c` overrides | `-e <names>` (restrict extensions) |
| Disable all tools (pure LLM) | `--tools ""` | None — manage via `--sandbox read-only` | `--approval-mode plan` (read-only) |
| Improve prompt cache reuse | `--exclude-dynamic-system-prompt-sections` | None directly | None directly |
| Cheaper fallback on overload | `--fallback-model <name>` (only with `-p`) | None | None |
| Pick a cheap fast model | `--model haiku` | `-m gpt-5.4-mini` (or whatever your account has) | `-m gemini-2.5-flash` |
| Track cumulative cost per call | `total_cost_usd` in `--output-format json` | `usage` fields in `--json` events | `statistics` in `--output-format json` |

## Pattern 1: Hard Cap CI Spending

The most reliable cost control is a hard cap that aborts the run before billing runs away.

### Claude Code

```bash
claude -p "Review this PR diff for security issues" \
  --max-budget-usd 0.50 \
  --output-format json \
  --no-session-persistence
```

If the run exceeds $0.50, the response comes back with `"subtype": "error_max_budget_usd"` instead of `"success"`. Check the subtype in your CI script:

```bash
RESULT=$(claude -p "..." --max-budget-usd 0.50 --output-format json --no-session-persistence)
SUBTYPE=$(echo "$RESULT" | jq -r '.subtype')

if [[ "$SUBTYPE" == "error_max_budget_usd" ]]; then
  echo "Budget cap hit — review prompt and tighten scope" >&2
  exit 2
fi

echo "$RESULT" | jq -r '.result'
```

### Codex CLI

Codex doesn't have a `--max-budget-usd` flag. The closest equivalents:

- **`--ephemeral`** — guarantees the session is fresh per run, so you don't accumulate context (and cost) across invocations
- **Pin a cheaper model** — `-m gpt-5.4-mini` or whatever your account has access to
- **Track cumulative spend** outside the CLI — parse `usage` fields from `--json` events and abort the next call yourself if you've spent enough

```bash
codex exec "Review this PR diff" \
  --ephemeral \
  --json \
  -m gpt-5.4-mini > events.jsonl

# Sum input/output tokens from events as a proxy for cost
INPUT_TOKENS=$(jq -r '.usage.input_tokens // 0' events.jsonl | awk '{s+=$1} END {print s}')
OUTPUT_TOKENS=$(jq -r '.usage.output_tokens // 0' events.jsonl | awk '{s+=$1} END {print s}')
```

### Gemini CLI

Same story as Codex: no native budget cap. Bound by:

- Picking the cheap model (`-m gemini-2.5-flash`)
- The free-tier daily request quota (1000 model requests/day on Google Account auth)
- Custom external tracking against `statistics.input_tokens` / `statistics.output_tokens` in `-o json`

```bash
gemini -p "Review this PR diff" \
  -m gemini-2.5-flash \
  -o json \
  --approval-mode plan > result.json
```

## Pattern 2: Cross-User Prompt Cache Reuse

The biggest cost win in practice isn't reducing per-call price — it's reusing the prompt cache across calls. Each CLI handles this differently.

### Claude Code: `--exclude-dynamic-system-prompt-sections`

Claude Code's default system prompt embeds per-machine details: cwd, env info, memory paths, git status. Two requests from two different machines (or two different working directories) effectively have different system prompts, so neither hits the cache.

`--exclude-dynamic-system-prompt-sections` moves those per-machine sections out of the system prompt and into the first user message instead. The system prompt is now stable across users/machines, and the cache hits.

```bash
# CI runner pattern: every parallel job shares the cached system prompt
claude -p "Classify this issue" \
  --exclude-dynamic-system-prompt-sections \
  --output-format json \
  --tools "" \
  --no-session-persistence \
  < issue-text.md
```

> Only applies when you're using the default system prompt. If you set `--system-prompt` (full replace), the flag is silently ignored.

Verify cache hits via `cache_read_input_tokens` in the JSON `usage` field. If it's > 0 and growing across calls, the cache is working.

### Codex CLI: implicit via session persistence

Codex doesn't expose a cache-stabilization flag. Its best practice is the opposite — keep sessions persistent (don't pass `--ephemeral`) so the agent can resume from a cached state.

```bash
# First call seeds the cache
codex exec --json "Analyze main.py" -o /tmp/first.txt

# Second call resumes and benefits from cache
codex exec resume --last "Now analyze utils.py" --json > /tmp/second.jsonl
```

### Gemini CLI: implicit, no fine-grained control

Gemini's caching is server-side and not directly user-controllable from the CLI.

## Pattern 3: `--bare` Mode for Clean CI

`--bare` is a Claude Code-only flag, but it's the strongest "minimal cost, minimal surprises" knob in the ecosystem. It skips:

- Hooks
- LSP integration
- Plugin sync
- Attribution metadata
- Auto-memory
- Background prefetches
- Keychain reads
- CLAUDE.md auto-discovery

It also forces auth strictly to `ANTHROPIC_API_KEY` or `apiKeyHelper` via `--settings`. OAuth and keychain are never touched.

```bash
# Cheapest possible Claude Code invocation: bare mode, no tools, ephemeral, cheap model
claude -p "Classify this issue: $(cat issue.md)" \
  --bare \
  --tools "" \
  --no-session-persistence \
  --model haiku \
  --max-budget-usd 0.05 \
  --output-format json \
  --append-system-prompt "Output JSON with one key: category"
```

You have to supply context explicitly when using `--bare`:

- `--system-prompt` / `--append-system-prompt` (or `*-file` variants)
- `--add-dir` for additional CLAUDE.md directories
- `--mcp-config` for MCP servers
- `--settings` for settings JSON
- `--agents` for inline agent definitions
- `--plugin-dir` for plugins

If a CI run fails because a stale plugin or leftover hook from a previous job is interfering, `--bare` is the fix.

## Pattern 4: Effort Budget Tuning

Claude Code `--effort {low,medium,high,max}` is the per-turn reasoning budget. Lower effort = less reasoning per turn = lower per-call cost. Use it as a coarse cost knob alongside `--model`:

```bash
# Cheap classifier
claude -p "Is this a bug report? Yes/No only." --effort low --model haiku --tools ""

# Cost-balanced general use (default)
claude -p "Summarize this PR" --effort medium

# Hard problem, willing to pay
claude -p "Refactor this state machine for clarity" --effort high

# Maximum capability — extended thinking unlocks at this level
claude -p "Find the bug in this distributed system trace" --effort max --model opus
```

## Pattern 5: Fallback to Cheap Model on Overload

```bash
claude -p "Review this PR" \
  --model opus \
  --fallback-model sonnet \
  --max-budget-usd 0.50 \
  --output-format json
```

`--fallback-model` triggers only on capacity errors (model overloaded), not on content errors. Transparent to caller. Use it to combine "use opus when available, sonnet when overloaded, abort if costs exceed cap."

When fallback fires, the JSON output's `modelUsage` field has both models in the per-model token breakdown.

## Pattern 6: Bound the Whole Pipeline

A typical CI pipeline mixes several techniques. Example:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Total budget for this CI job: $2.00
TOTAL_BUDGET_USD=2.00
PER_CALL_BUDGET_USD=0.40

CHANGED_FILES=$(git diff --name-only main...HEAD | head -5)

SPENT=0.0
for FILE in $CHANGED_FILES; do
  RESULT=$(claude -p "Review $FILE for bugs" \
    --bare \
    --tools "" \
    --add-dir "$(dirname "$FILE")" \
    --no-session-persistence \
    --model sonnet \
    --fallback-model haiku \
    --effort medium \
    --max-budget-usd "$PER_CALL_BUDGET_USD" \
    --exclude-dynamic-system-prompt-sections \
    --output-format json)

  COST=$(echo "$RESULT" | jq -r '.total_cost_usd // 0')
  SUBTYPE=$(echo "$RESULT" | jq -r '.subtype')

  if [[ "$SUBTYPE" == "error_max_budget_usd" ]]; then
    echo "Per-call budget exceeded for $FILE" >&2
    continue
  fi

  SPENT=$(awk -v s="$SPENT" -v c="$COST" 'BEGIN {printf "%.4f", s + c}')
  echo "$FILE: \$$COST (running total: \$$SPENT)"

  # Abort the pipeline if total budget is hit
  if awk -v s="$SPENT" -v t="$TOTAL_BUDGET_USD" 'BEGIN {exit !(s >= t)}'; then
    echo "Total budget exceeded — aborting" >&2
    break
  fi

  echo "$RESULT" | jq -r '.result' >> review.md
done
```

Knobs at work in this script:
- `--bare` strips ambient state for predictability
- `--tools ""` removes tool definition tokens from context
- `--no-session-persistence` keeps each call independent
- `--fallback-model haiku` cuts cost when sonnet is overloaded
- `--effort medium` is the default but pinned for clarity
- `--max-budget-usd` caps per-call spend
- `--exclude-dynamic-system-prompt-sections` improves cache reuse across files
- External `SPENT` accumulator caps total job spend

## See Also

- [subagent-orchestration.md](subagent-orchestration.md) — bound parallel agent runs
- [os-sandboxing.md](os-sandboxing.md) — when an agent must run untrusted commands
- [../../skills/claude-code/reference/print-mode-flags.md](../../skills/claude-code/reference/print-mode-flags.md) — flag reference for `--bare`, `--effort`, `--max-budget-usd`, `--fallback-model`, `--exclude-dynamic-system-prompt-sections`
