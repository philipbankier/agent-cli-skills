# OS-Level Sandboxing vs CLI Permission Gating

How each CLI isolates agent-executed commands from your system, and when each level of isolation is appropriate.
Verified against Claude Code v2.1.104, Codex CLI v0.114.0, Gemini CLI v0.33.0 on 2026-04-14.

## Two Layers, Often Confused

CLI agents have two *separate* mechanisms for restricting what they can do:

1. **In-CLI permission gating** — the CLI itself decides whether to invoke a tool/command, based on configured policy
2. **OS-level sandboxing** — the operating system enforces a hard wall around the process so even if the CLI tries to execute something, the kernel refuses

These are different. In-CLI gating relies on the CLI being well-behaved. OS-level sandboxing doesn't trust the CLI at all.

| | In-CLI gating | OS-level sandbox |
|--|---------------|------------------|
| What it protects against | Accidental or unintended tool calls | Malicious or runaway code execution, even if the CLI itself is compromised |
| Trust assumption | The CLI faithfully checks policy before acting | None — the OS enforces |
| Performance cost | Negligible | Some — process startup includes sandbox setup |
| When it's enough | Local dev, semi-trusted automation | Untrusted workloads, multi-tenant environments, true CI sandboxes |

## What Each CLI Provides

### Claude Code: in-CLI gating only

Claude Code's permission system lives entirely inside the CLI process. The relevant knobs:

