# Structured Output Patterns

How to get machine-readable JSON output from each CLI agent and normalize across platforms.

## JSON Output Comparison

### Claude Code

```bash
# JSON output with metadata
claude -p "List all functions" --output-format json --no-session-persistence < main.py

# Response shape:
# {
#   "result": "Here are the functions...",
#   "structured_output": null,
#   "cost_usd": 0.003,
#   "session_id": "...",
#   "is_error": false
# }

# Extract text response
claude -p "prompt" --output-format json < file.py | jq -r '.result'
```

### With JSON Schema Validation (Claude Code Only)

```bash
# Enforce structured output with a schema
claude -p "Extract function names from this code" \
  --output-format json \
  --json-schema '{
    "type": "object",
    "properties": {
      "functions": {"type": "array", "items": {"type": "string"}}
    },
    "required": ["functions"]
  }' \
  < main.py | jq '.structured_output'

# GOTCHA: Schema-validated data is in .structured_output, NOT .result
```

### Codex CLI

```bash
# JSONL event stream (events: thread.started, turn.started, item.completed, turn.completed)
codex exec "List all functions" --json --ephemeral

# Or save clean output to file
codex exec "List all functions" --ephemeral -o functions.txt
```

### Gemini CLI

```bash
# JSON with statistics
gemini -p "List all functions" --output-format json < main.py

# Response shape:
# {
#   "session_id": "abc123",
#   "response": "Here are the functions...",
#   "statistics": {"model_requests": 1, "input_tokens": 100, "output_tokens": 50},
#   "error": null
# }

# Extract text response
gemini -p "prompt" --output-format json < file.py | jq -r '.response'
```

## Requesting Structured JSON from Any CLI

When you need the model to return JSON (not just metadata), include it in the prompt:

```bash
PROMPT='List all functions in this file. Respond with ONLY a JSON array of strings, no other text.
Example: ["func1", "func2", "func3"]'

# Claude Code
claude -p "$PROMPT" --no-session-persistence < main.py

# Codex CLI
cat main.py | codex exec - "$PROMPT" --ephemeral

# Gemini CLI
gemini -p "$PROMPT" -m gemini-2-5-flash < main.py
```

## Normalizing Output Across CLIs

A wrapper function that returns consistent output regardless of which CLI is used:

```bash
#!/usr/bin/env bash
# normalize-output.sh — Consistent JSON output from any CLI

CLI="${CLI:-claude}"  # Set to "claude", "codex", or "gemini"

run_prompt() {
  local prompt="$1"
  local input_file="${2:-}"

  case "$CLI" in
    claude)
      if [ -n "$input_file" ]; then
        claude -p "$prompt" --output-format json --no-session-persistence < "$input_file" | jq -r '.result'
      else
        claude -p "$prompt" --output-format json --no-session-persistence | jq -r '.result'
      fi
      ;;
    codex)
      if [ -n "$input_file" ]; then
        cat "$input_file" | codex exec - "$prompt" --ephemeral
      else
        codex exec "$prompt" --ephemeral
      fi
      ;;
    gemini)
      if [ -n "$input_file" ]; then
        gemini -p "$prompt" -m gemini-2-5-flash < "$input_file"
      else
        gemini -p "$prompt" -m gemini-2-5-flash
      fi
      ;;
    *)
      echo "Unknown CLI: $CLI" >&2
      return 1
      ;;
  esac
}

# Usage:
# CLI=claude run_prompt "Summarize this" main.py
# CLI=gemini run_prompt "Explain this code" src/app.ts
```

## JSON Schema Support Matrix

| Feature | Claude Code | Codex CLI | Gemini CLI |
|---------|------------|-----------|------------|
| Schema validation flag | `--json-schema '{...}'` | `--output-schema` | — |
| Schema-validated field | `.structured_output` | — | — |
| Free-text response | `.result` | stdout / `-o` file | `.response` |
| Prompt-based JSON | Yes | Yes | Yes |

**Claude Code is the only CLI with built-in JSON schema enforcement.** For Codex and Gemini, include the desired JSON format in your prompt and validate the response yourself.

## Validation Pattern (Any CLI)

```bash
#!/usr/bin/env bash
# Validate JSON response regardless of CLI

RESULT=$(your_cli_command_here)

# Check if it's valid JSON
if echo "$RESULT" | jq '.' >/dev/null 2>&1; then
  echo "Valid JSON"
  echo "$RESULT" | jq '.'
else
  echo "Not valid JSON — raw response:"
  echo "$RESULT"
fi
```

## Python Normalization

```python
import subprocess
import json
from enum import Enum

class CLI(Enum):
    CLAUDE = "claude"
    CODEX = "codex"
    GEMINI = "gemini"

def run_prompt(prompt: str, cli: CLI = CLI.CLAUDE, input_file: str = None) -> str:
    """Run a prompt on any CLI and return the text response."""
    if cli == CLI.CLAUDE:
        cmd = ["claude", "-p", prompt, "--output-format", "json", "--no-session-persistence"]
        if input_file:
            with open(input_file) as f:
                result = subprocess.run(cmd, stdin=f, capture_output=True, text=True)
        else:
            result = subprocess.run(cmd, capture_output=True, text=True)
        return json.loads(result.stdout).get("result", "")

    elif cli == CLI.CODEX:
        cmd = ["codex", "exec", prompt, "--ephemeral"]
        if input_file:
            cmd = ["codex", "exec", "-", prompt, "--ephemeral"]
            with open(input_file) as f:
                result = subprocess.run(cmd, stdin=f, capture_output=True, text=True)
        else:
            result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip()

    elif cli == CLI.GEMINI:
        cmd = ["gemini", "-p", prompt, "-m", "gemini-2-5-flash"]
        if input_file:
            with open(input_file) as f:
                result = subprocess.run(cmd, stdin=f, capture_output=True, text=True)
        else:
            result = subprocess.run(cmd, capture_output=True, text=True)
        return result.stdout.strip()

# Usage
response = run_prompt("Summarize this code", CLI.GEMINI, "main.py")
```
