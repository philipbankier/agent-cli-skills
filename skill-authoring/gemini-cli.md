# Writing Skills for Gemini CLI

A guide to creating skills that Gemini CLI agents can discover and use.

## What Is a Gemini Skill?

A **skill** is a self-contained directory of specialized instructions that activates when a task matches its description. Gemini CLI loads skill metadata at startup, and the full skill content is injected into context only when activated — this keeps startup fast and context lean.

Skills can live standalone or be bundled inside [extensions](../skills/gemini-cli/guides/extensions.md).

## Directory Structure

Skills live in `.gemini/skills/` at the workspace level or `~/.gemini/skills/` at the user level:

```
.gemini/skills/my-skill/
├── SKILL.md              # Entry point (required)
├── guides/               # Task-oriented walkthroughs
│   └── getting-started.md
├── reference/            # Lookup tables, schemas
│   └── commands.md
└── examples/             # Runnable examples
    └── demo.sh
```

### Precedence Order

1. **Workspace skills** (`.gemini/skills/`) — highest precedence
2. **User skills** (`~/.gemini/skills/`)
3. **Extension-bundled skills** — lowest precedence

Skills with the same name at higher precedence override lower ones.

## SKILL.md: The Entry Point

```yaml
---
name: my-skill-name
description: One-line description. Be specific — Gemini uses this for automatic task matching.
---

# My Skill

## Quick Start
[Copy-paste recipes]

## Decision Router
[If X, read Y]

## Reference
[Links to subdirectory files]
```

## Skill Activation Flow

1. **Discovery** — CLI scans skill directories at startup, loads metadata (name + description)
2. **Matching** — Model identifies a task that fits a skill's description
3. **Activation** — Model calls the `activate_skill` tool
4. **Approval** — User receives a confirmation prompt
5. **Injection** — Full SKILL.md content and directory access granted
6. **Execution** — Model follows the skill's instructions

### Writing Good Descriptions

The `description` field determines when your skill activates. Be specific:

**Good**: "Deploy Docker containers with health checks, blue-green rollouts, and automatic rollback on failure"
**Bad**: "Docker stuff"

Include the key terms a user would naturally say when requesting this kind of task.

## Standalone vs Extension-Bundled

### Standalone Skill

Drop into `.gemini/skills/` — simple, no packaging needed:

```bash
cp -r my-skill .gemini/skills/my-skill
```

### Extension-Bundled Skill

Package inside an extension for distribution:

```
my-extension/
├── extension.json
└── skills/
    └── my-skill/
        └── SKILL.md
```

Extensions can bundle skills alongside MCP servers, commands, themes, and hooks. See the [extensions guide](../skills/gemini-cli/guides/extensions.md).

## Writing Agent-Friendly Content

### Do
- **Use decision routers** — "If you want X, read Y"
- **Include copy-paste recipes** — Working code the agent uses immediately
- **Document gotchas** — Non-obvious behaviors, silent failures
- **Use tables for reference data** — Flags, schemas, format comparisons
- **Keep files focused** — One topic per file

### Don't
- **Write prose-heavy docs** — Agents need structure, not paragraphs
- **Assume full reading** — Design for lazy loading via file map
- **Skip error cases** — Agents need to know failure modes

## Integration with GEMINI.md

Skills and GEMINI.md serve different purposes:

- **GEMINI.md** — Project-wide conventions, coding standards, architecture rules (always loaded)
- **Skills** — Specialized workflows activated on demand (loaded when needed)

Your skill can reference GEMINI.md conventions:
```markdown
Follow the project's coding standards as defined in GEMINI.md.
```

## Testing Your Skill

1. Install: `cp -r my-skill .gemini/skills/my-skill`
2. Start Gemini CLI interactively
3. Ask a task that matches your skill's description
4. Verify: skill activates, routes to correct guide, produces correct output
5. Edge test: tasks close to but outside your skill's scope should NOT activate

## Example: Minimal Skill

```
.gemini/skills/pr-reviewer/
└── SKILL.md
```

**SKILL.md:**
```yaml
---
name: pr-reviewer
description: Review pull request diffs for bugs, security issues, and code quality.
---

# PR Reviewer

## Quick Start

Ask Gemini to review your changes:

> "Review my staged changes for issues"

## Recipe

\```bash
git diff --cached | gemini -p "Review this diff for bugs and security issues" -m gemini-2-5-flash
\```

## Checklist

The review covers:
- Null/undefined checks
- Error handling completeness
- SQL injection and XSS risks
- Hardcoded secrets
- Logic errors and off-by-one bugs
```

Start small. Add guides and references as the skill grows.

## Cross-Platform Note

Gemini CLI skills use the same SKILL.md format as Claude Code and Codex CLI skills. For writing skills that work across all three, see [cross-platform.md](cross-platform.md).
