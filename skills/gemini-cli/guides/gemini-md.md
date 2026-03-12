# GEMINI.md Configuration

How to configure Gemini CLI with GEMINI.md files for project-wide AI instructions.

## What Is GEMINI.md?

`GEMINI.md` is a markdown file that provides persistent instructions to Gemini CLI. Every prompt sent includes the concatenated content of all discovered GEMINI.md files, ensuring consistent behavior without repeating instructions.

## File Discovery Hierarchy

Gemini CLI discovers files in this order (by priority):

1. **Global context**: `~/.gemini/GEMINI.md` — applies to all projects
2. **Workspace context**: `GEMINI.md` files in configured directories and parent folders
3. **Just-in-time context**: Files auto-scanned when tools access specific directories

All discovered files are concatenated and sent with every prompt.

## Basic Setup

### Project-Level (Most Common)

Create `GEMINI.md` at your project root:

```markdown
# Project Instructions

## Code Style
- Use TypeScript strict mode
- Prefer functional patterns over classes
- Use named exports, not default exports

## Testing
- Write tests for all new functions
- Use vitest for unit tests

## Architecture
- API routes in src/api/
- Business logic in src/services/
- Database queries in src/db/
```

### Global Defaults

Create `~/.gemini/GEMINI.md` for instructions that apply everywhere:

```markdown
# Global Defaults

- Always use descriptive variable names
- Include error handling for async operations
- Never commit secrets or API keys
```

## Modular Configuration with @import

For large projects, break your config into focused modules:

```markdown
# GEMINI.md (root)

@coding-standards.md
@architecture.md
@testing-guidelines.md
```

Each `@file.md` reference is resolved relative to the GEMINI.md file's location. This supports both relative and absolute paths.

**Example file tree:**
```
project/
├── GEMINI.md                     # Root config with @imports
├── .gemini/
│   ├── coding-standards.md       # Imported by root GEMINI.md
│   ├── architecture.md
│   └── testing-guidelines.md
└── src/
```

## Configuration via settings.json

### Alternate Filename

If your project uses a different name:

```json
// .gemini/settings.json
{
  "context": {
    "fileName": "AI_INSTRUCTIONS.md"
  }
}
```

### Additional Context Directories

```json
{
  "context": {
    "additionalDirs": ["docs/ai-context/"]
  }
}
```

## Interactive Memory Commands

In the interactive TUI, you can manage context dynamically:

```
/memory show       — Display concatenated context from all GEMINI.md files
/memory reload     — Rescan and reload all files
/memory add <text> — Append text to the global GEMINI.md file
```

## Cross-Tool Comparison

| Feature | GEMINI.md | CLAUDE.md | AGENTS.md |
|---------|-----------|-----------|-----------|
| Tool | Gemini CLI | Claude Code | Codex/Copilot/Cursor |
| Global location | `~/.gemini/GEMINI.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` |
| Import syntax | `@file.md` | — | — |
| Override file | — | — | `AGENTS.override.md` |
| Size limit | Not documented | Not documented | 32 KiB |
| Interactive management | `/memory` commands | — | — |

## Tips

- **Start small** — A few clear rules beat a wall of text
- **Use @imports for large configs** — Keeps the root file scannable
- **Be specific about file paths** — "Tests go in `tests/unit/`" not "tests go in the test directory"
- **Include examples** — Show the pattern you want, don't just describe it
- **Use `/memory show` to verify** — Confirm Gemini sees what you expect
- **GEMINI.md is always loaded** — Everything in it adds to every prompt's token count
