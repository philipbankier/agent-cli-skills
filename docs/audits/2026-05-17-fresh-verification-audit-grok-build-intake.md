# Fresh Verification Audit + Grok Build Intake

Date: 2026-05-17
Branch: `codex/fresh-verification-audit-grok-intake`
Scope: fresh verification audit of `agent-cli-skills`, Codex CLI refresh, and Grok Build intake promoted to a first-class skill with caveats.

## Executive Summary

The repository documentation was directionally strong, but many evidence markers
were stale against current local and upstream CLI behavior. This pass refreshed
the Codex CLI public docs around v0.130.0, added a first-class Grok Build skill
for verified headless and ACP behavior, and preserved explicit caveats for
surfaces that were help-exposed but not workflow-verified. Claude and Gemini
remain partly stale and should be handled in a separate refresh pass.

## Evidence Map

| Area | Local verification | Upstream/docs verification | Evidence state |
| --- | --- | --- | --- |
| Claude Code | Installed `claude` is `2.1.123`; top-level help includes newer flags and `ultrareview`; `claude auth status` reports logged in through `claude.ai`. | npm latest is `2.1.143`; GitHub latest release observed as `v2.1.143`. | Local help is verified, but headless smoke is blocked by missing API/OAuth env credentials. |
| Codex CLI | Installed `codex-cli 0.130.0`; `codex exec` smoke passed with `OK`; command surface includes `plugin`, `remote-control`, `app-server`, `exec-server`, `features`, and `cloud`. | npm latest is `0.130.0`; alpha dist-tag observed as `0.131.0-alpha.22`; GitHub latest observed alpha release is `0.131.0-alpha.22`. | Safe to update docs from local help and smoke. |
| Gemini CLI | Installed `0.33.0`; `gemini -p` JSON smoke passed with `OK`; `skills`, `extensions`, and `hooks` help matched existing v0.33-era docs. | npm latest is `0.42.0`; preview `0.43.0-preview.0`; nightly `0.44.0-nightly.20260515.g928a311fb`. | Local docs remain valid for installed CLI, but upstream/latest rows are stale and model examples need revalidation. |
| Grok Build | Installed `grok 0.1.211 (2f2cd6d5c2)`; `grok -p` worked for `plain`, `json`, and `streaming-json`; prompt file, prompt JSON array, actual-session-id resume, `models`, and `agent stdio` initialize passed. | Official xAI docs confirm headless `-p`/`--single`, output formats, session flags, JSON prompt, `--always-approve`, Claude-compatible skills/plugins/MCP/hooks, and ACP via `grok agent stdio`; relevant pages last updated 2026-05-14. | Safe to add public docs for verified headless/ACP paths. Richer flags are documented only as help-exposed or caveated. |

## Safe To Update Now

- Refresh README and per-file `Last verified` markers that still point to 2026-04-14.
- Update installed/upstream rows:
  - Claude local `2.1.123`, npm latest observed `2.1.143`.
  - Codex local and npm latest `0.130.0`, alpha `0.131.0-alpha.22`.
  - Gemini local `0.33.0`, npm latest `0.42.0`, preview `0.43.0-preview.0`, nightly `0.44.0-nightly.20260515.g928a311fb`.
- Refresh Codex command documentation for current `0.130.0` help:
  - Top-level commands now include `plugin`, `remote-control`, `app-server`, `exec-server`, `features`, and `cloud`.
  - `codex exec --help` still includes `resume`, confirming the current public distinction between `codex resume` for interactive/TUI sessions and `codex exec resume` for non-interactive workflows.
  - `codex plugin --help` currently exposes `marketplace` only.
- Refresh Codex behavior documentation for local v0.130 tests:
  - `--full-auto` still works but emits `warning: --full-auto is deprecated; use --sandbox workspace-write instead.`
  - Piped stdin with a prompt works without a trailing `-`; the old `codex exec "prompt" -` pattern now fails.
  - JSONL assistant messages use `item.type == "agent_message"` and `item.text`.
  - `turn.completed` includes `usage`.
  - `-o` writes the final message file and still prints the final message to stdout when `--json` is not enabled.
  - `codex exec --sandbox read-only resume --last ...` works; putting `--sandbox` after `resume` fails.
  - `--output-schema` passed on initial `codex exec`; upstream issue #22998 tracks missing resume support.
