# Session Management in Codex CLI

How to use session resume for multi-step workflows and manage session persistence.

## Session Basics

By default, Codex CLI persists sessions to disk after each `codex exec` invocation.
This enables a powerful pattern: multi-step workflows where each step builds on the previous one's context.

## Multi-Step Workflows with Resume

### The Resume Pattern

```bash
# Step 1: Analyze
codex exec "Analyze the authentication module. Identify the top 3 security concerns."

# Step 2: Resume and act on analysis
codex exec resume --last \
  "Implement fixes for the security concerns you identified. Start with the highest priority."

# Step 3: Resume and verify
codex exec resume --last \
  "Write tests to verify the security fixes you just implemented."

# Step 4: Resume and document
codex exec resume --last \
  "Write a summary of all changes made, suitable for a PR description." \
  -o pr-description.md
```

Each `resume --last` picks up the full conversation context from the previous step.

### Resume Options

```bash
# Resume the most recent session
codex exec resume --last "Continue from where we left off"

# List all available sessions and choose one
codex exec resume --all

# Resume is directory-scoped — the "last" session depends on your current directory
```

### Combining Resume with Output Capture

```bash
# First pass: analysis (no file output, just building context)
codex exec "Read through src/ and create a mental model of the architecture"

# Second pass: capture the result to file
codex exec resume --last \
  "Now write an architecture document based on your analysis" \
  -o ARCHITECTURE.md
```

## Stateless Mode

When you don't want session persistence:

```bash
# Ephemeral mode — no session saved to disk
codex exec "What time is it?" --ephemeral

# Recommended for:
# - CI/CD pipelines
# - Batch processing loops
# - One-shot queries
# - Any automation where you don't need to resume
```

## Session Storage

Sessions are stored on disk per-directory. Key behaviors:

- **Directory-scoped**: Each working directory has its own session history
- **`resume --last`**: Finds the most recent session in the current directory
- **Disk accumulation**: Without `--ephemeral`, sessions pile up over time

## Practical Patterns

### Iterative Code Refactoring

```bash
#!/usr/bin/env bash
# iterative-refactor.sh — Multi-step refactoring with session context

FILE="${1:?Usage: iterative-refactor.sh <file>}"

echo "Step 1: Analyzing $FILE..."
codex exec "Read $FILE and identify code smells, complexity issues, and improvement opportunities. List them ranked by impact."

echo "Step 2: Refactoring..."
codex exec resume --last \
  "Now implement the top improvements you identified. Make the changes directly to the file." \
  --full-auto

echo "Step 3: Verifying..."
codex exec resume --last \
  "Review the changes you just made. Are there any regressions or issues?" \
  -o "/tmp/refactor-review-$(basename "$FILE").md"

echo "Review saved to /tmp/refactor-review-$(basename "$FILE").md"
```

### Research → Generate Pipeline

```bash
#!/usr/bin/env bash
# Build context in step 1, generate artifact in step 2

# Step 1: Research (builds context, output not critical)
codex exec "Read all files in docs/ and understand the API design patterns used in this project."

# Step 2: Generate (uses accumulated context)
codex exec resume --last \
  "Based on your understanding, write API documentation for the endpoints in src/api/. Follow the same patterns you found in docs/." \
  -o docs/api-reference.md
```

## Tips

- **Use resume for related steps, ephemeral for independent tasks** — Don't waste context on unrelated queries
- **Capture the final step to file** — Use `-o` on the last step to get a clean output artifact
- **Remember directory scoping** — If you `cd` between steps, `--last` finds a different session
- **Clean up old sessions periodically** — Sessions accumulate on disk; purge when no longer needed
