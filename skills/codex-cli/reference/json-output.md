# Codex CLI JSON Output

Output shapes for the `--json` flag.
Last verified against **Codex CLI v0.130.0** on 2026-05-17.

## --json Flag

The `--json` flag produces JSONL (newline-delimited JSON) events on stdout. Each line is a self-contained JSON object with a `type` field.

### Event Types

The happy-path `--json` flag emits these event types in order:

1. **`thread.started`** — Emitted when the session begins
2. **`turn.started`** — Emitted when a new turn begins
3. **`item.completed`** — Emitted for each completed item
4. **`turn.completed`** — Emitted when the turn finishes, including token usage

Other event types can appear on failures or tool work. Treat unknown event types
as forward-compatible additions.

### Event Shapes

```jsonl
{"type": "thread.started", "thread_id": "..."}
{"type": "turn.started"}
{"type": "item.completed", "item": {"id": "item_0", "type": "agent_message", "text": "..."}}
{"type": "turn.completed", "usage": {"input_tokens": 23629, "cached_input_tokens": 3456, "output_tokens": 25, "reasoning_output_tokens": 23}}
```

### Basic Usage

```bash
# Capture JSONL output
codex exec "Analyze this code" --json > output.jsonl

# Extract message text with jq
codex exec "List TODO items" --json | \
  jq -r 'select(.type == "item.completed") | .item | select(.type == "agent_message") | .text'
```

## Output to File (-o)

The `-o` flag writes the assistant's **final message only** (not the full event stream) to a file:

```bash
codex exec "Write a summary" -o summary.txt

# The file contains plain text, not JSON
cat summary.txt
```

In v0.130, `-o` writes the final message to the file and still prints the final
message to stdout when `--json` is not enabled.

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
  jq -r 'select(.type == "item.completed") | .item | select(.type == "agent_message") | .text'
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
            if item.get('type') == 'agent_message':
                print(f"  Text: {item.get('text', '')}")
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
  .filter(e => e.type === 'item.completed' && e.item?.type === 'agent_message')
  .map(e => e.item.text);

console.log(`Got ${events.length} events, ${messages.length} messages`);
```

## Structured Final Output

`--output-schema <file>` constrains the final assistant message to a JSON Schema.
Local v0.130 smoke test:

```bash
cat > schema.json <<'JSON'
{
  "type": "object",
  "properties": {
    "status": { "type": "string" },
    "count": { "type": "integer" }
  },
  "required": ["status", "count"],
  "additionalProperties": false
}
JSON

codex exec "Return JSON with status ok and count 3." \
  --ephemeral \
  --sandbox read-only \
  --output-schema schema.json \
  -o result.json
```

Observed `result.json`:

```json
{"status":"ok","count":3}
```
