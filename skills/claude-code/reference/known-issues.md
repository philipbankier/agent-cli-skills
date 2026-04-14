> Part of the [cc-cli-skill](../SKILL.md) skill.

# Claude Code: Verified Known Issues

A curated list of confirmed-real Claude Code issues with reproducible workarounds.
Each entry links to the upstream GitHub issue and includes verification status.

> **Verification policy:** Every entry on this page links to a real GitHub issue that was confirmed via `gh api repos/anthropics/claude-code/issues/<number>` on 2026-04-14. Issue *titles* are quoted from the actual issue. Behaviors described here may have shipped fixes since — always check issue state and recent comments before acting on a workaround.

---

## Cache TTL silently regressed (causes silent cost inflation)

- **Issue:** [#46829 — "Cache TTL silently regressed from 1h to 5m around early March 2026, causing quota and cost inflation"](https://github.com/anthropics/claude-code/issues/46829)
- **State:** closed
- **First reported:** 2026-04-12
- **Severity:** High — silent cost inflation on long sessions

**What's reported:** Around early March 2026, the prompt cache default TTL changed from 1 hour to 5 minutes. For long-running sessions, this means re-creating the prompt cache repeatedly at creation pricing instead of reading it at cache-read pricing — a multi-x cost difference that's invisible unless you parse the JSON output's `usage.cache_*` fields.

**How to detect in your environment:** Run a long session and check `cache_creation_input_tokens` vs `cache_read_input_tokens` in `--output-format json` results. If creation tokens dominate read tokens on what you'd expect to be cached repeats, you're hit.

**Workarounds (verify against current behavior — issue is closed):**
- Use `--exclude-dynamic-system-prompt-sections` to stabilize the system prompt across sessions, improving cache hit rate
- Keep individual sessions shorter so 5-minute TTL doesn't force cache misses
- Watch cumulative `total_cost_usd` across runs and abort on unusual spikes

---

## Session resume invalidates the prompt cache

- **Issue:** [#34629 — "[BUG] Prompt cache regression in --print --resume since v2.1.69(?): cache_read never grows, ~20x cost increase"](https://github.com/anthropics/claude-code/issues/34629)
- **Companion issue:** [#42338 — "Session resume (--continue) invalidates entire prompt cache, causes massive rate limit consumption"](https://github.com/anthropics/claude-code/issues/42338)
- **Companion issue:** [#38029 — "[BUG] Abnormal Usage Consumption on Claude Code Session Resume — Possible Bug"](https://github.com/anthropics/claude-code/issues/38029)
- **State:** mixed (some closed, some open)
- **Severity:** High — affects long-running automation that uses `--resume` / `--continue`

**What's reported:** Resuming a session via `--resume` or `--continue` on certain configurations (with deferred tools, MCP servers, or custom agents) causes a full prompt-cache miss on the first resumed request. Several hundred thousand tokens get replayed at creation price instead of read price.

**How to detect in your environment:** After resuming, inspect `cache_read_input_tokens` in the JSON output. If it's near zero on a session that should have warm cache, you're hit.

**Workarounds:**
- For one-shot automation, prefer `--no-session-persistence` over `--resume` — you give up cross-call context but you don't pay the cache invalidation tax
- For multi-step workflows, batch related work into a single invocation rather than resuming across many small invocations
- Track the issues — at least one was reopened recently; behavior may shift again

---

## VS Code extension breaks MCP servers on Windows

- **Issue:** [#45195 — "[BUG] VSCode extension doesn't load MCP servers on Windows due to drive letter case mismatch in .claude.json project key lookup"](https://github.com/anthropics/claude-code/issues/45195)
- **State:** open
- **First reported:** 2026-04-08
- **Severity:** High for Windows users using the VS Code extension

**What's reported:** The VS Code extension passes the project's drive letter as lowercase (`c:\...`) to the CLI. The CLI writes the project key to `~/.claude.json` as uppercase (`C:/...`). Project lookup is case-sensitive, so MCP servers configured for the project never load.

**How to detect:** On Windows + VS Code extension, configure an MCP server in your project, restart, and check whether it appears in `claude mcp list` from a session launched via the extension.

**Workaround:** Manually duplicate entries in `~/.claude.json` with both drive-letter cases. They will drift out of sync if you make further config changes via `claude mcp` commands. Track the upstream fix.

---

## Context limit triggers prematurely (verbose stop hooks)

- **Issue:** [#24458 — "[BUG] \"Context limit reached\" triggers at 27% usage (68.9% free space) — regression in 2.1.33"](https://github.com/anthropics/claude-code/issues/24458)
- **State:** closed
- **First reported:** 2026-02-09
- **Severity:** Medium — blocks sessions earlier than expected

**What's reported:** A regression in v2.1.33+ where the "Context limit reached" error triggers at roughly 27% of model context usage (68.9% free space). Root cause was identified in the issue thread: verbose stop hooks (formatters, linters that produce lots of output) get included in the next message's context, and the internal limit overflows before the actual model token budget is anywhere near full.

**How to detect:** If you hit "Context limit reached" but `/cost` or JSON `usage.input_tokens` shows you're nowhere near the model's stated context window, look at your stop hooks.

**Workaround:** Quiet your stop hooks. Pipe verbose tool output (formatter logs, lint output) to a file or to `/dev/null` instead of letting it flow back into the agent's context. The hook can still run its checks; just don't surface the noise.

---

## `--dangerously-skip-permissions` cascades to subagents

- **Issue:** Documented in [Anthropic's permission modes documentation](https://code.claude.com/docs/en/permission-modes) and noted in multiple community write-ups
- **State:** intended behavior, not a bug — but documented poorly enough that users routinely get burned
- **Severity:** Critical safety implication

**What's documented:** When you enable `--dangerously-skip-permissions`, it cascades to spawned subagents. There is no per-subagent override. Worse: combining `--dangerously-skip-permissions` with `--permission-mode plan` causes the bypass to silently override plan mode (you think you're in read-only mode, but the agent is actually running with full bypass).

**How to detect:** Read your invocation flags carefully. If you see both flags on the same line, plan mode is *not* in effect.

**Workarounds:**
- Never combine `--dangerously-skip-permissions` with `--permission-mode plan`
- For untrusted prompt sources, run Claude Code inside a real container/VM/sandbox, not just inside the in-CLI permission system. See [`cross-platform/patterns/os-sandboxing.md`](../../../cross-platform/patterns/os-sandboxing.md) for the in-CLI vs OS-level distinction.
- Use `--allow-dangerously-skip-permissions` if you want the bypass to be *available as an option* but not enabled by default

---

## How to add an entry to this file

When proposing an addition:

1. The issue must be a real, currently-existing GitHub issue verifiable via `gh api repos/anthropics/claude-code/issues/<number>`.
2. The issue title quoted in your entry must match the live title (we re-verify on each refresh).
3. The "What's reported" section should describe the *upstream-reported* behavior, not your own theory.
4. Workarounds should be testable. If you can't test it, mark it as `(unverified — needs reproduction)`.
5. Avoid speculation about root causes unless the issue maintainers have stated them. Link to the issue comment instead of paraphrasing.

The goal is "if I read this entry, I either trust it or I have a clear pointer to the source of truth."
