# Codex CLI Exec Mode Flags

Complete reference for `codex exec` (alias: `codex e`) non-interactive mode flags.

## Core Flags

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `--full-auto` | — | Automation preset: workspace-write sandbox + on-request approvals | Off |
| `--dangerously-bypass-approvals-and-sandbox` | `--yolo` | Skip all approvals and sandboxing | Off |
| `--json` | — | Output newline-delimited JSON events | Off |
| `--experimental-json` | — | Richer JSON output (unstable, may change) | Off |
| `-o <file>` | `--output-last-message` | Write assistant's final message to file | — |
| `--output-schema <schema>` | — | Validate tool output against JSON Schema | — |
| `--ephemeral` | — | Don't persist session to disk | Off (sessions persist) |
| `-s <mode>` | `--sandbox` | Sandbox policy: `read-only`, `workspace-write`, `danger-full-access` | `workspace-write` |
| `-c key=value` | — | Global config override | — |
| `--model <name>` | — | Model to use | o4-mini |
| `-` | — | Read prompt from stdin | — |

## Resume Flags

| Command | Description |
|---------|-------------|
| `codex exec resume --last` | Resume the most recent session |
| `codex exec resume --all` | List all sessions, pick one to resume |

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
| `--json` + `--experimental-json` | `--experimental-json` takes precedence |
| `-o file` + `resume --last` | Writes the resumed session's final message |

## Config Overrides

```bash
# Override model for a single run
codex exec -c model=gpt-4.1 "Use GPT-4.1 for this"

# Multiple overrides
codex exec -c model=gpt-4.1 -c temperature=0 "Deterministic output"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| Non-zero | Error (check stderr for details) |
