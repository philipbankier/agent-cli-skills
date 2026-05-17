# CLI Agent Comparison Matrix

Side-by-side reference for Claude Code, Codex CLI, Gemini CLI, and Grok Build non-interactive modes.

## Installation & Auth

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Install** | `npm i -g @anthropic-ai/claude-code` | `npm i -g @openai/codex` | `npm i -g @google/gemini-cli` | `curl -fsSL https://x.ai/cli/install.sh \| bash` |
| **Alt install** | - | `brew install --cask codex` | `brew install gemini-cli` | - |
| **Auth** | `claude auth login` | `codex login` (ChatGPT) or `OPENAI_API_KEY` | `gemini login` (Google) or `GEMINI_API_KEY` | `grok login`, cached auth, or `GROK_CODE_XAI_API_KEY` |
| **Verify auth** | `claude auth status` | - | - | `grok models` / `grok inspect` |
| **Free tier** | No (requires subscription or API key) | Included with ChatGPT Plus/Pro/etc. | 1000 requests/day with Google account | Account-dependent |

## Non-Interactive Mode

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Basic invocation** | `claude -p "prompt"` | `codex exec "prompt"` | `gemini -p "prompt"` | `grok -p "prompt"` |
| **Shorthand** | `claude -p` | `codex e` | - | `grok --single` |
| **Pipe input** | `echo "input" \| claude -p "prompt"` | `echo "input" \| codex exec "prompt"` | `echo "input" \| gemini -p "prompt"` | Use `--prompt-file` or prompt JSON; stdin piping not verified |
| **File input** | `claude -p "analyze" < file.py` | `cat file.py \| codex exec "analyze stdin"` | `gemini -p "analyze" < file.py` | `grok --prompt-file prompt.txt` |
| **Auto-approve** | `--dangerously-skip-permissions` | Prefer `--sandbox workspace-write`; dangerous bypass available | `-y` / `--yolo` | `--always-approve` |
| **Exit codes** | 0=success, non-zero=error | 0=success, non-zero=error | 0=success, 1=error, 42=input error, 53=turn limit | 0=success, non-zero=error |

## Output Formats

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Plain text** | `--output-format text` (default) | Default | Default | `--output-format plain` |
| **JSON** | `--output-format json` | `--json` | `--output-format json` | `--output-format json` |
| **Streaming** | `--output-format stream-json` | JSONL events with `--json` | `--output-format stream-json` | `--output-format streaming-json` |
| **Output to file** | Redirect with `>` | `-o file.txt` / `--output-last-message` | Redirect with `>` | Redirect with `>` |
| **Structured output** | `--json-schema '{...}'` -> `.structured_output` | `--output-schema` | - | Not verified |

## Session Management

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Stateless** | `--no-session-persistence` | `--ephemeral` | Default | Not verified as a single flag |
| **Named session** | `--session-id <id>` | - | - | Help/docs expose `--session-id`; named workflow not verified |
| **Resume last (interactive)** | `--continue` | `codex resume --last` | `-r latest` | `--continue` |
| **Resume last (non-interactive)** | `claude -p --resume <id>` | `codex exec resume --last` | `-r <index>` | `grok -p "..." --resume <sessionId>` |
| **List/pick sessions** | `--resume` (picker) | `codex resume` (picker) | `--list-sessions` | `grok sessions list` |

## Model Selection

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Flag** | `--model <name>` | `--model <name>` | `-m <name>` | `--model <name>` |
| **Aliases** | `sonnet`, `opus`, `haiku` | - | - | - |
| **Default** | Claude Sonnet 4.6 | Depends on user config | Gemini 2.5 Pro | `grok-build` locally |
| **Top models** | Opus 4.6, Sonnet 4.6, Haiku 4.5 | gpt-5.5, o3 | Gemini 3 Pro, Gemini 2.5 Flash | `grok-build` |

## Permission & Safety

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Full auto** | `--dangerously-skip-permissions` | `--dangerously-bypass-approvals-and-sandbox` only in external sandbox | `-y` / `--yolo` | `--always-approve` |
| **Read-only** | `--permission-mode plan` | `-s read-only` | `--approval-mode plan` | `--permission-mode plan`; `--sandbox read-only` help-exposed |
| **Sandboxed writes** | - | `-s workspace-write` | - | `--sandbox <PROFILE>` help-exposed, not fully verified |
| **Tool whitelist** | `--allowedTools "Bash(git:*) Edit"` | - | - | `--allow`, `--deny`, `--tools` help-exposed |
| **Budget limit** | `--max-budget-usd 1.00` | - | - | - |

