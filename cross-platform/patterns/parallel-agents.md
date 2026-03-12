# Multi-Agent Orchestration Pattern

How to run multiple AI agents in parallel and aggregate results across all three CLI agents.

## The Pattern

Fork N parallel CLI processes, each with a unique perspective or task, then join and aggregate:

```
              ┌── Agent 1 (perspective A) ──┐
              │                              │
Prompt ──────>├── Agent 2 (perspective B) ──>├──> Aggregator ──> Final Output
              │                              │
              └── Agent 3 (perspective C) ──┘
```

This works identically across all three CLIs because the orchestration is in bash, not the CLI itself.

## Implementation: Debate Engine

### Claude Code

```bash
claude -p "$PERSONA_PROMPT" \
  --output-format json \
  --no-session-persistence \
  --append-system-prompt "$PERSONA" \
  > "/tmp/debater-$role.json" &
```

**Key flags:**
- `--append-system-prompt` sets the persona without replacing defaults
- `--output-format json` for structured parsing
- `--no-session-persistence` prevents session file buildup

### Codex CLI

```bash
codex exec "$PERSONA_PROMPT" \
  --ephemeral \
  -o "/tmp/debater-$role.txt" &
```

**Key flags:**
- `-o` writes clean output to file (no stdout parsing needed)
- `--ephemeral` prevents session persistence

### Gemini CLI

```bash
gemini -p "$PERSONA_PROMPT" \
  -m gemini-2-5-flash \
  > "/tmp/debater-$role.txt" &
```

**Key flags:**
- `-m gemini-2-5-flash` for speed (debaters don't need the best model)
- Default headless mode is already stateless

## The Fork/Join Pattern

```bash
#!/usr/bin/env bash
# Generic multi-agent pattern — works with any CLI

CLI_CMD="${CLI_CMD:-claude -p}"  # Set to "codex exec" or "gemini -p"
TOPIC="$1"
OUTDIR="/tmp/multi-agent-$(date +%s)"
mkdir -p "$OUTDIR"

# Define perspectives
PERSPECTIVES=(
  "You are an optimist. Argue in favor."
  "You are a skeptic. Argue against."
  "You are a historian. Provide context."
)
ROLES=("optimist" "skeptic" "historian")

# Fork: launch all agents in parallel
for i in "${!ROLES[@]}"; do
  role="${ROLES[$i]}"
  prompt="${PERSPECTIVES[$i]} Topic: $TOPIC. Respond with a concise argument."
  $CLI_CMD "$prompt" > "$OUTDIR/$role.txt" &
  echo "Started $role (PID $!)"
done

# Join: wait for all to finish
wait
echo "All agents complete."

# Aggregate: combine results
{
  for role in "${ROLES[@]}"; do
    echo "=== $role ==="
    cat "$OUTDIR/$role.txt"
    echo ""
  done
} > "$OUTDIR/combined.txt"

# Synthesize: run a final aggregation pass
$CLI_CMD "Synthesize these perspectives into a balanced summary:

$(cat "$OUTDIR/combined.txt")" > "$OUTDIR/synthesis.txt"

cat "$OUTDIR/synthesis.txt"
```

## Scaling Considerations

### Parallelism Limits

| CLI | Practical Parallel Limit | Bottleneck |
|-----|--------------------------|------------|
| Claude Code | 5-10 concurrent | API rate limits |
| Codex CLI | 5-10 concurrent | API rate limits |
| Gemini CLI | 5-10 concurrent (free tier: ~3-5) | 60 requests/minute quota |

### Rate Limiting for Gemini Free Tier

```bash
# Batch launches with pauses
BATCH_SIZE=5
for i in "${!ROLES[@]}"; do
  # Launch agent
  gemini -p "$prompt" > "$OUTDIR/${ROLES[$i]}.txt" &

  # Pause every BATCH_SIZE launches
  if [ $(( (i + 1) % BATCH_SIZE )) -eq 0 ]; then
    wait
    sleep 2
  fi
done
wait
```

### Error Recovery

```bash
# Retry failed agents
for role in "${ROLES[@]}"; do
  if [ ! -s "$OUTDIR/$role.txt" ]; then
    echo "Retrying $role..."
    $CLI_CMD "${PERSPECTIVES[$i]}" > "$OUTDIR/$role.txt"
  fi
done
```

## Advanced: Structured Output Aggregation

For machine-readable aggregation, request JSON from each agent:

```bash
# Each agent outputs JSON
$CLI_CMD "Respond as JSON: {\"role\": \"$role\", \"position\": \"for/against\", \"argument\": \"...\"}" \
  > "$OUTDIR/$role.json" &

# After join, merge into a JSON array
jq -s '.' "$OUTDIR"/*.json > "$OUTDIR/all.json"
```

See the [structured output patterns](structured-output.md) for CLI-specific JSON handling.
