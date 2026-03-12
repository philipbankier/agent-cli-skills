# Codex CLI JSON Output

Output shapes for `--json` and `--experimental-json` flags.

## --json Flag

The `--json` flag produces newline-delimited JSON events on stdout. Each line is a self-contained JSON object.

### Event Types

Events include session metadata, message chunks, tool calls, and results. The exact shape depends on the Codex CLI version.

### Basic Usage

```bash
# Capture JSON output
codex exec "Analyze this code" --json > output.jsonl

# Parse with jq
codex exec "List TODO items" --json | jq 'select(.type == "message")'
```

## --experimental-json Flag

Richer event stream with more granular data. **This flag is unstable** — the output format may change between versions.

### Usage

```bash
codex exec "Review code quality" --experimental-json > events.jsonl
```

### Caveats

- Output shape is not guaranteed stable across versions
- Pin your Codex CLI version if you parse this in production
- May include internal events not present in `--json`

## Output to File (-o)

The `-o` flag writes the assistant's **final message only** (not the full event stream) to a file:

```bash
codex exec "Write a summary" -o summary.txt

# The file contains plain text, not JSON
cat summary.txt
```

### Combining -o with --json

```bash
# JSON events go to stdout, final message goes to file
codex exec "Analyze code" --json -o analysis.txt > events.jsonl

# events.jsonl has the full JSON stream
# analysis.txt has just the final assistant message
```

## Parsing Patterns

### Extract Final Result (Bash)

```bash
# Using -o (simplest)
codex exec "What is 2+2?" -o /tmp/result.txt --ephemeral
cat /tmp/result.txt

# Using --json + jq (more control)
codex exec "What is 2+2?" --json --ephemeral | \
  jq -r 'select(.type == "message") | .content' | tail -1
```

### Process JSON Events (Python)

```python
import subprocess
import json

proc = subprocess.run(
    ["codex", "exec", "List all files", "--json", "--ephemeral"],
    capture_output=True, text=True
)

for line in proc.stdout.strip().split('\n'):
    if line:
        event = json.loads(line)
        print(f"Event type: {event.get('type')}")
```

### Process JSON Events (Node.js)

```javascript
const { execFileSync } = require('child_process');

const output = execFileSync(
  'codex',
  ['exec', 'List all files', '--json', '--ephemeral'],
  { encoding: 'utf-8' }
);

const events = output.trim().split('\n')
  .filter(Boolean)
  .map(line => JSON.parse(line));

console.log(`Got ${events.length} events`);
```
