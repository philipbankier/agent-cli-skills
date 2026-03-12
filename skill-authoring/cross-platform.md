# Cross-Platform Skill Design

How to write skills that work across Claude Code, Codex CLI, and Gemini CLI.

## The Convergence

All three CLI agents have converged on remarkably similar skill formats:

| Aspect | Claude Code | Codex CLI | Gemini CLI |
|--------|------------|-----------|------------|
| Entry point | `SKILL.md` | `SKILL.md` | `SKILL.md` |
| Frontmatter | `name`, `description` | `name`, `description` | `name`, `description` |
| Install location | `.claude/skills/` | `.agents/skills/` | `.gemini/skills/` |
| Discovery | Auto by description match | Auto by description match | Auto by description match |

This means a well-structured skill can work across all three with minimal adaptation.

## Two Approaches

### Approach 1: Shared Core + Platform Sections

Write a single SKILL.md that uses clearly marked platform-specific sections:

```markdown
---
name: my-cross-platform-skill
description: Does X for Claude Code, Codex CLI, and Gemini CLI.
---

# My Skill

## Quick Start

### Claude Code
\```bash
claude -p "do the thing" --output-format json
\```

### Codex CLI
\```bash
codex exec "do the thing" --json
\```

### Gemini CLI
\```bash
gemini -p "do the thing" --output-format json
\```
```

**Pros:** Single source of truth, easy to maintain, shows differences clearly.
**Cons:** Agents load content for all three CLIs even when using just one.

### Approach 2: Platform-Adaptive Skill (Recommended)

Write a shared SKILL.md core with platform-specific guide files:

```
my-skill/
├── SKILL.md                    # Shared decision router + concepts
├── guides/
│   ├── claude-code.md          # Claude Code-specific recipes
│   ├── codex-cli.md            # Codex CLI-specific recipes
│   └── gemini-cli.md           # Gemini CLI-specific recipes
├── reference/
│   └── comparison.md           # Flag mapping table
└── examples/
    ├── claude-code/
    ├── codex-cli/
    └── gemini-cli/
```

The SKILL.md decision router detects which CLI is being used and routes accordingly:

```markdown
## Decision Router

### Using Claude Code?
-> Read [guides/claude-code.md](guides/claude-code.md)

### Using Codex CLI?
-> Read [guides/codex-cli.md](guides/codex-cli.md)

### Using Gemini CLI?
-> Read [guides/gemini-cli.md](guides/gemini-cli.md)
```

**Pros:** Each agent only loads its own content. Clean separation.
**Cons:** Some content duplication between platform guides.

## The Flag Translation Table

Every cross-platform skill should include a mapping of equivalent flags:

| Concept | Claude Code | Codex CLI | Gemini CLI |
|---------|------------|-----------|------------|
| Non-interactive | `claude -p` | `codex exec` | `gemini -p` |
| JSON output | `--output-format json` | `--json` | `--output-format json` |
| Auto-approve | `--dangerously-skip-permissions` | `--full-auto --yolo` | `-y` |
| No session | `--no-session-persistence` | `--ephemeral` | Default |
| Model select | `--model sonnet` | `--model o4-mini` | `-m gemini-2-5-flash` |

## Shared Patterns That Work Everywhere

These shell patterns are CLI-agnostic:

### Parallel Execution
```bash
# Works for any CLI — just change the command
for topic in "AI ethics" "Climate tech" "Space exploration"; do
  $CLI_COMMAND "$topic" --output-format json > "/tmp/result-${topic// /-}.json" &
done
wait
```

### Output Aggregation
```bash
# Merge JSON results from parallel runs
jq -s '.' /tmp/result-*.json > combined.json
```

### Error Handling
```bash
if ! result=$($CLI_COMMAND "prompt" 2>/dev/null); then
  echo "CLI call failed" >&2
  exit 1
fi
```

## Platform-Specific Gotchas to Document

When writing cross-platform skills, always call out these differences:

### Output Shape Differences
- **Claude Code**: JSON response has `.result` for text and `.structured_output` for schema-validated data
- **Codex CLI**: Output shape depends on `--json` vs `--experimental-json`
- **Gemini CLI**: JSON response structure differs; JSONL for streaming

### Session Behavior
- **Claude Code**: Persists sessions by default — add `--no-session-persistence` for stateless
- **Codex CLI**: Has built-in session resume with `codex exec resume --last`
- **Gemini CLI**: Stateless by default in non-interactive mode

### Permission Models
- **Claude Code**: Granular (tool whitelist, permission modes, budget limits)
- **Codex CLI**: Binary (sandboxed vs full-auto)
- **Gemini CLI**: Binary (approve each vs auto-approve all with `-y`)

## Testing Across CLIs

1. Install the skill into each CLI's skill directory
2. Start each CLI and verify skill discovery
3. Run the same task in all three and compare outputs
4. Verify platform-specific guides are correctly routed
5. Test edge cases: what happens if the skill is installed in the wrong CLI's directory?

## This Repo as Reference Implementation

The `agent-cli-skills` repo itself is a reference implementation of cross-platform skill design. Each skill under `skills/` follows the same structure pattern but with platform-specific content. The `cross-platform/` directory shows shared patterns. Study how the debate engine example is adapted across all three CLIs for a concrete example.
