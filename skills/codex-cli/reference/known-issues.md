> Part of the [codex-cli skill](../SKILL.md).

# Codex CLI: Verified Known Issues

A curated list of confirmed-real Codex CLI issues with reproducible workarounds.

> **Verification policy:** Every entry on this page links to a real GitHub issue,
> official doc, or local CLI behavior confirmed on 2026-05-17. Entries marked
> `TODO(verify)` are research leads that need further reproduction before
> they're documented in detail. Treat workarounds as starting points, not
> finished playbooks. Verify against the issue's current state first.

---

## `--full-auto` is deprecated for exec-mode automation

- **Source:** local `codex exec --full-auto` smoke test and OpenAI non-interactive docs, verified locally on v0.130.0
- **Severity:** Medium - still works, but new scripts should not depend on it

**What's documented:** OpenAI's current non-interactive docs say
`codex exec --full-auto` is deprecated compatibility and recommend explicit
`--sandbox workspace-write`. Local v0.130 still accepts `--full-auto`, but stderr
prints: `warning: --full-auto is deprecated; use --sandbox workspace-write instead.`

**Workaround:** Migrate scripts to explicit sandbox flags:

```bash
codex exec "task" --sandbox workspace-write
```

Use `--dangerously-bypass-approvals-and-sandbox` only inside an external sandbox.

---

## `codex sandbox <os>` and `codex exec --sandbox` are different mechanisms

- **Source:** `codex sandbox --help` and `codex exec --help` (verified locally on v0.130.0)
- **Severity:** Medium — frequently confused

**What's documented:** `codex sandbox macos|linux|windows` is a top-level subcommand that wraps an arbitrary command in OS-level isolation (Seatbelt / Landlock+seccomp / Windows restricted token). `codex exec --sandbox {read-only|workspace-write|danger-full-access}` is an in-CLI policy on a Codex agent run. They are separate mechanisms — different layers of trust, different threat models.

**Workaround:** When you want OS-level isolation around any command (not just an agent run), use `codex sandbox <os> -- <command>`. When you want in-CLI permission policy on a Codex agent specifically, use `codex exec --sandbox <mode>`. To compose both, run `codex sandbox linux -- codex exec --sandbox workspace-write "..."`. See [`cross-platform/patterns/os-sandboxing.md`](../../../cross-platform/patterns/os-sandboxing.md) for the full discussion.

---

## `codex resume` and `codex exec resume` are different commands

- **Source:** `codex resume --help` and `codex exec resume --help` (verified locally on v0.130.0)
- **Severity:** Medium — used to be documented incorrectly across this repo

**What's documented:** `codex resume [SESSION_ID] [PROMPT]` resumes a previous **interactive** session — the TUI launches. `codex exec resume [SESSION_ID] [PROMPT]` resumes a previous **non-interactive** exec-mode session. Both accept `--last` to skip the picker. They are not aliases.

**Workaround:** Use the form that matches your context — interactive for TUI work, exec for scripts. Sessions are scoped to the working directory, so `cd` between calls changes which one is "last."

---

## `codex exec resume` parent options must come before `resume`

- **Source:** local v0.130.0 negative and positive tests
- **Severity:** Low to medium - easy to hit in scripts

**Observed locally:** This failed:

```bash
codex exec resume --last "What word?" --sandbox read-only
```

This worked:

```bash
codex exec --sandbox read-only resume --last "What word?"
```

**Workaround:** Put parent `exec` flags before the `resume` subcommand.

---

## Piped stdin no longer needs `codex exec - "prompt"`

- **Source:** local v0.130.0 stdin tests and `codex exec --help`
- **Severity:** Medium - old examples now fail

**Observed locally:** `printf 'one\ntwo\nthree\n' | codex exec "Count the input lines."`
worked and the model answered `3`. The old pattern
`printf ... | codex exec "Count..." -` failed with `unexpected argument '-' found`.

**Workaround:** Pipe stdin directly when you already pass a prompt:

```bash
cat file.py | codex exec "Summarize stdin"
```

Use `codex exec -` only when stdin is the prompt itself.

---

## `codex exec resume --output-schema` is not available

- **Source:** <https://github.com/openai/codex/issues/22998>, open on 2026-05-17
- **Severity:** Medium for structured multi-step scripts

**What's reported:** `codex exec` supports `--output-schema`, but
`codex exec resume --help` does not list it. The upstream feature request asks
for resume parity.

**Workaround:** Use `--output-schema` on the first exec step when possible, or
resume with `-o` and validate the final file with `jq`/JSON Schema in your own
script.

---

## `codex exec --ephemeral resume` may still persist rollout data

- **Source:** <https://github.com/openai/codex/issues/20084>, open on 2026-05-17
- **Severity:** Medium for privacy-sensitive resume workflows

**What's reported:** The issue reports that `codex exec --ephemeral resume <id>`
can still append resumed turns to existing rollout files.

**Workaround:** Treat `--ephemeral` resume as unverified. For sensitive data,
avoid resume or test the exact storage path before relying on it.

---

## MCP helpers can add noise or hang risk in exec/resume workflows

- **Sources:** <https://github.com/openai/codex/issues/14470> and <https://github.com/openai/codex/issues/21984>, open on 2026-05-17
- **Severity:** Medium

**What's reported:** One issue reports `codex exec --json resume` hanging after
MCP helpers start on macOS. Another reports configured MCP servers eagerly
starting per session and accumulating headed browser processes.

**Workaround:** For deterministic automation, prefer a minimal config profile or
`--ignore-user-config --ignore-rules` when your task does not need configured
MCP servers. Local smoke tests showed this avoided user-config auth errors,
though bundled plugin warnings can still appear.

---

## Current issue queue shows active app/server/session churn

- **Source:** `gh issue list -R openai/codex` and GitHub release metadata, verified on 2026-05-17
- **Severity:** varies

**What's reported:** Recent open issues include app-server, remote-control,
session, `/goal`, Windows sandbox, and desktop app regressions. Stable npm was
`0.130.0`; alpha was `0.131.0-alpha.22`.

**Workaround:** For automation, pin stable `@openai/codex@0.130.0` or the exact
version you verify. Treat alpha releases as moving targets.

---

## TODO: research leads from community discussion

These items came from community research and need first-hand reproduction before being documented in detail:

- TODO(verify): `codex remote-control` behavior and auth token handling.
- TODO(verify): `exec-server` standalone service behavior.
- TODO(verify): `/goal` interaction with inherited approval policy, tracked by <https://github.com/openai/codex/issues/22362>.
- TODO(verify): Full Access `/goal` sandbox fallback behavior, tracked by <https://github.com/openai/codex/issues/23105>.

---

## How to add an entry

Same rules as [the Claude Code known-issues file](../../claude-code/reference/known-issues.md#how-to-add-an-entry-to-this-file): link to a real verifiable source, quote titles exactly, describe upstream-reported behavior (not your theory), keep workarounds testable, and mark unverifiable items as `TODO(verify)` rather than dropping them or fabricating details.
