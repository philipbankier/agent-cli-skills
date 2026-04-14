> Part of the [codex-cli skill](../SKILL.md).

# Codex CLI: Verified Known Issues

A curated list of confirmed-real Codex CLI issues with reproducible workarounds.

> **Verification policy:** Every entry on this page links to a real GitHub issue or pull request that was confirmed via `gh api repos/openai/codex/...` on 2026-04-14. Entries marked `TODO(verify)` are research leads that need further reproduction before they're documented in detail. Treat workarounds as starting points, not finished playbooks — verify against the issue's current state first.

---

## `--on-failure` approval mode is deprecated

- **Source:** `codex exec --help` output for the `-a / --ask-for-approval` flag (verified locally on v0.114.0)
- **Severity:** Low — still works but the `--help` text marks it deprecated

**What's documented:** The `on-failure` value for `-a` / `--ask-for-approval` is marked DEPRECATED in `--help`: *"Run all commands without asking for user approval. Only asks for approval if a command fails to execute, in which case it will escalate to the user to ask for un-sandboxed execution. Prefer `on-request` for interactive runs or `never` for non-interactive runs."*

**Workaround:** Migrate scripts off `--on-failure`:
- For interactive use → `--ask-for-approval on-request`
- For non-interactive use → `--ask-for-approval never`

---

## `codex sandbox <os>` and `codex exec --sandbox` are different mechanisms

- **Source:** `codex sandbox --help` and `codex exec --help` (verified locally on v0.114.0)
- **Severity:** Medium — frequently confused

**What's documented:** `codex sandbox macos|linux|windows` is a top-level subcommand that wraps an arbitrary command in OS-level isolation (Seatbelt / Landlock+seccomp / Windows restricted token). `codex exec --sandbox {read-only|workspace-write|danger-full-access}` is an in-CLI policy on a Codex agent run. They are separate mechanisms — different layers of trust, different threat models.

**Workaround:** When you want OS-level isolation around any command (not just an agent run), use `codex sandbox <os> -- <command>`. When you want in-CLI permission policy on a Codex agent specifically, use `codex exec --sandbox <mode>`. To compose both, run `codex sandbox linux -- codex exec --full-auto "..."`. See [`cross-platform/patterns/os-sandboxing.md`](../../../cross-platform/patterns/os-sandboxing.md) for the full discussion.

---

## `codex resume` and `codex exec resume` are different commands

- **Source:** `codex resume --help` and `codex exec resume --help` (verified locally on v0.114.0)
- **Severity:** Medium — used to be documented incorrectly across this repo

**What's documented:** `codex resume [SESSION_ID] [PROMPT]` resumes a previous **interactive** session — the TUI launches. `codex exec resume [SESSION_ID] [PROMPT]` resumes a previous **non-interactive** exec-mode session. Both accept `--last` to skip the picker. They are not aliases.

**Workaround:** Use the form that matches your context — interactive for TUI work, exec for scripts. Sessions are scoped to the working directory, so `cd` between calls changes which one is "last."

---

## `gh search` shows a steady churn of recent app-server / TUI bugs

- **Source:** `gh api repos/openai/codex/issues` (verified on 2026-04-14)
- **Severity:** varies

**What's reported:** Recent issue queue includes items like "Scroller jumps like crazy", "Drain mailbox only at request boundaries", "Add marketplace remove command and shared logic" — indicating active churn around the app-server / TUI / marketplace surfaces. Most of these are unrelated to non-interactive `codex exec` automation usage.

**Workaround:** If you're hitting a TUI-specific issue, check whether the bug exists in non-interactive `codex exec` mode. For automation, prefer `codex exec` with `--ephemeral` over interactive flows when possible — fewer moving parts, narrower bug surface.

---

## TODO: research leads from community discussion

These items came from community research and need first-hand reproduction before being documented in detail:

- TODO(verify): Realtime V2 voice / WebRTC streaming claims for v0.115+ — needs upgrade to v0.115+ to test
- TODO(verify): MCP Apps enhancements (resource reads, file uploads, custom-server tool search) in v0.116-v0.119 — needs release notes spot-check + reproduction
- TODO(verify): Egress websocket transport behavior for remote workflows in v0.118+

---

## How to add an entry

Same rules as [the Claude Code known-issues file](../../claude-code/reference/known-issues.md#how-to-add-an-entry-to-this-file): link to a real verifiable source, quote titles exactly, describe upstream-reported behavior (not your theory), keep workarounds testable, and mark unverifiable items as `TODO(verify)` rather than dropping them or fabricating details.
