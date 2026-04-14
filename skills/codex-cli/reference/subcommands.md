> Part of the [codex-cli skill](../SKILL.md).

# Codex CLI Subcommand Reference

Complete subcommand tree for `codex` and `codex exec`.
Last verified against `codex --help` and per-subcommand `--help` for **Codex CLI v0.114.0** on 2026-04-14.
Upstream is currently v0.120.0; subcommands added in v0.115–v0.120 are tracked in [changelog.md](changelog.md) (created in a later commit).

## Subcommand Tree

```
codex [OPTIONS] [PROMPT]                           # interactive TUI
codex [OPTIONS] <COMMAND> [ARGS]                   # subcommand mode
│
├── exec, e                  Run Codex non-interactively
│   ├── resume               Resume a previous exec-mode session
│   └── review               Run a code review against the current repository
├── review                   Run a code review non-interactively (TOP-LEVEL alias)
├── login                    Manage login (start OAuth flow)
├── logout                   Remove stored authentication credentials
├── mcp                      Manage external MCP servers for Codex
├── mcp-server               Start Codex itself as an MCP server (stdio)
├── app-server  [experimental]  Run the app server / generate protocol bindings
│   ├── generate-ts          Generate TypeScript bindings for the app server protocol
│   └── generate-json-schema Generate JSON Schema for the app server protocol
├── app                      Launch the Codex desktop app (downloads installer if missing)
├── completion               Generate shell completion scripts
├── sandbox                  Run commands within a Codex-provided OS sandbox
│   ├── macos, seatbelt      Run a command under macOS Seatbelt
│   ├── linux, landlock      Run a command under Linux Landlock+seccomp
│   └── windows              Run a command under Windows restricted token
├── debug                    Debugging tools
│   └── app-server           Tooling: helps debug the app server
├── apply, a <TASK_ID>       Apply latest diff produced by Codex agent as `git apply`
├── resume [SESSION_ID]      Resume a previous interactive session (picker by default; --last for most recent)
├── fork [SESSION_ID]        Fork a previous interactive session (picker by default; --last for most recent)
├── cloud  [EXPERIMENTAL]    Browse Codex Cloud tasks and apply changes locally
│   ├── exec                 Submit a new Codex Cloud task without launching the TUI
│   ├── status               Show the status of a Codex Cloud task
│   ├── list                 List Codex Cloud tasks
│   ├── apply                Apply the diff for a Codex Cloud task locally
│   └── diff                 Show the unified diff for a Codex Cloud task
└── features                 Inspect feature flags
    ├── list                 List known features with their stage and effective state
    ├── enable               Enable a feature in config.toml
    └── disable              Disable a feature in config.toml
```

---

## Critical: `resume` vs `exec resume`

Both top-level `codex resume` and `codex exec resume` exist. They are **different commands**, not aliases:

| | `codex resume` | `codex exec resume` |
|--|----------------|---------------------|
| Mode | Interactive TUI launches | Non-interactive, exec mode |
| When to use | A human is at the terminal continuing work | An automation script is continuing a prior step |
| `[PROMPT]` arg | Optional, becomes the next interactive turn | The follow-up prompt to send |
| Picker behavior | Default opens session picker if no SESSION_ID | Same |
| Stdin | TUI takes over | Standard exec stdin handling |

Use the form that matches the context. The `--last` flag works for both.

---

## `codex exec`

Already documented in detail in [exec-mode-flags.md](exec-mode-flags.md). Aliases: `codex e`. Subcommands (under `codex exec`):

- `codex exec resume [SESSION_ID] [PROMPT]` — non-interactive resume of a previous session. If `[PROMPT]` is `-`, read from stdin.
- `codex exec review [PROMPT]` — run a code review in exec mode. Same as the top-level `codex review`, but lives under exec for discoverability.

---

## `codex review`

Run a code review non-interactively against the current repository. Convenience for CI gates.

```bash
codex review                           # default review prompt
codex review "Focus on security issues and SQL injection risks"
echo "Review only changed files" | codex review -
```

If `[PROMPT]` is `-`, read instructions from stdin.

---

## `codex login` / `codex logout`

```bash
codex login          # start OAuth flow against ChatGPT account
codex logout         # remove stored credentials
```

For CI/CD use `OPENAI_API_KEY` instead of `codex login`. The two auth paths bill to different accounts (ChatGPT subscription vs OpenAI Platform).

---

## `codex mcp` and `codex mcp-server`

Two distinct things:

```bash
codex mcp                # manage external MCP servers Codex consumes
codex mcp-server         # start Codex itself as an MCP server (stdio transport)
```

- `codex mcp` is the equivalent of `claude mcp` — register and manage MCP servers that Codex can call out to.
- `codex mcp-server` exposes Codex *to* other MCP clients. This is how you use Codex as a tool from another agent (e.g., let Claude Code drive Codex via MCP).

---

## `codex sandbox` — OS-level sandboxing

