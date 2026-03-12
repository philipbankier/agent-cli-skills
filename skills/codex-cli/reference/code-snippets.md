# Codex CLI Code Snippets

Copy-paste patterns for common Codex CLI automation scenarios.

## Bash

### One-Shot Query

```bash
codex exec "Explain what this project does" --ephemeral
```

### Structured Analysis

```bash
# Analyze and save result
codex exec "List all API endpoints in this codebase, one per line" \
  --ephemeral \
  -o /tmp/endpoints.txt

# Process the result
while IFS= read -r endpoint; do
  echo "Found endpoint: $endpoint"
done < /tmp/endpoints.txt
```

### Batch File Processing

```bash
#!/usr/bin/env bash
# process-files.sh — Run Codex on every file matching a pattern

PATTERN="${1:?Usage: process-files.sh <glob-pattern> <prompt>}"
PROMPT="${2:?Usage: process-files.sh <glob-pattern> <prompt>}"
OUTDIR="/tmp/codex-batch-$(date +%s)"
mkdir -p "$OUTDIR"

for f in $PATTERN; do
  name=$(basename "$f" | sed 's/[^a-zA-Z0-9]/-/g')
  echo "Processing $f..."
  cat "$f" | codex exec - "$PROMPT" \
    --ephemeral \
    -o "$OUTDIR/$name.txt" &
done
wait

echo "Results in $OUTDIR/"
ls "$OUTDIR/"
```

### Multi-Step with Session Resume

```bash
#!/usr/bin/env bash
# iterative-review.sh — Analyze, then fix, then verify

codex exec "Read the codebase and identify the top 3 bugs"
codex exec resume --last "Fix the highest-priority bug you found" --full-auto
codex exec resume --last "Verify the fix doesn't break any existing tests" -o review.md
echo "Review saved to review.md"
```

### Error Handling

```bash
#!/usr/bin/env bash
set -euo pipefail

if ! result=$(codex exec "Analyze this code for issues" --ephemeral 2>&1); then
  echo "Error: $result" >&2
  exit 1
fi

echo "$result"
```

## Python

### Subprocess Call

```python
import subprocess
import sys

def codex_run(prompt: str, ephemeral: bool = True) -> str:
    """Run a Codex CLI prompt and return the result."""
    cmd = ["codex", "exec", prompt]
    if ephemeral:
        cmd.append("--ephemeral")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Codex error: {result.stderr}", file=sys.stderr)
        raise RuntimeError(f"codex exec failed: {result.returncode}")

    return result.stdout.strip()

# Usage
summary = codex_run("Summarize this project in one paragraph")
print(summary)
```

### JSON Event Processing

```python
import subprocess
import json

def codex_run_json(prompt: str) -> list[dict]:
    """Run Codex with --json and return parsed events."""
    result = subprocess.run(
        ["codex", "exec", prompt, "--json", "--ephemeral"],
        capture_output=True, text=True
    )

    events = []
    for line in result.stdout.strip().split('\n'):
        if line:
            events.append(json.loads(line))
    return events

events = codex_run_json("List all functions in main.py")
for event in events:
    print(f"{event.get('type')}: {json.dumps(event)[:100]}")
```

### Batch Processing

```python
import subprocess
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path

def analyze_file(filepath: Path, prompt: str) -> tuple[str, str]:
    """Analyze a single file with Codex."""
    content = filepath.read_text()
    result = subprocess.run(
        ["codex", "exec", "-", prompt, "--ephemeral"],
        input=content, capture_output=True, text=True
    )
    return str(filepath), result.stdout.strip()

# Analyze all Python files in parallel
files = list(Path("src").glob("**/*.py"))
prompt = "List all functions and their docstrings in this file"

with ThreadPoolExecutor(max_workers=5) as executor:
    futures = {
        executor.submit(analyze_file, f, prompt): f
        for f in files
    }

    for future in as_completed(futures):
        filepath, analysis = future.result()
        print(f"\n=== {filepath} ===")
        print(analysis)
```

## JavaScript / Node.js

### Basic Execution

```javascript
const { execFileSync } = require('child_process');

function codexRun(prompt, options = {}) {
  const args = ['exec', prompt, '--ephemeral'];
  if (options.json) args.push('--json');

  const result = execFileSync('codex', args, {
    encoding: 'utf-8',
    timeout: 120000,
  });

  return options.json
    ? result.trim().split('\n').filter(Boolean).map(JSON.parse)
    : result.trim();
}

// Usage
const summary = codexRun('Explain the project structure');
console.log(summary);
```

### Async Execution

```javascript
const { execFile } = require('child_process');
const { promisify } = require('util');
const execFileAsync = promisify(execFile);

async function codexRunAsync(prompt) {
  const { stdout, stderr } = await execFileAsync(
    'codex',
    ['exec', prompt, '--ephemeral'],
    { timeout: 120000 }
  );

  if (stderr) console.error('Codex stderr:', stderr);
  return stdout.trim();
}

// Usage
(async () => {
  const result = await codexRunAsync('List all TODO comments');
  console.log(result);
})();
```

## CI/CD Patterns

### GitHub Actions — PR Review

```yaml
- name: AI Code Review
  env:
    OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
  run: |
    npm install -g @openai/codex
    git diff ${{ github.event.pull_request.base.sha }} HEAD | \
      codex exec - "Review this diff for bugs" --ephemeral -o review.md
```

### Pre-Commit Hook

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit — AI review of staged changes

DIFF=$(git diff --cached)
if [ -z "$DIFF" ]; then exit 0; fi

echo "Running AI pre-commit review..."
echo "$DIFF" | codex exec - \
  "Review this diff. If there are critical issues, list them. If it looks good, say LGTM." \
  --ephemeral
```