- Refresh Claude command and flag docs for installed `2.1.123` help:
  - `ultrareview` is now present as a top-level command.
  - Top-level help includes `--agents`, `--allow-dangerously-skip-permissions`, `--bare`, `--brief`, `--fallback-model`, `--file`, `--fork-session`, `--from-pr`, `--include-hook-events`, `--include-partial-messages`, `--max-budget-usd`, `--plugin-dir`, `--remote-control-session-name-prefix`, and `--worktree`.
  - `--effort` choices now include `max`.
- Fix broken local documentation links found by the audit:
  - The initial broad scan reported illustrative links inside fenced examples in `skill-authoring/claude-code.md` and `skill-authoring/cross-platform.md`; those are examples, not live documentation links.
  - The one real broken local link was `skills/claude-code/reference/commands.md` pointing at missing `json-output.md`; it now points at existing `json-schemas.md`.
- Update stale model examples:
  - `skills/claude-code/examples/debate-engine/debate.py` still defaults to `claude-sonnet-4-20250514`.
  - Gemini smoke traffic used service-side model names `gemini-3.1-flash-lite` and `gemini-3-flash-preview`, so examples mentioning `gemini-2-5-flash` or `gemini-2.5-flash` should be rechecked before being treated as current.
- Keep the fabricated-flag notes as intentional examples. The grep only found documented false-claim warnings, not accidental fabricated flags.

## Needs User, Auth, Or Manual Run

