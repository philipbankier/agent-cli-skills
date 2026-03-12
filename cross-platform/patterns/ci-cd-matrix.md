# CI/CD Templates for CLI Agents

GitHub Actions and GitLab CI templates for Claude Code, Codex CLI, and Gemini CLI.

## GitHub Actions

### Claude Code

```yaml
name: AI Code Review (Claude)
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Claude Code
        run: npm install -g @anthropic-ai/claude-code

      - name: Review PR
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          git diff ${{ github.event.pull_request.base.sha }} HEAD > pr.diff
          claude -p "Review this diff for bugs and security issues. Be concise." \
            --output-format json \
            --no-session-persistence \
            < pr.diff | jq -r '.result' > review.md

      - name: Post Comment
        if: success()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            if (review.trim()) {
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: `## AI Code Review (Claude)\n\n${review}`
              });
            }
```

### Codex CLI

```yaml
name: AI Code Review (Codex)
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Codex CLI
        run: npm install -g @openai/codex

      - name: Review PR
        env:
          OPENAI_API_KEY: ${{ secrets.OPENAI_API_KEY }}
        run: |
          git diff ${{ github.event.pull_request.base.sha }} HEAD | \
            codex exec - "Review this diff for bugs and security issues. Be concise." \
              --ephemeral \
              -o review.md

      - name: Post Comment
        if: success()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            if (review.trim()) {
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: `## AI Code Review (Codex)\n\n${review}`
              });
            }
```

### Gemini CLI

```yaml
name: AI Code Review (Gemini)
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Install Gemini CLI
        run: npm install -g @google/gemini-cli

      - name: Review PR
        env:
          GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
        run: |
          git diff ${{ github.event.pull_request.base.sha }} HEAD | \
            gemini -p "Review this diff for bugs and security issues. Be concise." \
              -m gemini-2-5-flash \
              > review.md

      - name: Post Comment
        if: success()
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const review = fs.readFileSync('review.md', 'utf8');
            if (review.trim()) {
              github.rest.issues.createComment({
                issue_number: context.issue.number,
                owner: context.repo.owner,
                repo: context.repo.repo,
                body: `## AI Code Review (Gemini)\n\n${review}`
              });
            }
```

## GitLab CI

### All Three CLIs

```yaml
stages:
  - review

.ai-review-base:
  stage: review
  image: node:20
  artifacts:
    paths:
      - review.md
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"

ai-review-claude:
  extends: .ai-review-base
  before_script:
    - npm install -g @anthropic-ai/claude-code
  script:
    - git diff $CI_MERGE_REQUEST_DIFF_BASE_SHA HEAD > mr.diff
    - claude -p "Review this diff" --output-format json --no-session-persistence < mr.diff | jq -r '.result' > review.md
  variables:
    ANTHROPIC_API_KEY: $ANTHROPIC_API_KEY

ai-review-codex:
  extends: .ai-review-base
  before_script:
    - npm install -g @openai/codex
  script:
    - git diff $CI_MERGE_REQUEST_DIFF_BASE_SHA HEAD | codex exec - "Review this diff" --ephemeral -o review.md
  variables:
    OPENAI_API_KEY: $OPENAI_API_KEY

ai-review-gemini:
  extends: .ai-review-base
  before_script:
    - npm install -g @google/gemini-cli
  script:
    - git diff $CI_MERGE_REQUEST_DIFF_BASE_SHA HEAD | gemini -p "Review this diff" -m gemini-2-5-flash > review.md
  variables:
    GEMINI_API_KEY: $GEMINI_API_KEY
```

## Multi-CLI Review (Run All Three)

Use all three CLIs for diverse perspectives:

```yaml
name: Multi-AI Code Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        cli:
          - name: claude
            install: npm install -g @anthropic-ai/claude-code
            key_var: ANTHROPIC_API_KEY
            cmd: "claude -p 'Review this diff' --output-format json --no-session-persistence < pr.diff | jq -r '.result'"
          - name: codex
            install: npm install -g @openai/codex
            key_var: OPENAI_API_KEY
            cmd: "cat pr.diff | codex exec - 'Review this diff' --ephemeral"
          - name: gemini
            install: npm install -g @google/gemini-cli
            key_var: GEMINI_API_KEY
            cmd: "cat pr.diff | gemini -p 'Review this diff' -m gemini-2-5-flash"

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup
        run: |
          ${{ matrix.cli.install }}
          git diff ${{ github.event.pull_request.base.sha }} HEAD > pr.diff

      - name: Review
        env:
          ${{ matrix.cli.key_var }}: ${{ secrets[matrix.cli.key_var] }}
        run: eval "${{ matrix.cli.cmd }}" > review-${{ matrix.cli.name }}.md

      - uses: actions/upload-artifact@v4
        with:
          name: review-${{ matrix.cli.name }}
          path: review-${{ matrix.cli.name }}.md
```

## Setup Checklist

| Step | Claude Code | Codex CLI | Gemini CLI |
|------|------------|-----------|------------|
| Get API key | [Anthropic Console](https://console.anthropic.com/) | [OpenAI Platform](https://platform.openai.com/api-keys) | [Google AI Studio](https://aistudio.google.com/apikey) |
| Add to CI secrets | `ANTHROPIC_API_KEY` | `OPENAI_API_KEY` | `GEMINI_API_KEY` |
| Install command | `npm i -g @anthropic-ai/claude-code` | `npm i -g @openai/codex` | `npm i -g @google/gemini-cli` |
| Pin version | `@anthropic-ai/claude-code@latest` | `@openai/codex@0.20` | `@google/gemini-cli@latest` |
