# Automating with Codex CLI

End-to-end guide for using `codex exec` in scripts, CI/CD pipelines, and batch processing.

## Basic Non-Interactive Usage

```bash
# Simple one-shot call
codex exec "Explain what this project does"

# Shorthand
codex e "Explain what this project does"

# Pipe content from stdin
cat README.md | codex exec - "Summarize this document"

# With auto-approval for write operations
codex exec "Fix the linting errors in src/" --full-auto
```

## Output Capture

### Plain Text (Default)

```bash
# Capture to variable
result=$(codex exec "What language is this project written in?")
echo "$result"

# Capture to file via redirect
codex exec "Generate a project summary" > summary.txt
```

### JSON Output

```bash
# Structured JSONL for programmatic parsing
# Events: thread.started, turn.started, item.completed, turn.completed
codex exec "List all TODO comments in the codebase" --json | jq '.'
```

### Output to File

```bash
# Save the assistant's final message to a file
codex exec "Write a changelog entry for the latest changes" -o CHANGELOG_ENTRY.md

# Combine with JSON for both structured and file output
codex exec "Review this code" --json -o review.md
```

## Approval and Safety Modes

### Read-Only (Safest)

```bash
# Can read code but cannot modify anything
codex exec "Explain the authentication flow" -s read-only
```

### Workspace Write (Default)

```bash
# Can read and write within the project directory
codex exec "Add error handling to api.ts" -s workspace-write
```

### Full Auto

```bash
# Preset for automation: workspace-write sandbox + on-request approvals
codex exec "Refactor the database module" --full-auto
```

### Full Autonomy (Dangerous)

```bash
# No approvals, no sandbox — only use in isolated/CI environments
codex exec "Fix all failing tests and commit the fixes" \
  --full-auto --dangerously-bypass-approvals-and-sandbox
```

## Batch Processing

### Process Multiple Files

```bash
# Analyze each file independently (stateless)
for f in src/*.ts; do
  echo "=== $f ==="
  codex exec "Review this file for common issues" --ephemeral < "$f"
  echo ""
done
```

### Parallel Execution

```bash
# Run multiple analyses in parallel
codex exec "Check auth.ts for security issues" --ephemeral -o /tmp/auth-review.txt &
codex exec "Check api.ts for performance issues" --ephemeral -o /tmp/api-review.txt &
codex exec "Check db.ts for SQL injection" --ephemeral -o /tmp/db-review.txt &
wait

# Aggregate results
cat /tmp/*-review.txt > full-review.txt
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

      - name: Install Codex CLI
        run: npm install -g @openai/codex

      - name: Review PR
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          git diff ${{ github.event.pull_request.base.sha }} HEAD > pr.diff
          codex exec "Review this diff for bugs and security issues. Be concise." \
            --json \
            --ephemeral \
            -o review.md \
            < pr.diff

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
              body: `## AI Code Review\n\n${review}`
            });
```

### GitLab CI

```yaml
ai-review:
  stage: review
  image: node:20
  before_script:
    - npm install -g @openai/codex
  script:
    - git diff $CI_MERGE_REQUEST_DIFF_BASE_SHA HEAD > mr.diff
    - codex exec "Review this diff" --ephemeral -o review.md < mr.diff
  artifacts:
    paths:
      - review.md
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

## Configuration Overrides

```bash
# Override global config for a single run
codex exec -c model=gpt-4.1 "Use GPT-4.1 for this task"

# Combine with other flags
codex exec -c model=o4-mini --full-auto --ephemeral "Quick analysis"
```

## Error Handling

```bash
# Check exit code
if ! result=$(codex exec "Analyze this code" --ephemeral 2>/dev/null); then
  echo "Codex exec failed" >&2
  exit 1
fi

# Timeout long-running tasks
timeout 120 codex exec "Review the entire codebase" --ephemeral || {
  echo "Timed out after 120 seconds" >&2
  exit 1
}
```

## Tips

- **Always use `--ephemeral` for stateless automation** — prevents session files from accumulating
- **Use `-o` for downstream processing** — cleaner than parsing stdout
- **Prefer API key auth for CI/CD** — `OPENAI_API_KEY` is more reliable than device-code login in automated environments
- **Pin your Codex CLI version** — `npm install -g @openai/codex@0.20` prevents breaking changes in CI
