# Codex CLI JSON Output

Output shapes for the `--json` flag.

## --json Flag

The `--json` flag produces JSONL (newline-delimited JSON) events on stdout. Each line is a self-contained JSON object with a `type` field.

### Event Types

The `--json` flag emits four event types in order:

1. **`thread.started`** — Emitted when the session begins
2. **`turn.started`** — Emitted when a new turn begins
3. **`item.completed`** — Emitted for each completed item (message, tool call, etc.)
4. **`turn.completed`** — Emitted when the turn finishes

### Event Shapes

```jsonl
{"type": "thread.started", "thread_id": "..."}
{"type": "turn.started", "turn_id": "..."}
{"type": "item.completed", "item": {"type": "message", "content": [{"type": "text", "text": "..."}]}}
{"type": "item.completed", "item": {"type": "tool_call", "name": "...", "arguments": "..."}}
{"type": "turn.completed", "turn_id": "..."}
```

### Basic Usage

```bash
# Capture JSONL output
codex exec "Analyze this code" --json > output.jsonl

# Extract message text with jq
codex exec "List TODO items" --json | \
  jq -r 'select(.type == "item.completed") | .item | select(.type == "message") | .content[].text'
```

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
  jq -r 'select(.type == "item.completed") | .item | select(.type == "message") | .content[].text'
```

### Process JSONL Events (Python)

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
        if event.get('type') == 'item.completed':
            item = event.get('item', {})
            if item.get('type') == 'message':
                for content in item.get('content', []):
                    print(f"  Text: {content.get('text', '')}")
```

### Process JSONL Events (Node.js)

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

const messages = events
  .filter(e => e.type === 'item.completed' && e.item?.type === 'message')
  .flatMap(e => e.item.content.map(c => c.text));

console.log(`Got ${events.length} events, ${messages.length} messages`);
```
