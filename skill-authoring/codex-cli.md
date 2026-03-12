# Writing Skills for Codex CLI

A guide to creating skills that Codex CLI agents can discover and use.

## What Is a Codex Skill?

A **skill** is a self-contained directory that packages specialized instructions and assets into a discoverable capability. Codex loads skill metadata at startup and activates the full skill when a task matches its description.

Skills in Codex follow the **Agent Skills** open standard, which is shared across Codex CLI, GitHub Copilot, and Cursor.

## Directory Structure

Skills live in `.agents/skills/` at the project level, `~/.codex/skills/` at the user level, or `/etc/codex/skills/` at the system level:

```
.agents/skills/my-skill/
├── SKILL.md              # Entry point (required)
├── scripts/              # Executable code
│   └── analyze.sh
├── references/           # Documentation and guides
│   ├── flags.md
│   └── patterns.md
└── assets/               # Templates and resources
    └── template.yaml
```

### Precedence Order

1. **Repository level**: `.agents/skills/` in current directory and parents
2. **User level**: `$HOME/.agents/skills/` (or `$HOME/.codex/skills/`)
3. **Admin level**: `/etc/codex/skills/`
4. **System**: Built-in skills from OpenAI

Higher-precedence skills override lower-precedence ones with the same name.

## SKILL.md: The Entry Point

```yaml
---
name: my-skill-name
description: One-line description of what this skill does. Be specific — Codex uses this for task matching.
---

# My Skill

## When to Use
[Describe the situations where this skill is relevant]

## Quick Start
[Copy-paste recipes for the most common use cases]

## Reference
[Links to files in references/ for deeper detail]
```

### Key Differences from Claude Code Skills

| Aspect | Claude Code | Codex CLI |
|--------|------------|-----------|
| Subdirectories | `guides/`, `reference/`, `examples/` | `scripts/`, `references/`, `assets/` |
| Executable code | Not standard | `scripts/` directory for runnable code |
| Config integration | CLAUDE.md | AGENTS.md |
| UI config | — | Optional `agents/openai.yaml` for UI dependencies |

## Skill Invocation

### Explicit
Users invoke skills with the `/skills` command or `$` mention syntax in the interactive TUI.

### Implicit (Auto-Discovery)
Codex autonomously selects skills when a task description matches the skill's `description` field. Write descriptions that are specific about use cases:

**Good**: "Deploy Docker containers with health checks, rollback, and blue-green strategy"
**Bad**: "Docker deployment"

## Progressive Disclosure

Codex loads skill metadata (name, description) first. The full SKILL.md content is only loaded when the skill is selected. This keeps startup fast even with many skills installed.

Design your skill with this in mind:
- Put the most critical info (recipes, gotchas) in SKILL.md
- Put detailed reference material in `references/` files
- Put runnable automation in `scripts/`

## The scripts/ Directory

Unlike Claude Code skills (which are documentation-only), Codex skills can include executable scripts:

```bash
# scripts/setup.sh
#!/usr/bin/env bash
# Called by Codex when the skill needs to set up dependencies

npm install
docker-compose up -d
```

Scripts can be referenced from SKILL.md and executed by the agent as part of skill activation.

## Integration with AGENTS.md

Skills complement AGENTS.md. Use AGENTS.md for:
- Project-wide coding standards
- Architecture decisions
- Team conventions

Use skills for:
- Specialized workflows (deployment, testing, code generation)
- Reusable patterns across projects
- Community-shared capabilities

## Managing Skills

```bash
# Install a community skill
$skill-installer install <skill-url>

# Disable a skill without deleting
# Add to ~/.codex/config.toml:
# [[skills.config]]
# name = "my-skill"
# enabled = false

# List installed skills
ls .agents/skills/
```

## Cross-Platform Note

Since Codex uses the Agent Skills open standard, skills designed for Codex can often work with Copilot and Cursor with minimal changes. The `SKILL.md` format and directory structure are compatible across these tools.

For writing skills that also work with Claude Code and Gemini CLI, see [cross-platform.md](cross-platform.md).

## Example: Minimal Skill

```
.agents/skills/pr-reviewer/
├── SKILL.md
└── scripts/
    └── review.sh
```

**SKILL.md:**
```yaml
---
name: pr-reviewer
description: Review pull request diffs for bugs, security issues, and code quality problems.
---

# PR Reviewer

## Quick Start

Ask Codex to review your current changes:

> "Review my staged changes for issues"

Or run the review script directly:

\```bash
./scripts/review.sh
\```

## How It Works

1. Gets the git diff of staged or recent changes
2. Analyzes for common issues (null checks, error handling, SQL injection)
3. Reports findings with severity levels
```

**scripts/review.sh:**
```bash
#!/usr/bin/env bash
git diff --cached | codex exec - \
  "Review this diff for bugs and security issues. Rate each finding as HIGH, MEDIUM, or LOW." \
  --ephemeral -o review.md
cat review.md
```