| Flag / mode | Behavior |
|------------|----------|
| `--permission-mode default` | Prompt for approval on writes/executions |
| `--permission-mode acceptEdits` | Auto-approve edits, prompt for everything else |
| `--permission-mode dontAsk` | Suppress permission prompts (the agent uses tools but you don't see prompts) |
| `--permission-mode plan` | Read-only — agent describes what it would do, doesn't execute |
| `--permission-mode bypassPermissions` | Skip all permission checks |
| `--permission-mode auto` | Auto mode classifier picks per-action |
| `--dangerously-skip-permissions` | Equivalent to `bypassPermissions` |
| `--allow-dangerously-skip-permissions` | Make the bypass an *option* without enabling it by default |
| `--allowedTools "Bash(git:*) Edit"` | Pattern-based allowlist |
| `--disallowedTools "Write,Edit"` | Explicit denylist |
| `--tools ""` | Disable all tools (pure LLM, no execution) |

> **Important:** all of these are enforced *by* `claude` itself. If the binary is running, you trust it to check policy. There is no Claude-Code-native OS sandbox. Run `claude` itself inside a container/VM/jail if you need OS-level isolation.

> **`--dangerously-skip-permissions` cascade caveat:** when you enable it, behaviors that spawn subagents inherit the bypass. Combined with `--permission-mode plan`, the bypass silently overrides plan mode. See the Critical Gotchas section in [skills/claude-code/SKILL.md](../../skills/claude-code/SKILL.md) for the safety implications.

### Codex CLI: BOTH in-CLI gating AND OS-level sandbox

Codex is the only one of the three with native OS-level sandboxing.

**In-CLI gating** lives on `codex exec`:

| Flag / value | Behavior |
|------------|----------|
| `-s read-only` (`--sandbox read-only`) | Read-only mode |
| `-s workspace-write` (default) | Read all, write to project only |
| `-s danger-full-access` | No sandbox, full access |
| `-a untrusted` (`--ask-for-approval`) | Run only "trusted" commands without asking |
| `-a on-request` | Model decides when to ask |
| `-a never` | Never ask for approval |
| `--full-auto` | Convenience for `-a on-request --sandbox workspace-write` |
| `--dangerously-bypass-approvals-and-sandbox` | Skip all approvals AND sandbox |

**OS-level sandbox** is its own top-level subcommand: `codex sandbox`.

```bash
# macOS — Apple Seatbelt sandbox profile
codex sandbox macos -- npm test
codex sandbox seatbelt -- ./build.sh         # alias for macos

# Linux — Landlock + seccomp
codex sandbox linux -- python -m pytest
codex sandbox landlock -- ./build.sh         # alias for linux

# Windows — restricted token
codex sandbox windows -- npm test
```

This is **not** the same as `codex exec --sandbox`. The `codex sandbox <os>` subcommand wraps an arbitrary command in the same OS isolation primitives Codex uses internally, *whether or not Codex itself is involved*. You can use it to:

- Test that a build script is sandbox-safe before letting an agent run it
- Wrap third-party commands in a sandbox boundary as part of a CI step
- Run a Codex agent under explicit OS-level sandboxing: `codex sandbox linux -- codex exec --full-auto "..."`

This is the closest portable "sandbox a process" command in the CLI agent ecosystem.

### Gemini CLI: in-CLI gating + `--sandbox` flag

Gemini has its own approval system and a `--sandbox` flag, but the underlying isolation mechanism is less explicit than Codex's.

| Flag / value | Behavior |
|------------|----------|
| `-s` / `--sandbox` | Run in sandbox (boolean) |
| `-y` / `--yolo` | Auto-approve all actions |
| `--approval-mode default` | Prompt for approval (default) |
| `--approval-mode auto_edit` | Auto-approve edit tools, prompt for everything else |
| `--approval-mode yolo` | Equivalent to `-y` |
| `--approval-mode plan` | Read-only mode |
| `--policy <files>` | Additional policy files to load |
| `--allowed-tools <list>` | DEPRECATED — use Policy Engine instead |
| `--allowed-mcp-server-names <list>` | Restrict which MCP servers can be reached |

`gemini -s` enables sandbox mode but the documentation around what *kind* of sandbox is sparse. For high-trust isolation, prefer `codex sandbox <os>` or run `gemini` itself inside a container.

## Pick-Your-Tool Decision Tree

```
Need to run agent-driven code on this machine?
│
├── It's a local dev environment, you trust the prompt source
│   └── Any CLI's in-CLI gating is fine
│       (Claude --permission-mode default, Codex --full-auto, Gemini --approval-mode default)
│
├── It's CI, you trust the prompt source but want hard caps
│   └── Any CLI with --print + ephemeral + plan mode for read-only steps
│       Pair with --max-budget-usd (Claude only) for spend cap
│
├── It's CI, you may not fully trust the prompt source
│   └── Codex CLI + `codex sandbox <os>` wrapping the agent invocation
│       Or run any CLI inside a container / VM you control
│
├── It's a multi-tenant service, untrusted callers
│   └── Container / VM around the entire CLI process. CLI-level gating
│       is necessary but not sufficient. Codex's sandbox subcommand can
│       be used as one layer inside the container as defense in depth.
│
└── It's a one-shot read-only audit
    ├── Claude Code: --permission-mode plan
    ├── Codex CLI: -s read-only
    └── Gemini CLI: --approval-mode plan
```

## Recipe: Codex agent inside its own OS sandbox

```bash
# Codex exec wrapped in Linux landlock+seccomp via the codex sandbox subcommand
codex sandbox linux -- \
  codex exec --full-auto --json --ephemeral \
    "Run the test suite and summarize failures"
```

This composes two layers:

1. The outer `codex sandbox linux` enforces OS isolation around the entire process tree
2. The inner `codex exec --full-auto` is the agent run; it does its own in-CLI gating *inside* the sandbox

If the agent inside ever decides to do something destructive, the kernel still refuses because the outer sandbox is in effect.

## Recipe: Read-only multi-CLI audit

For "look at this code but never modify anything" tasks, all three CLIs have a read-only mode:

```bash
# Claude Code
claude -p "Audit auth/ for security issues" --permission-mode plan --tools "" -p

# Codex CLI
codex exec --sandbox read-only "Audit auth/ for security issues"

# Gemini CLI
gemini -p "Audit auth/ for security issues" --approval-mode plan
```

These are all *in-CLI* read-only. None of them prevent the binary itself from being malicious; they prevent the *agent* from invoking write/execute tools.

## Common Mistakes

- **Trusting `--dangerously-skip-permissions` in production CI** — even if you trust your prompts, it bypasses safety checks across subagents in ways that can surprise you. Prefer `--permission-mode plan` or run inside a container.
- **Confusing `codex exec --sandbox` with `codex sandbox <os>`** — they're different mechanisms at different layers. Use `--sandbox` for in-CLI policy on a Codex agent run; use `codex sandbox <os>` to wrap any command in OS-level isolation.
- **Assuming Gemini's `--sandbox` is equivalent to Codex's sandbox subcommand** — Gemini's `-s` is closer to "enable safer mode" than to a hard OS-level wall. For untrusted workloads, prefer Codex's OS sandbox or a real container.
- **Forgetting that read-only ≠ free** — read-only mode still makes API calls and still costs money. Pair with `--max-budget-usd` (Claude only) or external accounting if you care about cost ceilings.

## See Also

- [subagent-orchestration.md](subagent-orchestration.md) — when you need parallel agents and want each in its own sandbox
- [cost-control.md](cost-control.md) — bounding spend on read-only audits
- [../../skills/codex-cli/reference/subcommands.md](../../skills/codex-cli/reference/subcommands.md) — full `codex sandbox` and `codex exec --sandbox` reference
- [../../skills/claude-code/reference/print-mode-flags.md](../../skills/claude-code/reference/print-mode-flags.md) — Claude Code permission modes and tool gating flags