Run an arbitrary command under the same OS sandbox Codex uses internally. This is **separate** from the in-CLI `--sandbox {read-only|workspace-write|danger-full-access}` permission policy that `codex exec` uses; this subcommand applies the actual OS isolation primitives directly.

```bash
# macOS — Seatbelt sandbox profile
codex sandbox macos -- npm test
codex sandbox seatbelt -- ./build.sh        # alias

# Linux — Landlock + seccomp
codex sandbox linux -- python -m pytest
codex sandbox landlock -- ./build.sh        # alias

# Windows — restricted token
codex sandbox windows -- npm test
```

Use this when you want to:
- Execute *any* command (not just a Codex agent run) under the same sandbox Codex would use
- Verify a build script is sandbox-safe before letting an agent run it
- Wrap a shell tool in a sandbox boundary as part of a CI step

This is the closest thing in the CLI agent ecosystem to a portable "OS-sandbox a process" command — Claude Code and Gemini CLI rely on permission-mode gating instead.

---

## `codex debug`

Debugging tools subcommand. Currently has one child:

```bash
codex debug app-server          # tooling that helps debug the app server
```

Use when an `app-server` integration is misbehaving. Not for general agent debugging.

---

## `codex apply <TASK_ID>` (alias `codex a`)

Apply the latest diff produced by a Codex agent as a `git apply` to your local working tree.

```bash
codex apply abc123                # apply task abc123's diff
codex a abc123                    # alias
```

Use after a Codex agent has produced a diff that you want to materialize on disk locally — common pattern with `codex cloud exec` (run remotely, apply locally).

---

## `codex resume` (TOP-LEVEL)

Resume a previous **interactive** session. Picker by default, `--last` for most recent.

```bash
codex resume                          # picker over recent sessions in this directory
codex resume --last                   # jump straight into the most recent
codex resume --last "follow-up"       # resume with an opening prompt
codex resume <uuid>                   # resume a specific session id
codex resume <thread-name>            # resume by thread name (UUIDs take precedence if it parses)
```

> `[SESSION_ID]` accepts either a UUID or a human-readable thread name. UUIDs win on ambiguity. Sessions are scoped to the working directory — `cd` between runs changes which session is "last".

For non-interactive automation use `codex exec resume` instead.

---

## `codex fork`

Fork a previous interactive session into a new branch. Like `resume`, but instead of continuing the original session, it creates a copy you can diverge from. Original session is left untouched.

```bash
codex fork                            # picker
codex fork --last                     # fork the most recent
codex fork --last "try a different approach"
codex fork <session-id>
```

Use when you want to explore an alternative path from a known-good state without losing the original.

---

## `codex cloud` [EXPERIMENTAL]

Browse and apply Codex Cloud tasks locally. Codex Cloud runs tasks on remote infrastructure; this subcommand brings the results back to your machine.

```bash
codex cloud list                  # list your tasks
codex cloud status <task-id>      # check task progress
codex cloud exec "task prompt"    # submit a new task without launching the TUI
codex cloud diff <task-id>        # show the unified diff for a task
codex cloud apply <task-id>       # apply the diff locally (same effect as `codex apply`)
```

Marked experimental in `--help`; the surface may change. Useful when you want a long-running agent task to execute in the cloud and pull only the resulting diff back to your machine.

---

## `codex features`

Inspect and toggle feature flags persisted in `~/.codex/config.toml`.

```bash
codex features list                # show known features, their stage, and effective state
codex features enable <name>       # enable a feature in config.toml
codex features disable <name>      # disable a feature in config.toml
```

You can also flip features per-invocation without writing to disk via `--enable <name>` / `--disable <name>` on any `codex` or `codex exec` call — these flags are equivalent to `-c features.<name>=true` / `=false`.

---

## `codex app` and `codex app-server`

```bash
codex app                                    # launch the Codex desktop app (default workspace = .)
codex app /path/to/workspace                 # launch with a specific workspace path
codex app-server                             # [experimental] run the app server / related tooling
codex app-server generate-ts                 # generate TypeScript bindings for the app server protocol
codex app-server generate-json-schema        # generate JSON Schema for the app server protocol
```

`codex app` downloads the macOS installer the first time you call it on a Mac. `codex app-server` is the experimental backend that the desktop app and other clients can talk to.

---

## `codex completion`

Generate shell completion scripts.

```bash
codex completion bash > /etc/bash_completion.d/codex
codex completion zsh > "${fpath[1]}/_codex"
codex completion fish > ~/.config/fish/completions/codex.fish
```

Run once after install. Useful since the subcommand surface is wide and growing.

---

## See Also

- [exec-mode-flags.md](exec-mode-flags.md) — full flag reference for `codex exec`
- [json-output.md](json-output.md) — `--json` event types
- [code-snippets.md](code-snippets.md) — copy-paste recipes
- [../guides/session-management.md](../guides/session-management.md) — multi-step `codex exec resume` workflows
- [../guides/agents-md.md](../guides/agents-md.md) — `AGENTS.md` configuration
