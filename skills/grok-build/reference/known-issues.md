> Part of the [grok-build skill](../SKILL.md).

# Grok Build: Verified Known Issues and Caveats

This file tracks local findings and public-doc deltas for Grok Build. Last
updated 2026-05-17 from local `grok 0.1.211 (2f2cd6d5c2)` tests and official xAI
docs last updated 2026-05-14.

## Claude-compatible resources can affect clean smoke tests

- **Source:** `grok inspect` and local headless stderr, verified 2026-05-17
- **Severity:** Medium

**Observed locally:** In a disposable repo, Grok still loaded user-level
Claude-compatible resources and emitted warnings about plugin name collisions,
skill frontmatter, MCP tool names, and hooks. `grok inspect` reported Claude
instruction/permission sources and many skills/plugins/agents/MCP servers.

**Workaround:** Run `grok inspect` before debugging a headless failure. If a smoke
test needs to isolate the CLI itself, temporarily reduce loaded skills/plugins or
run in an account/config profile known to be clean.

## `--max-turns 1` is too low for trivial prompts

- **Source:** local smoke tests, verified 2026-05-17
- **Severity:** Low

**Observed locally:** Even a one-word answer can consume more than one counted
turn because internal messages count against the turn limit.

**Workaround:** Use `--max-turns 10` for simple smoke tests and raise it for
`--best-of-n`, `--check`, tools, or write workflows.

## Named `--session-id` needs more verification

- **Source:** local session tests plus xAI docs, verified 2026-05-17
- **Severity:** Medium

**Observed locally:** The installed CLI accepted `--session-id`, but a named
session did not resume as expected in the local test. Capturing the actual
`sessionId` from `--output-format json` and passing it to `--resume` worked.

**Workaround:** Use actual JSON `sessionId` values in scripts.

## `--check` is not a simple CI smoke flag

- **Source:** local smoke tests, verified 2026-05-17
- **Severity:** Medium

**Observed locally:** `--check` hit the turn budget at 10 turns and later returned
a `Cancelled` JSON response with no `text` after attempting self-verification
behavior.

**Workaround:** Do not recommend `--check` as a generic smoke-test flag. If you
need it, test it on the target workflow with a realistic `--max-turns` value.

## `--best-of-n` increases turn usage

- **Source:** local smoke tests, verified 2026-05-17
- **Severity:** Low to medium

**Observed locally:** `--best-of-n 2` failed at `--max-turns 10` and passed at
`--max-turns 20`.

**Workaround:** Budget extra turns and latency when using candidate fan-out.

## Permission and sandbox semantics are still candidate scope

- **Source:** local help and limited probes, verified 2026-05-17
- **Severity:** Medium

**Observed locally:** `--permission-mode plan` produced a plan. A read-only
sandbox write probe did not create the target file, but the JSON response was
`Cancelled`, so this audit does not claim a stable write-denial contract.

**Workaround:** Before documenting or depending on `--permission-mode` or
`--sandbox`, run task-specific probes in a disposable repo and record both stdout
and stderr.

## Public community signal is still early

- **Source:** current web search on 2026-05-17
- **Severity:** Informational

Grok Build public commentary is mostly launch reaction, compatibility claims, and
workflow speculation. Official docs plus local CLI evidence should carry more
weight than blog or forum claims until the issue tracker/community evidence gets
more mature.
