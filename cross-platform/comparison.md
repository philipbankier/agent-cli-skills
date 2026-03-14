# CLI Agent Comparison Matrix

Side-by-side reference for Claude Code, Codex CLI, and Gemini CLI non-interactive modes.

## Installation & Auth

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Install** | `npm i -g @anthropic-ai/claude-code` | `npm i -g @openai/codex` | `npm i -g @google/gemini-cli` |
| **Alt install** | — | `brew install --cask codex` | `brew install gemini-cli` |
| **Auth** | `claude auth login` | `codex login` (ChatGPT) or `OPENAI_API_KEY` | `gemini login` (Google) or `GEMINI_API_KEY` |
| **Verify auth** | `claude auth status` | — | — |
| **Free tier** | No (requires subscription or API key) | Included with ChatGPT Plus/Pro/etc. | 1000 requests/day with Google account |

## Non-Interactive Mode

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Basic invocation** | `claude -p "prompt"` | `codex exec "prompt"` | `gemini -p "prompt"` |
| **Shorthand** | `claude -p` | `codex e` | — |
| **Pipe input** | `echo "prompt" \| claude -p` | `echo "prompt" \| codex exec -` | `echo "prompt" \| gemini` |
| **File input** | `claude -p "analyze" < file.py` | — | — |
| **Auto-approve** | `--dangerously-skip-permissions` | `--full-auto` + `--dangerously-bypass-approvals-and-sandbox` | `-y` / `--yolo` |
| **Exit codes** | 0=success, non-zero=error | 0=success, non-zero=error | 0=success, 1=error, 42=input error, 53=turn limit |

## Output Formats

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Plain text** | `--output-format text` (default) | Default | Default |
| **JSON** | `--output-format json` | `--json` | `--output-format json` |
| **Streaming** | `--output-format stream-json` | — | `--output-format stream-json` |
| **Output to file** | Redirect with `>` | `-o file.txt` / `--output-last-message` | Redirect with `>` |
| **Structured output** | `--json-schema '{...}'` → `.structured_output` | `--output-schema` | — |

## Session Management

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Stateless** | `--no-session-persistence` | `--ephemeral` | Default |
| **Named session** | `--session-id <id>` | — | — |
| **Resume last** | `--continue` | `codex resume --last` | `-r` / `--resume` |
| **Resume all** | — | `codex resume --all` | `--list-sessions` |

## Model Selection

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Flag** | `--model <name>` | `--model <name>` | `-m <name>` |
| **Aliases** | `sonnet`, `opus`, `haiku` | — | — |
| **Default** | Claude Sonnet 4 | Depends on user config | Gemini 2.5 Pro |
| **Top models** | Opus 4, Sonnet 4, Haiku 3.5 | o4-mini, GPT-4.1 | Gemini 3 Pro, Gemini 2.5 Flash |

## Permission & Safety

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Full auto** | `--dangerously-skip-permissions` | `--full-auto` + `--dangerously-bypass-approvals-and-sandbox` | `-y` / `--yolo` |
| **Read-only** | `--permission-mode plan` | `-s read-only` | `--approval-mode plan` |
| **Sandboxed writes** | — | `-s workspace-write` (default) | — |
| **Tool whitelist** | `--allowedTools "tool1,tool2"` | — | — |
| **Budget limit** | `--max-budget-usd 1.00` | — | — |

## Configuration Files

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Project config** | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` |
| **Global config** | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.gemini/GEMINI.md` |
| **Override file** | — | `AGENTS.override.md` | — |
| **Cross-tool compat** | Claude Code only | Copilot, Cursor, Codex | Gemini CLI only |
| **Import syntax** | — | — | `@file.md` |

## Skill / Extension System

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Skill directory** | `.claude/skills/` | `.agents/skills/` | `.gemini/skills/` |
| **User-level skills** | `~/.claude/skills/` | `~/.codex/skills/` | `~/.gemini/skills/` |
| **Entry point** | `SKILL.md` | `SKILL.md` | `SKILL.md` |
| **Subdirectories** | guides/, reference/, examples/ | scripts/, references/, assets/ | (flexible) |
| **Extensions** | — | — | Bundles: skills + MCP + commands + themes + hooks |
| **MCP support** | Via settings | Via config | Via extensions |

## Streaming Details

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Format** | NDJSON (one JSON per line) | JSONL (`--json`) | Stream JSON (`--output-format stream-json`) |
| **Requires** | `--verbose` flag (critical!) | — | — |
| **Partial messages** | `--include-partial-messages` | — | Built-in with stream-json |
| **Event types** | `system`, `assistant`, `result` | `thread.started`, `turn.started`, `item.completed`, `turn.completed` | Session metadata, message chunks, tool calls, stats |

## System Prompts

| | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| **Replace default** | `--system-prompt "..."` | — | — |
| **Append to default** | `--append-system-prompt "..."` | Via AGENTS.md | Via GEMINI.md |
| **Via config file** | CLAUDE.md (always loaded) | AGENTS.md (always loaded) | GEMINI.md (always loaded) |

## Key Gotchas Per CLI

### Claude Code
- `stream-json` silently fails without `--verbose`
- `--system-prompt` replaces (not appends) the default — use `--append-system-prompt`
- Structured output lands in `.structured_output`, not `.result`
- No temperature/top_p control via CLI flags

### Codex CLI
- Full auto requires multiple flags: `--full-auto` + `--dangerously-bypass-approvals-and-sandbox` + trusted workspace
- `--json` outputs JSONL with event types: `thread.started`, `turn.started`, `item.completed`, `turn.completed`
- Session resume is a top-level subcommand: `codex resume --last`, not under `exec`

### Gemini CLI
- A single prompt can trigger multiple API requests (affects quota)
- Free tier is 1000 *model requests*/day, not 1000 *prompts*/day
- `-y`/`--yolo` auto-approves all changes; for granular control use `--approval-mode` (`default`, `auto_edit`, `yolo`, `plan`)
- Sessions supported with `-r`/`--resume`, `--list-sessions`, `--delete-session`
- Monitor usage with `/stats model` in interactive mode