## Configuration Files

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Project config** | `CLAUDE.md` | `AGENTS.md` | `GEMINI.md` | `.grok/` plus Claude-compatible instructions |
| **Global config** | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.gemini/GEMINI.md` | `~/.grok` plus observed `~/.claude` resources |
| **Override file** | - | `AGENTS.override.md` | - | Permissions/config via Grok and Claude-compatible sources |
| **Cross-tool compat** | Claude Code only | Copilot, Cursor, Codex | Gemini CLI only | Reads Claude-compatible skills/plugins/MCP/hooks per docs and local inspect |
| **Import syntax** | - | - | `@file.md` | Not verified |

## Skill / Extension System

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Skill directory** | `.claude/skills/` | `.agents/skills/` | `.gemini/skills/` | `.grok/skills/` and Claude-compatible skill paths |
| **User-level skills** | `~/.claude/skills/` | `~/.codex/skills/` | `~/.gemini/skills/` | `~/.grok/skills/` plus observed `~/.claude/skills/` |
| **Entry point** | `SKILL.md` | `SKILL.md` | `SKILL.md` | `SKILL.md` |
| **Subdirectories** | guides/, reference/, examples/ | (flexible) | (flexible) | (flexible) |
| **Extensions** | - | Plugins | Bundles: skills + MCP + commands + themes + hooks | Claude-compatible plugins and marketplaces |
| **MCP support** | Via settings | Via config | Via extensions | Via Grok and Claude-compatible config; ACP server via `grok agent stdio` |

## Streaming Details

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Format** | NDJSON (one JSON per line) | JSONL (`--json`) | Stream JSON (`--output-format stream-json`) | JSONL (`--output-format streaming-json`) |
| **Recommended with** | `--verbose` flag (enables system/init events) | - | - | `--disable-web-search --no-plan` for deterministic smoke tests |
| **Partial messages** | `--include-partial-messages` | - | Built-in with stream-json | Text chunks emitted as `type: "text"` |
| **Event types** | `system`, `assistant`, `result` | `thread.started`, `turn.started`, `item.completed`, `turn.completed` | Session metadata, message chunks, tool calls, stats | `thought`, `text`, `end` observed locally |

## System Prompts

| | Claude Code | Codex CLI | Gemini CLI | Grok Build |
|---|---|---|---|---|
| **Replace default** | `--system-prompt "..."` | - | - | `--system-prompt-override` help-exposed |
| **Append to default** | `--append-system-prompt "..."` | Via AGENTS.md | Via GEMINI.md | Via instructions/skills; exact precedence needs verification |
| **Via config file** | CLAUDE.md (always loaded) | AGENTS.md (always loaded) | GEMINI.md (always loaded) | `.grok` and Claude-compatible sources |

## Key Gotchas Per CLI

### Claude Code
- `stream-json` works best with `--verbose` (enables system-level init/result events alongside message events)
- `--system-prompt` replaces (not appends) the default — use `--append-system-prompt`
- Structured output lands in `.structured_output`, not `.result`
- No temperature/top_p control via CLI flags

### Codex CLI
- `--full-auto` is deprecated compatibility in v0.130; prefer `--sandbox workspace-write`
- `--json` outputs JSONL with `agent_message` items for final text
- Pipe stdin directly to `codex exec "prompt"`; the old `codex exec "prompt" -` form now fails
- Session resume has two forms: `codex resume --last` (interactive TUI) and `codex exec resume --last` (non-interactive exec mode). They are different commands, not aliases.
- Parent options for resume go before `resume`: `codex exec --sandbox read-only resume --last "..."`

### Grok Build
- Run `grok inspect` before debugging because Grok can load Claude-compatible skills, plugins, hooks, agents, and MCP servers
- Use `--max-turns 10` or higher even for simple smoke tests
- Resume scripts should capture the actual JSON `sessionId`; named `--session-id` is not verified here
- `--check`, `--best-of-n`, `--permission-mode`, `--worktree`, and `--sandbox` are help-exposed but need task-specific verification

### Gemini CLI
- A single prompt can trigger multiple API requests (affects quota)
- Free tier is 1000 *model requests*/day, not 1000 *prompts*/day
- `-y`/`--yolo` auto-approves all changes; for granular control use `--approval-mode` (`default`, `auto_edit`, `yolo`, `plan`)
- Sessions supported with `-r`/`--resume`, `--list-sessions`, `--delete-session`
- Monitor usage with `/stats model` in interactive mode

## API Proxy Options

For SDK compatibility without API keys, see the [API Proxy Pattern guide](patterns/api-proxy-pattern.md).

| Aspect | Direct CLI | CC-Bridge | CLIProxyAPI |
|--------|-----------|-----------|-------------|
| **How it works** | Shell commands | HTTP → CLI subprocess | HTTP → direct API call |
| **Multi-provider** | One CLI at a time | Claude only | Claude, Codex, Gemini, + more |
| **Multi-account** | No | No | Yes (round-robin) |
| **SDK compatible** | No | Yes (Anthropic) | Yes (OpenAI/Claude/Gemini) |
| **Best for** | Scripts, CI/CD | Learning, local dev | Production, multi-tenant |
