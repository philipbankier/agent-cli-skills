# Writing Skills for Claude Code

A guide to creating skills that Claude Code agents can discover and use.

## What Is a Skill?

A **skill** is a structured knowledge package that AI agents load on demand. It's documentation optimized for AI consumption — with a decision router, copy-paste recipes, and cross-linked references — though humans can read it too.

When Claude Code encounters a task that matches a skill's description, it loads the skill's entry point and follows the decision router to find the right guide.

## Directory Structure

Skills live in `.claude/skills/` at the project level or `~/.claude/skills/` at the user level:

```
.claude/skills/my-skill/
├── SKILL.md              # Entry point (required)
├── guides/               # Task-oriented walkthroughs
│   ├── getting-started.md
│   └── advanced-usage.md
├── reference/            # Lookup tables, flag matrices, schemas
│   ├── flags.md
│   └── code-snippets.md
└── examples/             # Working, runnable examples
    └── my-example/
        ├── run.sh
        └── WALKTHROUGH.md
```

## SKILL.md: The Entry Point

Every skill needs a `SKILL.md` with YAML frontmatter:

```yaml
---
name: my-skill-name
description: One-line description of what this skill does. Be specific — this is how the agent decides whether to load it.
---
```

The `description` field is critical. The agent uses it to match tasks to skills. Be specific about the use cases, not generic. "Build and deploy Docker containers with health checks and rollback" is better than "Docker skill".

### Anatomy of a Good SKILL.md

1. **Overview** — What this skill does, when to use it, prerequisites
2. **Decision Router** — "What are you trying to do?" → links to guides
3. **Quick Start Recipes** — 3-4 copy-paste patterns covering 80% of use cases
4. **Core Concepts** — Key abstractions the agent needs to understand
5. **Critical Gotchas** — Non-obvious behaviors that will cause failures
6. **File Map** — Which files to load and when (lazy-loading)

### The Decision Router Pattern

```markdown
## Decision Router

### "I want to deploy a container"
-> Read [guides/deploy.md](guides/deploy.md)
Key commands: `docker build`, `docker push`, `docker run`

### "I want to set up health checks"
-> Read [guides/health-checks.md](guides/health-checks.md)
Pattern: HTTP probe on /health, TCP fallback
```

This pattern is essential. Agents work best when given clear routing — "if X, then read Y" — rather than having to scan entire documents.

### The File Map Pattern

```markdown
## File Map

Load these files only when the decision router points you to them:

| File | Description | Load When |
|---|---|---|
| `guides/deploy.md` | Container deployment guide | Building or deploying containers |
| `reference/flags.md` | Complete flag reference | Need exact flag syntax |
```

This enables **lazy loading** — the agent only reads files it needs, saving context window.

## Writing for Agents

### Do
- **Use decision routers** — "If you want X, read Y"
- **Include copy-paste recipes** — Working code the agent can use immediately
- **Document gotchas explicitly** — Non-obvious behaviors, silent failures, flag interactions
- **Use tables for reference data** — Flags, schemas, format comparisons
- **Keep files focused** — One topic per guide, one concern per reference file

### Don't
- **Don't write prose-heavy docs** — Agents need structure, not paragraphs
- **Don't assume the agent reads everything** — Design for lazy loading
- **Don't use relative terms** — "The default behavior" should be "When no flag is set, the output is plain text"
- **Don't skip error cases** — Agents need to know what happens when things fail

## Testing Your Skill

1. Install it: `cp -r my-skill .claude/skills/my-skill`
2. Start Claude Code in your project
3. Ask a question that matches your skill's description
4. Verify the agent loads the skill and routes to the correct guide
5. Try edge cases — tasks that are close to but outside your skill's scope

## Example: Minimal Skill

```
.claude/skills/git-worktree/
├── SKILL.md
└── reference/
    └── commands.md
```

**SKILL.md:**
```yaml
---
name: git-worktree
description: Manage git worktrees for parallel branch development. Use when working on multiple branches simultaneously without stashing.
---

# Git Worktree Skill

## Decision Router

### "I want to work on two branches at once"
-> Read [reference/commands.md](reference/commands.md)

## Quick Recipe

\```bash
# Create a worktree for a feature branch
git worktree add ../my-feature feature-branch

# List active worktrees
git worktree list

# Clean up when done
git worktree remove ../my-feature
\```
```

That's it. Start small, add guides as the skill grows.
