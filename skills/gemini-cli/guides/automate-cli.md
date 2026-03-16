# Automating with Gemini CLI

End-to-end guide for using Gemini CLI in scripts, CI/CD pipelines, and batch processing.

## Basic Non-Interactive Usage

```bash
# Using the -p flag
gemini -p "Explain what this project does"

# Piping input with -p (recommended for non-interactive)
echo "Explain this code" | gemini -p "Answer based on the piped input"

# Piping file content
cat main.py | gemini -p "List all function names in this file"

# Auto-approve all actions (yolo mode)
gemini -p "Fix the linting errors in src/" -y  # or --yolo

# Granular approval modes: default, auto_edit, yolo, plan (read-only)
gemini -p "Read the codebase and explain the architecture" --approval-mode plan
```

## Model Selection

```bash
# Default: Gemini 2.5 Pro (largest context window)
gemini -p "Analyze this codebase"

# Fast model for quick tasks
gemini -p "What language is this?" -m gemini-2-5-flash

# Best reasoning model
gemini -p "Design an authentication system" -m gemini-3-pro-preview

# Auto-select best model
gemini -p "Complex task here" -m auto-gemini-3
```

## Output Capture

### Plain Text (Default)

```bash
# Capture to variable
result=$(gemini -p "Summarize this project")
echo "$result"

# Capture to file
gemini -p "Generate a project summary" > summary.txt
```

### JSON Output

```bash
# Structured JSON with response + statistics
gemini -p "List all TODO comments" --output-format json | jq '.'

# Extract just the response
gemini -p "Explain this code" --output-format json | jq -r '.response'
```

### Streaming JSON

```bash
# Streaming JSON events
gemini -p "Explain this step by step" --output-format stream-json

# Parse streaming events
gemini -p "Analyze the architecture" --output-format stream-json | \
  while IFS= read -r line; do
    type=$(echo "$line" | jq -r '.type // empty')
    [ -n "$type" ] && echo "Event: $type"
  done
```

## Free Tier Batch Processing

Gemini's free tier (1000 requests/day) makes it ideal for high-volume batch processing.

### Rate-Limited Batch Processing

```bash
#!/usr/bin/env bash
# batch-analyze.sh — Process files within free tier limits

PATTERN="${1:?Usage: batch-analyze.sh <glob-pattern>}"
OUTDIR="/tmp/gemini-batch-$(date +%s)"
mkdir -p "$OUTDIR"
COUNT=0
MAX_PER_MINUTE=50  # Stay under 60/min limit

for f in $PATTERN; do
  name=$(basename "$f" | sed 's/[^a-zA-Z0-9]/-/g')
  echo "[$COUNT] Processing $f..."

  gemini -p "Analyze this file for code quality issues" \
    -m gemini-2-5-flash \
    < "$f" > "$OUTDIR/$name.txt" &

  COUNT=$((COUNT + 1))

  # Rate limiting: pause every batch
  if [ $((COUNT % MAX_PER_MINUTE)) -eq 0 ]; then
    echo "Rate limit pause (${MAX_PER_MINUTE} files processed)..."
    wait
    sleep 2
  fi
done

wait
echo "Done! Processed $COUNT files."
echo "Results in $OUTDIR/"
```

### Parallel Execution

```bash
# Run multiple analyses in parallel (watch rate limits)
gemini -p "Check auth.ts for security issues" -m gemini-2-5-flash > /tmp/auth-review.txt &
gemini -p "Check api.ts for performance issues" -m gemini-2-5-flash > /tmp/api-review.txt &
gemini -p "Check db.ts for SQL injection" -m gemini-2-5-flash > /tmp/db-review.txt &
wait

cat /tmp/*-review.txt > full-review.txt
```

## Large Context Analysis

Gemini 2.5 Pro's 1M token context window enables unique workflows:

```bash
# Analyze an entire codebase at once
find src -name "*.ts" -exec cat {} + | \
  gemini -p "Analyze this entire codebase. Identify:
1. Architectural patterns used
2. Potential security vulnerabilities
3. Code duplication across files
4. Suggested improvements"

# Compare two large files
paste <(cat old-version.ts) <(cat new-version.ts) | \
  gemini -p "Compare these two versions of the file. What changed and why?"
```

## CI/CD Integration

### GitHub Actions

```yaml
name: AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Gemini CLI
        run: npm install -g @google/gemini-cli

      - name: Review PR
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: |
          git diff ${{ github.event.pull_request.base.sha }} HEAD > pr.diff
          cat pr.diff | gemini -p \
            "Review this diff for bugs and security issues. Be concise." \
            -m gemini-2-5-flash \
            > review.md

      - name: Post Review Comment
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: `## AI Code Review (Gemini)\n\n${review}`
            });
```

### GitLab CI

```yaml
ai-review:
  stage: review
  image: node:20
  before_script:
    - npm install -g @google/gemini-cli
  script:
    - git diff $CI_MERGE_REQUEST_DIFF_BASE_SHA HEAD | gemini -p "Review this diff" -m gemini-2-5-flash > review.md
  artifacts:
    paths:
      - review.md
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

## Error Handling

```bash
# Check exit codes
if ! result=$(gemini -p "Analyze this code" 2>/dev/null); then
  echo "Gemini call failed" >&2
  exit 1
fi

# Handle specific exit codes
gemini -p "complex task" -y
case $? in
  0)  echo "Success" ;;
  1)  echo "General error" >&2 ;;
  42) echo "Input error (bad prompt)" >&2 ;;
  53) echo "Turn limit exceeded" >&2 ;;
esac
```

## Tips

- **Use `-m gemini-2-5-flash` for batch processing** — Faster, cheaper, stays within rate limits
- **Leverage the 1M context window** — Gemini can analyze entire codebases in a single call
- **Watch your request count, not prompt count** — Complex prompts use multiple requests
- **Use Google Account auth for free tier** — API key auth limits you to Flash models only
- **Add `sleep 1` between calls in loops** — Respect the 60 requests/minute rate limit
