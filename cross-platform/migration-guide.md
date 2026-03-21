# Migration Guide: Porting Between CLI Agents

How to port automation scripts and skills between Claude Code, Codex CLI, and Gemini CLI.

## The Rosetta Stone

The same task — "review a PR diff" — implemented in all three CLIs:

### Claude Code

```bash
git diff main...HEAD | claude -p \
  "Review this diff for bugs and security issues" \
  --output-format json \
  --no-session-persistence | jq -r '.result'
```

### Codex CLI

```bash
git diff main...HEAD | codex exec - \
  "Review this diff for bugs and security issues" \
  --json \
  --ephemeral | jq -r '.content'
```

### Gemini CLI

```bash
git diff main...HEAD | gemini -p \
  "Review this diff for bugs and security issues" \
  --output-format json | jq -r '.response'
```

## Flag Translation Table

| Concept | Claude Code | Codex CLI | Gemini CLI |
|---------|------------|-----------|------------|
| Run non-interactively | `claude -p "prompt"` | `codex exec "prompt"` | `gemini -p "prompt"` |
| Pipe from stdin | `echo "x" \| claude -p` | `echo "x" \| codex exec -` | `echo "x" \| gemini` |
| JSON output | `--output-format json` | `--json` | `--output-format json` |
| Streaming | `--output-format stream-json --verbose` | `--json` (JSONL events) | `--output-format stream-json` |
| Auto-approve all | `--dangerously-skip-permissions` | `--full-auto --dangerously-bypass-approvals-and-sandbox` | `-y` / `--yolo` |
| Stateless | `--no-session-persistence` | `--ephemeral` | Default (sessions available with `-r`/`--resume`) |
| Model select | `--model sonnet` | `--model o3` | `-m gemini-2-5-flash` |
| System prompt | `--append-system-prompt "..."` | Via AGENTS.md | Via GEMINI.md |
| Budget limit | `--max-budget-usd 1.00` | — | — |

## JSON Output Shape Differences

The JSON response structure differs across CLIs:

### Claude Code
```json
{
  "result": "The response text",
  "structured_output": {},
  "cost_usd": 0.003,
  "session_id": "abc123",
  "is_error": false
}
```
- Main text is in `.result`
- Schema-validated data is in `.structured_output`
- Includes cost tracking

### Codex CLI
```jsonl
{"type": "thread.started", "thread_id": "..."}
{"type": "turn.started", "turn_id": "..."}
{"type": "item.completed", "item": {"type": "message", "content": [{"type": "text", "text": "The response text"}]}}
{"type": "turn.completed", "turn_id": "..."}
```
- JSONL (one event per line) with `--json` flag
- Filter for `type == "item.completed"` and `item.type == "message"` to get the response
- Or use `-o file.txt` for clean output

### Gemini CLI
```json
{
  "session_id": "abc123",
  "response": "The response text",
  "statistics": {"model_requests": 1, "input_tokens": 100, "output_tokens": 50},
  "error": null
}
```
- Main text is in `.response`
- Includes token/request statistics
- Error field present even on success (null)

## Common Migration Patterns

### Pattern 1: Simple One-Shot Script

**From Claude Code:**
```bash
result=$(claude -p "Summarize this" --no-session-persistence < file.py)
```

**To Codex CLI:**
```bash
result=$(cat file.py | codex exec - "Summarize this" --ephemeral)
```

**To Gemini CLI:**
```bash
result=$(gemini -p "Summarize this" < file.py)
```

### Pattern 2: Batch Processing Loop

**From Claude Code:**
```bash
for f in src/*.py; do
  claude -p "Analyze this file" --output-format json --no-session-persistence < "$f" | jq -r '.result'
done
```

**To Codex CLI:**
```bash
for f in src/*.py; do
  codex exec "Analyze this file" --ephemeral -o /dev/stdout < "$f"
done
```

**To Gemini CLI:**
```bash
for f in src/*.py; do
  gemini -p "Analyze this file" -m gemini-2-5-flash < "$f"
  sleep 1  # Rate limit
done
```

### Pattern 3: Parallel Execution with Aggregation

All three CLIs support the same bash fork/join pattern:

```bash
# Works for all three — just change CLI_CMD
CLI_CMD="claude -p"       # or "codex exec" or "gemini -p"

for topic in "security" "performance" "readability"; do
  $CLI_CMD "Analyze this code for $topic issues" > "/tmp/$topic.txt" &
done
wait

cat /tmp/security.txt /tmp/performance.txt /tmp/readability.txt > analysis.txt
```

### Pattern 4: CI/CD GitHub Action

The structure is identical — only the install command, env var, and CLI invocation change:

| Step | Claude Code | Codex CLI | Gemini CLI |
|------|------------|-----------|------------|
| Install | `npm i -g @anthropic-ai/claude-code` | `npm i -g @openai/codex` | `npm i -g @google/gemini-cli` |
| Auth env var | `ANTHROPIC_API_KEY` | `OPENAI_API_KEY` | `GEMINI_API_KEY` |
| Review command | `claude -p "..." --no-session-persistence` | `codex exec "..." --ephemeral` | `gemini -p "..." -m gemini-2-5-flash` |

## Gotchas When Migrating

### Claude Code → Codex CLI
- Replace `< file.py` with `cat file.py | codex exec -` (stdin needs the `-` flag)
- Replace `--no-session-persistence` with `--ephemeral`
- Replace `--output-format json | jq '.result'` with `-o output.txt` (cleaner)
- Remove `--verbose` (not needed for Codex JSON)

### Claude Code → Gemini CLI
- Replace `--no-session-persistence` — Gemini is stateless by default in headless mode (use `-r`/`--resume` for sessions)
- Replace `--output-format json | jq '.result'` with `--output-format json | jq '.response'`
- Add rate limiting (`sleep 1`) for batch loops on free tier
- Replace `--dangerously-skip-permissions` with `-y` (or `--yolo`)

### Codex CLI → Gemini CLI
- Replace `codex exec` with `gemini -p`
- Replace `--json` with `--output-format json` (or `--output-format stream-json` for streaming)
- Replace `--ephemeral` — not needed (Gemini is stateless by default)
- Replace `-o file.txt` with `> file.txt` (redirect)
- Add `-m gemini-2-5-flash` for speed-optimized tasks

## Config File Migration

| Source | Target | What to Do |
|--------|--------|------------|
| CLAUDE.md | AGENTS.md | Copy content; AGENTS.md format is similar but also works with Copilot/Cursor |
| CLAUDE.md | GEMINI.md | Copy content; add `@import` syntax for modularity if needed |
| AGENTS.md | GEMINI.md | Direct copy works; consider `@import` for large files |
| AGENTS.md | CLAUDE.md | Direct copy works |

All three use markdown with natural language instructions. The content is portable — only the filename and location changes.
