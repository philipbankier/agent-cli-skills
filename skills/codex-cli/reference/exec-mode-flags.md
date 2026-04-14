# Codex CLI Exec Mode Flags

Complete reference for `codex exec` (alias: `codex e`) non-interactive mode flags.
Last verified against `codex exec --help` for **Codex CLI v0.114.0** on 2026-04-14.

For all other subcommands (`codex sandbox`, `codex cloud`, `codex apply`, `codex fork`,
`codex resume`, `codex features`, etc.), see [subcommands.md](subcommands.md).

## Core Flags

| Flag | Short / alias | Description | Default |
|------|--------------|-------------|---------|
| `--full-auto` | — | Automation preset: workspace-write sandbox + on-request approvals | Off |
| `--dangerously-bypass-approvals-and-sandbox` | — | Skip all approvals and sandboxing — only safe in externally-sandboxed environments | Off |
| `-a <policy>` | `--ask-for-approval` | Approval policy: `untrusted`, `on-request`, `never`. (`on-failure` is DEPRECATED — use `on-request` for interactive runs or `never` for non-interactive runs.) | varies |
| `--json` | — | Output JSONL events (`thread.started`, `turn.started`, `item.completed`, `turn.completed`) | Off |
| `-o <file>` | `--output-last-message` | Write assistant's final message to file | — |
| `--output-schema <file>` | — | Path to a JSON Schema file describing the model's final response shape | — |
| `--ephemeral` | — | Don't persist session to disk | Off (sessions persist) |
| `-s <mode>` | `--sandbox` | Sandbox policy: `read-only`, `workspace-write`, `danger-full-access` | `workspace-write` |
| `-c key=value` | `--config` | Override a config value (TOML); supports dotted paths like `shell_environment_policy.inherit=all` | — |
| `--enable <FEATURE>` | — | Enable a feature flag (repeatable). Equivalent to `-c features.<name>=true` | — |
| `--disable <FEATURE>` | — | Disable a feature flag (repeatable). Equivalent to `-c features.<name>=false` | — |
| `-m <name>` | `--model` | Model to use | Depends on user config |
| `--oss` | — | Convenience flag selecting the local open-source model provider; verifies a local LM Studio or Ollama server is running | Off |
| `--local-provider <provider>` | — | When using `--oss`, pin the local provider to `lmstudio` or `ollama` | Auto |
| `-i <file>` | `--image` | Attach image(s) to the initial prompt (repeatable) | — |
| `-p <profile>` | `--profile` | Configuration profile from `config.toml` to specify default options | — |
| `-C <dir>` | `--cd` | Tell the agent to use the specified directory as its working root | cwd |
| `--add-dir <dir>` | — | Additional directories that should be writable alongside the primary workspace | — |
| `--skip-git-repo-check` | — | Allow running Codex outside a Git repository | Off |
| `--search` | — | Enable live web search via the native Responses `web_search` tool (no per-call approval) | Off |
| `--no-alt-screen` | — | Run TUI in inline mode, preserving terminal scrollback. Useful in Zellij and other strict xterm-spec multiplexers. | Off |
| `-` | — | Read prompt from stdin (when used as PROMPT positional arg) | — |

## Resume Flags

| Command | Description |
|---------|-------------|
| `codex exec resume --last` | Resume the most recent session in non-interactive exec mode |
| `codex exec resume <SESSION_ID>` | Resume a specific session id (UUID or thread name) |
| `codex exec resume <SESSION_ID> -` | Resume and read the follow-up prompt from stdin |

For interactive resume (TUI launches), use top-level `codex resume` instead. See [subcommands.md](subcommands.md#critical-resume-vs-exec-resume) for the distinction.

## Sandbox Modes

| Mode | Flag | Read Files | Write Files | Execute Commands | System Access |
|------|------|------------|-------------|------------------|---------------|
| Read-only | `-s read-only` | Yes | No | No | No |
| Workspace-write | `-s workspace-write` | Yes | Project only | Limited | No |
| Full access | `-s danger-full-access` | Yes | Yes | Yes | Yes |

## Full Autonomy Requirements (v0.20+)

For complete non-interactive automation without any prompts, all conditions must be met:

```bash
codex exec "task" \
  --full-auto \
  --dangerously-bypass-approvals-and-sandbox
```

Plus the workspace must be marked as trusted. Without all conditions, approval prompts may still appear.

## Flag Interactions

| Combination | Behavior |
|-------------|----------|
| `--json` + `-o file` | JSON to stdout, final message to file |
| `--full-auto` + `-s read-only` | Read-only overrides full-auto's workspace-write default |
| `--ephemeral` + `resume` | Error — can't resume an ephemeral session |
| `-o file` + `resume --last` | Writes the resumed session's final message |

## Config Overrides

```bash
# Override model for a single run
codex exec -m o3 "Use o3 for this"

# Config override syntax (alternative to -m flag)
codex exec -c model="o3" "Use o3 for this"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| Non-zero | Error (check stderr for details) |
