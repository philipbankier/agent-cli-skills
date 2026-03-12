# Gemini CLI JSON Output

Output shapes for `--output-format json` and `--output-format jsonl`.

## --output-format json

Returns a single JSON object containing the response, statistics, and any errors:

```json
{
  "response": "The model's text response here",
  "statistics": {
    "model_requests": 1,
    "input_tokens": 450,
    "output_tokens": 120,
    "total_tokens": 570
  },
  "error": null
}
```

### Usage

```bash
# Get JSON response
gemini -p "Summarize this project" --output-format json | jq '.'

# Extract just the response text
gemini -p "Explain this code" --output-format json | jq -r '.response'

# Get token usage
gemini -p "Analyze main.py" --output-format json | jq '.statistics'
```

### Error Shape

When an error occurs:

```json
{
  "response": null,
  "statistics": {},
  "error": {
    "message": "Rate limit exceeded",
    "code": "RATE_LIMIT_ERROR"
  }
}
```

## --output-format jsonl

Streaming JSONL (newline-delimited JSON). Each line is a self-contained event:

### Event Types

**Session metadata:**
```json
{"type": "session_start", "session_id": "abc123", "model": "gemini-2-5-pro"}
```

**Message chunks (streaming content):**
```json
{"type": "content_chunk", "content": "Here is the ", "index": 0}
{"type": "content_chunk", "content": "analysis of ", "index": 1}
{"type": "content_chunk", "content": "your code.", "index": 2}
```

**Tool calls:**
```json
{"type": "tool_call", "name": "read_file", "arguments": {"path": "src/main.ts"}}
```

**Tool results:**
```json
{"type": "tool_result", "name": "read_file", "content": "file contents here"}
```

**Aggregated statistics:**
```json
{"type": "statistics", "model_requests": 3, "input_tokens": 2000, "output_tokens": 500}
```

### Parsing JSONL

```bash
# Stream and display content chunks
gemini -p "Explain the architecture" --output-format jsonl | \
  while IFS= read -r line; do
    content=$(echo "$line" | jq -r 'select(.type == "content_chunk") | .content // empty')
    [ -n "$content" ] && echo -n "$content"
  done
echo ""

# Count tool calls
gemini -p "Analyze the codebase" --output-format jsonl -y | \
  jq -r 'select(.type == "tool_call") | .name' | sort | uniq -c

# Extract statistics
gemini -p "Review this code" --output-format jsonl | \
  jq 'select(.type == "statistics")'
```

## Parsing Patterns

### Python

```python
import subprocess
import json

def gemini_run(prompt: str, json_output: bool = True) -> dict | str:
    """Run Gemini CLI and return parsed response."""
    cmd = ["gemini", "-p", prompt]
    if json_output:
        cmd.extend(["--output-format", "json"])

    result = subprocess.run(cmd, capture_output=True, text=True)

    if result.returncode != 0:
        raise RuntimeError(f"Gemini failed (exit {result.returncode}): {result.stderr}")

    if json_output:
        return json.loads(result.stdout)
    return result.stdout.strip()

# Usage
response = gemini_run("Summarize this project")
print(response["response"])
print(f"Tokens used: {response['statistics']['total_tokens']}")
```

### Node.js

```javascript
const { execFileSync } = require('child_process');

function geminiRun(prompt, options = {}) {
  const args = ['-p', prompt];
  if (options.json) args.push('--output-format', 'json');
  if (options.model) args.push('-m', options.model);

  const result = execFileSync('gemini', args, {
    encoding: 'utf-8',
    timeout: 120000,
  });

  return options.json ? JSON.parse(result) : result.trim();
}

// Usage
const response = geminiRun('Explain the codebase', { json: true, model: 'gemini-2-5-flash' });
console.log(response.response);
console.log(`Tokens: ${response.statistics.total_tokens}`);
```

## JSON vs JSONL: When to Use Which

| Use Case | Format | Why |
|---|---|---|
| Simple scripting | `json` | Single object, easy to parse |
| Real-time streaming | `jsonl` | See progress as it happens |
| Token monitoring | `json` | Statistics in final object |
| Tool call tracking | `jsonl` | See each tool call as it happens |
| CI/CD pipelines | `json` | Deterministic single output |
