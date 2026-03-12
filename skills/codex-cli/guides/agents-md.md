# AGENTS.md Configuration

How to configure Codex CLI (and Copilot and Cursor) with AGENTS.md files.

## What Is AGENTS.md?

`AGENTS.md` is a markdown file that provides persistent instructions to Codex CLI. It's the Codex equivalent of Claude Code's `CLAUDE.md` or Gemini CLI's `GEMINI.md` — but with a key advantage: **AGENTS.md is shared across Codex CLI, GitHub Copilot, and Cursor**. Write it once, and all three tools follow the same instructions.

## File Discovery Hierarchy

Codex builds an instruction chain by reading files in this order:

1. **`~/.codex/AGENTS.override.md`** — Global override (highest priority)
2. **`~/.codex/AGENTS.md`** — Global defaults
3. **Git root to current directory**: At each level, reads:
   - `AGENTS.override.md` (override, if present)
   - `AGENTS.md` (standard, if present)

Files concatenate from root downward. Closer files take precedence in case of conflicting instructions.

## Basic Setup

### Project-Level (Most Common)

Create `AGENTS.md` at your project root:

```markdown
# Project Instructions

## Code Style
- Use TypeScript strict mode
- Prefer functional patterns over classes
- Use named exports, not default exports

## Testing
- Write tests for all new functions
- Use vitest for unit tests
- Integration tests go in tests/integration/

## Architecture
- API routes live in src/api/
- Business logic lives in src/services/
- Database queries live in src/db/
```

### Global Defaults

Create `~/.codex/AGENTS.md` for instructions that apply to all projects:

```markdown
# Global Defaults

- Always use descriptive variable names
- Include error handling for all async operations
- Prefer const over let
- Never commit secrets or API keys
```

### Subdirectory Overrides

Add `AGENTS.md` files in subdirectories for area-specific rules:

```
project/
├── AGENTS.md                  # Project-wide rules
├── src/
│   └── api/
│       └── AGENTS.md          # API-specific rules (appended to project rules)
└── tests/
    └── AGENTS.md              # Test-specific rules
```

## Override Files

`AGENTS.override.md` takes precedence over `AGENTS.md` at the same level. Use this for:

- **Team-specific rules** that shouldn't be in the shared AGENTS.md
- **Temporary overrides** during development
- **Machine-specific configuration**

```
~/.codex/
├── AGENTS.override.md    # Personal overrides (highest global priority)
└── AGENTS.md             # Personal defaults
```

## Configuration Options

### Alternate Filenames

If your project uses a different filename, configure it in `~/.codex/config.toml`:

```toml
[project_doc]
fallback_filenames = ["AGENTS.md", "CODEX.md", "AI_INSTRUCTIONS.md"]
```

### Size Limits

Combined instructions are capped at `project_doc_max_bytes` (32 KiB default). If your chain exceeds this, later files get truncated silently.

```toml
[project_doc]
max_bytes = 65536  # Increase to 64 KiB if needed
```

### Alternate Config Directory

```bash
# Use a different config directory
export CODEX_HOME=/path/to/alternate/config
```

## Verifying Your Configuration

```bash
# Ask Codex to summarize what instructions it sees
codex --ask-for-approval never "Summarize the current instructions you've been given."
```

## Cross-Tool Compatibility

| Config File | Codex CLI | Copilot | Cursor | Claude Code | Gemini CLI |
|-------------|-----------|---------|--------|-------------|------------|
| `AGENTS.md` | Yes | Yes | Yes | No | No |
| `CLAUDE.md` | No | No | No | Yes | No |
| `GEMINI.md` | No | No | No | No | Yes |

If you use multiple tools, you can maintain parallel config files. For shared rules, keep them in `AGENTS.md` (widest compatibility) and add tool-specific instructions in `CLAUDE.md` or `GEMINI.md`.

## Tips

- **Start small** — A few clear rules are better than a wall of text. Agents follow short, specific instructions more reliably.
- **Be explicit about file locations** — "Tests go in `tests/`" is better than "tests go in the test directory".
- **Include examples** — Show the pattern you want, don't just describe it.
- **Review the chain** — Use the verification command above to confirm Codex sees what you expect.
- **Watch the size limit** — If instructions seem to be ignored, you may have hit the 32 KiB cap.