- Claude headless print-mode smoke did not pass even though `claude auth status` reports a logged-in `claude.ai` account. The headless run returned a 401 authentication error and no relevant `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or `CLAUDE_CODE_OAUTH_TOKEN` environment variables were set. This needs a user-authenticated terminal run or explicit API/OAuth environment setup before public docs can claim fresh Claude headless behavior.
- The Claude debate-engine sample output should not be refreshed from a nested agent session. The existing script warns to run standalone, and this remains the right manual verification path.
- Gemini examples still need true end-to-end sample-output generation. The installed CLI smoke works, but the repo does not currently include Gemini debate-engine sample output.
- `TODO(verify)` items remain open:
  - Gemini: slow file performance, 429 free-tier behavior, and Memory service / Flash 3.1 lite behavior.
- Codex: `remote-control`, `exec-server`, `/goal` approval-policy semantics, Full Access `/goal` sandbox fallback, and resume/schema parity.
- Star counts and GitHub issue states are volatile. The audit captured fresh values for the report, but public docs should avoid hard-coding counts unless each count carries a dated verification marker.

## Grok Build Intake

Grok Build is now suitable for first-class public documentation for the verified
headless and ACP paths. Advanced flags remain candidate scope until each has a
task-specific repro.

Official xAI docs currently verify:

- Headless mode with `grok -p` / `grok --single`.
- Output formats `plain`, `json`, and `streaming-json`.
- Session-related flags including `--session-id`, `--resume`, and `--continue`.
- JSON prompt input through `--prompt-json`.
- `--always-approve` for approval behavior.
- ACP through `grok agent stdio`.
- Claude-compatible skills, plugins, MCPs, hooks, agents, and instruction files.
- The official headless scripting page was last updated on 2026-05-14.

Local CLI behavior verified:

- `grok --version` returned `grok 0.1.211 (2f2cd6d5c2)`.
- `grok -p "Reply with exactly OK"` passed for all documented output formats when run with `--disable-web-search --no-plan --max-turns 10`.
- `grok --prompt-file prompt.txt` passed with JSON output.
- `grok --prompt-json '[{"type":"text","text":"Reply with exactly OK"}]'` passed; object forms failed without additional ACP-like fields and should not be documented as verified.
- Session resume passed when the actual JSON `sessionId` was captured and passed to `--resume`.
- `--continue` passed after a remembered-word setup.
- `--session-id` was accepted by the installed CLI, but the named-session workflow did not resume as expected locally.
- `grok models` returned logged-in status with default and available model `grok-build`.
- `--max-turns 1` is too low even for a trivial prompt because Grok counts internal prompt messages; it failed before completion. Future docs should avoid recommending `--max-turns 1` as a smoke-test limiter.
- `grok agent stdio` responded to JSON-RPC `initialize` with ACP protocol version `1`, `agentCapabilities.loadSession: true`, embedded-context prompt capability, HTTP/SSE MCP capability, auth methods `cached_token` and `grok.com`, agent version `0.1.211`, and model state `grok-build`.
- The official docs also mention API-key auth through `GROK_CODE_XAI_API_KEY`; that path still needs local verification.
- `grok inspect` reported config from `/Users/philipbankier/.grok/config.toml`, project instructions from `/Users/philipbankier/.claude/Claude.md`, permissions from `.claude/settings.local.json`, 91 skills, 47 plugins, and 2 MCP servers.
- `--best-of-n 2` failed at `--max-turns 10` and passed at 20, so fan-out needs a higher turn budget.
- `--check` hit the turn budget at 10 and returned cancelled output at 20 in the local smoke; do not recommend it as a cheap CI smoke flag.
- `--permission-mode plan` produced a plan. `--sandbox read-only` did not create the target file in a write probe, but the response was cancelled, so sandbox semantics still need deeper workflow verification.

Local CLI help exposes more than the current xAI headless scripting page:

- Flags: `--best-of-n`, `--check`, `--agents`, `--permission-mode`, `--worktree`, `--sandbox`, `--experimental-memory`, `--no-memory`, `--no-subagents`, `--restore-code`, `--rules`, and tool allow/deny controls.
- Commands: `memory`, `sessions`, `models`, `worktree`, `inspect`, `trace`, `share`, and `ssh`.

These richer local flags and commands are documented as help-exposed only unless
the new Grok skill states a local workflow result.

## Community And Issue-Tracker Findings

- Codex stable npm `@openai/codex` was `0.130.0` and alpha was `0.131.0-alpha.22` on 2026-05-17; the GitHub repo had 83,137 stars when checked.
- OpenAI Codex issue #22998 reports `codex exec resume` does not support `--output-schema`.
- Issue #20084 reports `codex exec --ephemeral resume <id>` can still persist rollout data.
- Issue #14470 reports `codex exec --json resume` can hang on macOS after MCP helpers start.
- Issue #21984 reports configured MCP servers eagerly starting per session, especially visible with headed browser MCP servers.
- Issue #22362 tracks ambiguity around `/goal` and inherited approval policies; issue #23105 tracks a Full Access `/goal` sandbox fallback report.
- Public Grok Build commentary was sparse and launch-oriented. The useful guidance came from official xAI docs plus local CLI behavior; community tips should remain anecdotal until reproduced.

## Repo Verification Log

Commands run successfully:

- `bash -n` across repository shell scripts.
- Non-code Markdown internal-link scan after fixes.
- Codex headless smoke: `codex exec 'Reply with exactly OK' --ephemeral --sandbox read-only`.
- Gemini headless smoke: `gemini -p 'Reply with exactly OK' --output-format json`.
- Grok headless smoke for `plain`, `json`, and `streaming-json`.
- Grok prompt file, prompt JSON array, `models`, session resume by actual `sessionId`, and `--continue`.
- Grok ACP initialize handshake through `grok agent stdio`.
- Version/help checks for `claude`, `codex`, `gemini`, and `grok`.
- npm and GitHub release checks for Claude Code, Codex CLI, and Gemini CLI.

Commands with important caveats:

- Claude headless smoke failed with 401 authentication despite local `claude auth status` reporting logged in. Treat current Claude help as verified, but headless execution as unverified.
- The broad markdown internal-link scan can flag illustrative links inside code/example blocks. A non-code scan after fixes found no broken local Markdown links.
- Grok `--check`, named `--session-id`, and sandbox probes produced caveated results and should not be treated as stable public recipes.

## Sources

- xAI Grok Build headless scripting docs: <https://docs.x.ai/build/cli/headless-scripting>
- xAI Grok Build overview: <https://docs.x.ai/build/overview>
- xAI Grok Build skills/plugins docs: <https://docs.x.ai/build/features/skills-plugins-marketplaces>
- xAI Grok Build modes and commands docs: <https://docs.x.ai/build/modes-and-commands>
- OpenAI Codex non-interactive docs: <https://developers.openai.com/codex/noninteractive>
- OpenAI Codex best practices docs: <https://developers.openai.com/codex/learn/best-practices>
- OpenAI Codex release 0.130.0: <https://github.com/openai/codex/releases/tag/rust-v0.130.0>
- Codex issue #22998: <https://github.com/openai/codex/issues/22998>
- Codex issue #20084: <https://github.com/openai/codex/issues/20084>
- Codex issue #14470: <https://github.com/openai/codex/issues/14470>
- Codex issue #21984: <https://github.com/openai/codex/issues/21984>
- Codex issue #22362: <https://github.com/openai/codex/issues/22362>
- Codex issue #23105: <https://github.com/openai/codex/issues/23105>
