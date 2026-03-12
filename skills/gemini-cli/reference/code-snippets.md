# Gemini CLI Code Snippets

Copy-paste patterns for common Gemini CLI automation scenarios.

## Bash

### One-Shot Query

```bash
gemini -p "Explain what this project does"
```

### Structured Analysis with JSON

```bash
# Get JSON response with statistics
result=$(gemini -p "List all API endpoints in this codebase" --output-format json)
echo "$result" | jq -r '.response'
echo "Tokens used: $(echo "$result" | jq '.statistics.total_tokens')"
```

### Batch File Processing (Free Tier Friendly)

```bash
#!/usr/bin/env bash
# batch-analyze.sh — Process files within free tier rate limits

OUTDIR="/tmp/gemini-batch-$(date +%s)"
mkdir -p "$OUTDIR"
COUNT=0

for f in src/*.py; do
  name=$(basename "$f" | sed 's/[^a-zA-Z0-9]/-/g')
  echo "[$COUNT] $f..."

  gemini -p "Summarize this file's purpose and list its functions" \
    -m gemini-2-5-flash \
    < "$f" > "$OUTDIR/$name.txt"

  COUNT=$((COUNT + 1))
  # Rate limit: stay under 60/min
  sleep 1
done

echo "Processed $COUNT files → $OUTDIR/"
```

### Parallel Execution

```bash
# Run 5 analyses in parallel
for topic in "auth" "api" "database" "frontend" "tests"; do
  gemini -p "Analyze the $topic layer of this codebase" \
    -m gemini-2-5-flash \
    > "/tmp/analysis-$topic.txt" &
done
wait

# Combine results
for f in /tmp/analysis-*.txt; do
  echo "=== $(basename "$f" .txt) ==="
  cat "$f"
  echo ""
done
```

### Large Context Analysis

```bash
# Feed an entire codebase to Gemini's 1M token context
find src -name "*.ts" -exec cat {} + | \
  gemini -p "Analyze the architecture, identify patterns, and suggest improvements"
```

### Error Handling

```bash
#!/usr/bin/env bash
set -euo pipefail

gemini -p "Analyze this code" -m gemini-2-5-flash
case $? in
  0)  echo "Success" ;;
  1)  echo "Error: API failure" >&2; exit 1 ;;
  42) echo "Error: Bad input" >&2; exit 1 ;;
  53) echo "Error: Turn limit" >&2; exit 1 ;;
esac
```

## Python

### Basic Subprocess

```python
import subprocess
import json
import sys

def gemini_run(prompt: str, model: str = "gemini-2-5-flash") -> str:
    """Run Gemini CLI and return the text response."""
    result = subprocess.run(
        ["gemini", "-p", prompt, "-m", model],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        print(f"Gemini error (exit {result.returncode}): {result.stderr}", file=sys.stderr)
        raise RuntimeError(f"gemini failed: {result.returncode}")

    return result.stdout.strip()

# Usage
summary = gemini_run("Summarize this project in one paragraph")
print(summary)
```

### JSON Response with Statistics

```python
import subprocess
import json

def gemini_run_json(prompt: str, model: str = "gemini-2-5-flash") -> dict:
    """Run Gemini CLI with JSON output and return parsed response."""
    result = subprocess.run(
        ["gemini", "-p", prompt, "-m", model, "--output-format", "json"],
        capture_output=True, text=True
    )

    if result.returncode != 0:
        raise RuntimeError(f"gemini failed: {result.stderr}")

    return json.loads(result.stdout)

# Usage
response = gemini_run_json("Analyze this codebase for security issues")
print(response["response"])
print(f"Tokens: {response['statistics']['total_tokens']}")
print(f"Model requests: {response['statistics']['model_requests']}")
```

### Rate-Limited Batch Processing

```python
import subprocess
import time
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

def analyze_file(filepath: Path) -> tuple[str, str]:
    """Analyze a file with Gemini (rate-limit friendly)."""
    content = filepath.read_text()
    result = subprocess.run(
        ["gemini", "-p", "Summarize this file's purpose", "-m", "gemini-2-5-flash"],
        input=content, capture_output=True, text=True
    )
    return str(filepath), result.stdout.strip()

# Process files with rate limiting
files = list(Path("src").glob("**/*.py"))
results = {}

# Sequential with rate limiting (safe for free tier)
for i, f in enumerate(files):
    filepath, analysis = analyze_file(f)
    results[filepath] = analysis
    print(f"[{i+1}/{len(files)}] {filepath}")

    if (i + 1) % 50 == 0:
        print("Rate limit pause...")
        time.sleep(5)
    else:
        time.sleep(1)

# Print results
for path, analysis in results.items():
    print(f"\n=== {path} ===")
    print(analysis)
```

## JavaScript / Node.js

### Basic Execution

```javascript
const { execFileSync } = require('child_process');

function geminiRun(prompt, options = {}) {
  const args = ['-p', prompt];
  if (options.model) args.push('-m', options.model);
  if (options.json) args.push('--output-format', 'json');

  const result = execFileSync('gemini', args, {
    encoding: 'utf-8',
    timeout: 120000,
  });

  return options.json ? JSON.parse(result) : result.trim();
}

// Usage
const summary = geminiRun('Explain the project', { model: 'gemini-2-5-flash' });
console.log(summary);
```

### With Token Tracking

```javascript
const { execFileSync } = require('child_process');

function geminiRunTracked(prompt) {
  const result = execFileSync(
    'gemini',
    ['-p', prompt, '-m', 'gemini-2-5-flash', '--output-format', 'json'],
    { encoding: 'utf-8', timeout: 120000 }
  );

  const parsed = JSON.parse(result);
  console.log(`Tokens: ${parsed.statistics.total_tokens} | Requests: ${parsed.statistics.model_requests}`);
  return parsed.response;
}

// Usage
const analysis = geminiRunTracked('Analyze main.ts for issues');
console.log(analysis);
```

## CI/CD Patterns

### GitHub Actions — PR Review

```yaml
- name: AI Code Review (Gemini)
  env:
    GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
  run: |
    npm install -g @google/gemini-cli
    git diff ${{ github.event.pull_request.base.sha }} HEAD | \
      gemini -p "Review this diff for bugs and security issues" \
        -m gemini-2-5-flash > review.md
```

### Pre-Commit Hook

```bash
#!/usr/bin/env bash
# .git/hooks/pre-commit

DIFF=$(git diff --cached)
if [ -z "$DIFF" ]; then exit 0; fi

echo "Running AI pre-commit review (Gemini)..."
echo "$DIFF" | gemini -p \
  "Review this diff. List critical issues or say LGTM." \
  -m gemini-2-5-flash
```
