> Part of the [gemini-cli skill](../SKILL.md).

# Gemini CLI: Verified Known Issues

A curated list of confirmed-real Gemini CLI issues with reproducible workarounds.

> **Verification policy:** Every entry on this page links to a real GitHub issue confirmed via `gh api repos/google-gemini/gemini-cli/issues/<number>` on 2026-04-14. Issue *titles* are quoted from the live issue. Items marked `TODO(verify)` are research leads that still need reproduction.

---

## Gemini CLI removes parts of code unexpectedly

- **Issue:** [#23497 — "Gemini CLI is still removing parts of code (23 mar 2026)"](https://github.com/google-gemini/gemini-cli/issues/23497)
- **State:** open
- **First reported:** 2026-03-23
- **Severity:** High — data loss risk

**What's reported:** Gemini CLI has been observed deleting sections of code from files during edit operations, even when the prompt did not request deletion. The issue title's "still" indicates this has been a recurring class of bug, not a one-off.

**Workaround until upstream fix lands:**
- Always run with `git status` clean before letting Gemini CLI edit files
- Pair with `--approval-mode default` (or stricter) so each edit is reviewed before it lands
- For untrusted prompts, prefer `--approval-mode plan` (read-only) and apply changes manually
- Consider committing after each successful turn so you have granular undo

---

## `-f / --free` flag does not exist

- **Source:** `gemini --help` v0.33.0 (verified locally 2026-04-14)
- **Severity:** Low — but documented incorrectly in earlier versions of *this* repo

**What's reported:** Some community write-ups and earlier versions of this repo's docs reference a `-f / --free` flag for selecting key-free mode. **It does not exist** in v0.33.0's `gemini --help`. The actual auth selection is implicit: if `GEMINI_API_KEY` is set, the API key is used; otherwise the OAuth flow (and free tier) is used.

**Workaround:** Drop any reference to `-f` or `--free` from your scripts. To force OAuth/free-tier behavior, simply unset the API key environment variable: `unset GEMINI_API_KEY; gemini -p "..."`.

---

## `--allowed-tools` is deprecated

- **Source:** `gemini --help` v0.33.0
- **Severity:** Low — still works but deprecated

**What's documented:** The `--allowed-tools` flag is marked DEPRECATED with a pointer to the Policy Engine: *"DEPRECATED: Use Policy Engine instead See https://geminicli.com/docs/core/policy-engine"*

**Workaround:** Migrate scripts off `--allowed-tools` to the Policy Engine via `--policy <files>`. Specifics of the Policy Engine config format are out of scope here — see the upstream docs link in `--help`.

---

## `--experimental-acp` is deprecated, use `--acp`

- **Source:** `gemini --help` v0.33.0
- **Severity:** Trivial

**What's documented:** `--experimental-acp` works but is deprecated in favor of `--acp`. Both start the agent in ACP mode (Agent Communication Protocol).

**Workaround:** Replace `--experimental-acp` with `--acp` in any scripts.

---

## `gemini hooks migrate` is lossy

- **Source:** `gemini hooks --help` and structural reasoning about cross-CLI hook semantics
- **Severity:** Medium — important to know before relying on the migration

**What's documented:** `gemini hooks migrate` translates Claude Code hook configurations into Gemini's hook system. The translation is best-effort, not a 1:1 mapping. Hooks that rely on Claude-Code-specific event types or environment variables won't survive the port intact.

**Workaround:** Always commit your project state before running `gemini hooks migrate`. After running, `git diff` the result, manually test each translated hook by triggering its corresponding event, and treat the output as a starting point for refinement, not a finished port. See [`cross-platform/patterns/hook-migration.md`](../../../cross-platform/patterns/hook-migration.md) for the full discussion of cross-CLI hook portability.

---

## TODO: research leads needing reproduction

These items came from community research and need first-hand reproduction before being documented in detail:

- TODO(verify): Reports of slow `gemini` performance reading small files (~5 minutes for a small `.txt`). Need to reproduce on local v0.33.0 before adding as a verified entry.
- TODO(verify): 429 rate-limit errors on free tier. The rate limits *are* documented (1000 model requests/day on Google Account auth), but the failure mode and recovery behavior need first-hand testing.
- TODO(verify): Memory service / Flash 3.1 lite model support claimed for v0.34+ — needs upgrade to v0.34+ to test.

---

## How to add an entry

Same rules as [the Claude Code known-issues file](../../claude-code/reference/known-issues.md#how-to-add-an-entry-to-this-file): link to a real verifiable source, quote titles exactly, describe upstream-reported behavior (not your theory), keep workarounds testable, and mark unverifiable items as `TODO(verify)` rather than dropping them or fabricating details.
