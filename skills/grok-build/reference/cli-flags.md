> Part of the [grok-build skill](../SKILL.md).

# Grok Build CLI Flags

Complete reference for the verified headless subset of `grok`.
Last verified against `grok --help` for **Grok Build 0.1.211 (2f2cd6d5c2)** on 2026-05-17.

Official xAI docs were checked on 2026-05-17:

- <https://docs.x.ai/build/overview>
- <https://docs.x.ai/build/cli/headless-scripting>
- <https://docs.x.ai/build/modes-and-commands>

## Verified Headless Flags

| Flag | Short / alias | Description | Local verification |
|---|---|---|---|
| `--single <PROMPT>` | `-p` | Send one prompt and exit | Passed with `plain`, `json`, `streaming-json` |
| `--output-format <FMT>` | - | `plain`, `json`, or `streaming-json` | All three passed |
| `--prompt-file <PATH>` | - | Read prompt from a file | Passed with JSON output |
| `--prompt-json <JSON>` | - | Read structured prompt JSON | Passed for an array of text blocks |
| `--resume <SESSION_ID>` | `-r` | Resume an existing session | Passed with actual JSON `sessionId` |
| `--continue` | `-c` | Continue the most recent session in the current directory | Passed after a remembered-word setup |
| `--cwd <PATH>` | - | Set working directory | Help-exposed; `grok inspect` confirmed cwd metadata |
| `--disable-web-search` | - | Disable web search | Used in all deterministic smoke tests |
| `--no-plan` | - | Skip planning behavior | Used in one-shot smoke tests |
| `--max-turns <N>` | - | Bound the turn budget | `10` worked for trivial smoke tests |
| `--always-approve` | - | Auto-approve tool executions | Official docs confirm; not used for write smoke tests |
| `--model <MODEL>` | `-m` | Select model | `grok models` showed `grok-build` as default |

## Session Flags

The safest verified script path is:

```bash
session_id=$(
  grok -p "Remember the word BRAVO. Reply with exactly stored." \
    --output-format json \
    --disable-web-search \
    --no-plan \
    --max-turns 10 |
    jq -r '.sessionId'
)

grok -p "What word did I ask you to remember? Reply with just the word." \
  --resume "$session_id" \
  --output-format plain \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Local result: `BRAVO`.

xAI docs also list `--session-id <ID>` for named headless sessions. The installed
CLI accepted the flag, but local named-session resume did not behave consistently.
Do not build public automation on named `--session-id` until you verify it locally.

## Prompt JSON

Verified:

```bash
grok --prompt-json '[{"type":"text","text":"Reply with exactly OK"}]' \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Failed locally:

```bash
grok --prompt-json '{"type":"text","text":"Reply with exactly OK"}'
grok --prompt-json '{"content":[{"type":"text","text":"Reply with exactly OK"}]}'
```

The second failure reported that JSON objects need a `type` field, which suggests
there are ACP-shaped object forms, but the array-of-content-blocks form is the
only one verified here.

## Help-Exposed Advanced Flags

These appeared in `grok --help` locally, but were not fully workflow-verified:

| Flag | Notes |
|---|---|
| `--best-of-n <N>` | Passed at `--max-turns 20`, failed at 10. It fans out candidates. |
| `--check` | Produced cancelled output in one smoke test; do not use as a cheap CI check yet. |
| `--agents` / `--agent` | Help-exposed for subagent/agent profiles; not smoke-tested. |
| `--permission-mode <MODE>` | Values included `default`, `acceptEdits`, `auto`, `dontAsk`, `bypassPermissions`, `plan`; plan mode produced a plan. |
| `--worktree` | Help-exposed; not smoke-tested. |
| `--sandbox <PROFILE>` | Help-exposed; read-only write probe did not create the file but returned cancelled output, so behavior needs deeper verification. |
| `--tools`, `--allow`, `--deny`, `--disallowed-tools` | Tool gating surface; not smoke-tested. |
| `--experimental-memory`, `--no-memory` | Memory surface; not smoke-tested beyond help. |
| `--system-prompt-override` | Help-exposed; not smoke-tested. |
| `--restore-code`, `--verbatim`, `--oauth` | Help-exposed; not smoke-tested. |

## Practical Defaults for Scripts

Use these for deterministic smoke tests:

```bash
grok -p "Reply with exactly OK" \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Before running a larger task:

```bash
grok inspect
grok models
```

`grok inspect` is important because Grok may load config, instructions, skills,
plugins, hooks, and MCP servers from `.grok`, `~/.grok`, and Claude-compatible
locations.
