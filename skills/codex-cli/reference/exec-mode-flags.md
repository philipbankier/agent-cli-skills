# Codex CLI Exec Mode Flags

Complete reference for `codex exec` (alias: `codex e`) non-interactive mode flags.
Last verified against `codex exec --help` for **Codex CLI v0.130.0** on 2026-05-17.

For all other subcommands (`codex sandbox`, `codex cloud`, `codex apply`, `codex fork`,
`codex resume`, `codex features`, etc.), see [subcommands.md](subcommands.md).

> `codex exec --full-auto` is still accepted in v0.130, but it is no longer
> listed in `codex exec --help` and prints a deprecation warning. Prefer explicit
> `--sandbox workspace-write` in new scripts.

## Core Flags

| Flag | Short / alias | Description | Default |
|------|--------------|-------------|---------|
| `--dangerously-bypass-approvals-and-sandbox` | — | Skip all approvals and sandboxing — only safe in externally-sandboxed environments | Off |
| `--json` | — | Output JSONL events (`thread.started`, `turn.started`, `item.*`, `turn.completed`, `turn.failed`, `error`) | Off |
| `-o <file>` | `--output-last-message` | Write assistant's final message to file | — |
| `--output-schema <file>` | — | Path to a JSON Schema file describing the model's final response shape | — |
| `--ephemeral` | — | Don't persist session to disk | Off (sessions persist) |
| `-s <mode>` | `--sandbox` | Sandbox policy: `read-only`, `workspace-write`, `danger-full-access` | Depends on CLI version and user config; set explicitly |
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
| `--ignore-user-config` | — | Do not load `$CODEX_HOME/config.toml`; auth still uses `CODEX_HOME` | Off |
| `--ignore-rules` | — | Do not load user or project execpolicy `.rules` files | Off |
| `--color <mode>` | — | `always`, `never`, or `auto` | `auto` |
| `-` | — | Read prompt from stdin when used as the only PROMPT positional arg. If a prompt is provided and stdin is piped, stdin is appended as `<stdin>` without needing `-`. | — |

Top-level `codex --help` still exposes `-a/--ask-for-approval`, `--search`, and
`--no-alt-screen`, but they were not listed under `codex exec --help` in v0.130.
Use `codex exec --help` as the source of truth for exec-only scripts.

OpenAI's current docs state `codex exec` defaults to a read-only sandbox, but
local user config can override the effective runtime mode. Automation should set
`--sandbox` explicitly.

## Resume Flags

| Command | Description |
|---------|-------------|
| `codex exec resume --last` | Resume the most recent session in non-interactive exec mode |
| `codex exec resume <SESSION_ID>` | Resume a specific session id (UUID or thread name) |
| `codex exec resume <SESSION_ID> -` | Resume and read the follow-up prompt from stdin |

When combining parent `exec` options with resume, put parent options before the
`resume` subcommand:

```bash
codex exec --sandbox read-only resume --last "Continue the previous analysis"
```

Local negative test:

```bash
codex exec resume --last "Continue" --sandbox read-only
# error: unexpected argument '--sandbox' found
```

For interactive resume (TUI launches), use top-level `codex resume` instead. See [subcommands.md](subcommands.md#critical-resume-vs-exec-resume) for the distinction.

## Sandbox Modes

| Mode | Flag | Read Files | Write Files | Execute Commands | System Access |
|------|------|------------|-------------|------------------|---------------|
| Read-only | `-s read-only` | Yes | No | No | No |
| Workspace-write | `-s workspace-write` | Yes | Project only | Limited | No |
| Full access | `-s danger-full-access` | Yes | Yes | Yes | Yes |

## Automation and Autonomy

Prefer explicit sandbox mode:

```bash
codex exec "task" --sandbox workspace-write
```

For complete autonomy with no approvals and no sandbox, use only in an externally
isolated environment:

```bash
codex exec "task" --dangerously-bypass-approvals-and-sandbox
```

Deprecated compatibility path:

```bash
codex exec "task" --full-auto
# warning: --full-auto is deprecated; use --sandbox workspace-write instead.
```

## Flag Interactions

| Combination | Behavior |
|-------------|----------|
| `--json` + `-o file` | JSONL events to stdout, final message to file |
| `-o file` without `--json` | Final message is written to file and still printed to stdout |
| Piped stdin + prompt arg | Prompt is used and stdin is appended as a `<stdin>` block |
| Prompt arg + trailing `-` | Fails in v0.130 with "unexpected argument '-'" |
| `--full-auto` | Still works, but emits a deprecation warning |
| `-o file` + `resume --last` | Writes the resumed session's final message |
| `codex exec --ephemeral resume ...` | Upstream issue reports resume may still persist rollout data; verify before relying on it |

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
