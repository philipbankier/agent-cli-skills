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

## Default sandbox (bwrap) fails on many Linux servers

- **Source:** First-hand reproduction on Ubuntu server with Codex CLI v0.27.0 and v0.125.0 (2026-04-29)
- **Severity:** High — exec mode silently hangs or errors with no useful output

**What happens:** On Linux servers where `bwrap` (bubblewrap) cannot create network namespaces (common on VPS hosts, homelab machines, and environments without `sys_admin` capability), Codex exec commands either:

- Fail immediately with: `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`
- Hang indefinitely with no stdout (the agent tries to execute shell commands in the broken sandbox, they all fail, and it stalls waiting for output)

**Workaround:** Use `--dangerously-bypass-approvals-and-sandbox` to disable the bwrap sandbox entirely:

```bash
echo "Say hello" | codex exec -m gpt-5.5 \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check -
```

This is safe when:
- The machine is a private server you control
- You're running known prompts
- You're not processing untrusted input

**Key flags that fix this:**

| Flag | Why |
|------|-----|
| `--dangerously-bypass-approvals-and-sandbox` | Disables bwrap, which is broken on many Linux servers |
| `--skip-git-repo-check` | Allows running outside a git repo (common for one-off automation) |
| `-` (stdin pipe) | Reads prompt from stdin — avoids shell escaping issues with long prompts |
| `--output-last-message=<file>` | Captures output to file in addition to stdout |

---

## Old CLI versions silently fail on newer models (gpt-5.5, etc.)

- **Source:** First-hand reproduction: Codex CLI v0.27.0 failed with `400 Bad Request: "The 'gpt-5.5' model requires a newer version of Codex"` (2026-04-29)
- **Severity:** High — older CLI versions either error with unclear messages or silently hang

**What happens:** When using `-m gpt-5.5` (or any model newer than what your CLI version supports):

- v0.27.0 and earlier: silently hangs for 10+ minutes with no output, or returns `400 Bad Request` after exhausting retries
- The error message is clear in v0.125.0+ but invisible in older versions

**Workaround:** Always check your CLI version and upgrade before using new models:

```bash
# Check version
codex --version

# Upgrade (use nvm's npm if globally installed via nvm)
npm install -g @openai/codex

# Verify
codex --version   # Should be 0.125.0+ for gpt-5.5
```

**Quick test before long runs:**

```bash
echo "Say hello" | codex exec -m gpt-5.5 \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check -
```

If this returns "Hello" within ~10 seconds, your setup works. If it hangs or errors, fix CLI version or auth first.

---

## Codex OAuth token cannot be used with raw OpenAI Python SDK

- **Source:** First-hand reproduction (2026-04-29)
- **Severity:** Medium — causes confusion when trying to build custom tooling around Codex

**What happens:** The OAuth tokens stored in `~/.codex/auth.json` are scoped to the Codex CLI application. Using the `access_token` as an `OPENAI_API_KEY` with the `openai` Python SDK produces:

- `403 Forbidden: You have insufficient permissions for this operation. Missing scopes: api.model.read`
- `500 Internal Server Error` on chat completion requests

**Workaround:** Use Codex CLI itself (`codex exec`) as the interface. If you need programmatic access:

1. Use `codex exec` with `--output-last-message` and parse the file
2. Or use a separate OpenAI API key (`OPENAI_API_KEY` env var) for the Python SDK — this is a different billing system from ChatGPT/Codex OAuth

---

## Long prompts via CLI argument can hang — pipe via stdin instead

- **Source:** First-hand reproduction (2026-04-29)
- **Severity:** Medium — prompts over ~4K characters passed as CLI arguments may behave differently than piped stdin

**What happens:** Passing very long prompts as a direct argument to `codex exec` can cause:

- Shell argument length limits
- Different buffering behavior vs stdin pipe
- Hanging with no output in some configurations

**Workaround:** Pipe long prompts via stdin:

```bash
# For prompts in a file
cat /tmp/my-prompt.md | codex exec -m gpt-5.5 \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  --output-last-message=/tmp/output.md -

# With timeout protection
timeout 600 bash -c 'cat /tmp/my-prompt.md | codex exec -m gpt-5.5 \
  --dangerously-bypass-approvals-and-sandbox \
  --skip-git-repo-check \
  --output-last-message=/tmp/output.md -'
```

---

## TODO: research leads from community discussion

These items came from community research and need first-hand reproduction before being documented in detail:

- TODO(verify): Realtime V2 voice / WebRTC streaming claims for v0.115+ — needs upgrade to v0.115+ to test
- TODO(verify): MCP Apps enhancements (resource reads, file uploads, custom-server tool search) in v0.116-v0.119 — needs release notes spot-check + reproduction
- TODO(verify): Egress websocket transport behavior for remote workflows in v0.118+

---

## How to add an entry

Same rules as [the Claude Code known-issues file](../../claude-code/reference/known-issues.md#how-to-add-an-entry-to-this-file): link to a real verifiable source, quote titles exactly, describe upstream-reported behavior (not your theory), keep workarounds testable, and mark unverifiable items as `TODO(verify)` rather than dropping them or fabricating details.
