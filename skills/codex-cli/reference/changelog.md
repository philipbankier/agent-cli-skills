> Part of the [codex-cli skill](../SKILL.md).

# Codex CLI Upstream Changelog (v0.115.0 → v0.120.0)

This file captures changes shipped between our locally-tested install (v0.114.0) and the current upstream release (v0.120.0). Every entry below is summarized from the **official GitHub release notes** for `openai/codex`. The release notes themselves are the source of truth — when there's any doubt about behavior, follow the link to the upstream PR.

> **Verification status:** Local install is v0.114.0. Entries below are documented from release notes, not from live `--help` runs against the new version. Tag entries with `(verify after upgrade)` apply when you upgrade to v0.115+ — re-run `codex --help` and `codex <subcommand> --help` to confirm.

Source: `gh api repos/openai/codex/releases/tags/rust-v<version>` on 2026-04-14.

---

## v0.120.0 (2026-04-11)

[Release notes](https://github.com/openai/codex/releases/tag/rust-v0.120.0) · [Compare](https://github.com/openai/codex/compare/rust-v0.119.0...rust-v0.120.0)

**New features:**
- Realtime V2 can stream background agent progress while work is still running and queue follow-up responses until the active response completes (#17264, #17306).
- Hook activity in the TUI is easier to scan, with live running hooks shown separately and completed hook output kept only when useful (#17266).
- Custom TUI status lines can include the renamed thread title (#17187).
- Code-mode tool declarations now include MCP `outputSchema` details so structured tool results are typed more precisely (#17210).
- SessionStart hooks can distinguish sessions created by `/clear` from fresh startup or resume sessions (#17073).

**Bug fixes:**
- Fixed Windows elevated sandbox handling for split filesystem policies, including read-only carveouts under writable roots (#14568).
- Fixed sandbox permission handling for symlinked writable roots and carveouts, preventing failures in shell and `apply_patch` workflows (#15981).
- Fixed `codex --remote wss://...` panics by installing the Rustls crypto provider before TLS websocket connections (#17288).
- Fixed live Stop-hook prompts so they appear immediately instead of only after thread history reloads (#17189).
- Fixed app-server MCP cleanup on disconnect so unsubscribed threads and resources are torn down correctly (#17223).

---

## v0.119.0 (2026-04-10)

[Release notes](https://github.com/openai/codex/releases/tag/rust-v0.119.0) · [Compare](https://github.com/openai/codex/compare/rust-v0.118.0...rust-v0.119.0)

**New features:**
- Realtime voice sessions now default to the v2 WebRTC path, with configurable transport, voice selection, native TUI media support, and app-server coverage for the new flow (#16960, #17057, #17058, #17093, #17097, #17145, #17165, #17176, #17183, #17188).
- MCP Apps and custom MCP servers gained richer support: resource reads, tool-call metadata, custom-server tool search, server-driven elicitations, file-parameter uploads, and more reliable plugin cache refreshes (#16082, #16465, #16944, #17043, #15197, #16191, #16947).
- Remote/app-server workflows now support egress websocket transport, remote `--cd` forwarding, runtime remote-control enablement, sandbox-aware filesystem APIs, and an experimental top-level `codex exec-server` subcommand (#15951, #16700, #16973, #16751, #17059, #17142, #17162). **(verify after upgrade)** — top-level `exec-server` is a new subcommand surface that should appear in `codex --help` after upgrade.
- The TUI can copy the latest agent response with `Ctrl+O`, with better clipboard behavior over SSH and across platforms (#16966).
- `/resume` can now jump directly to a session by ID or name from the TUI (#17222).
- TUI notifications are more configurable, including Warp OSC 9 support and an opt-in mode for notifications even while the terminal is focused (#17174, #17175).

**Bug fixes:**
- The TUI starts faster by fetching rate limits asynchronously, and `/status` refreshes stale limits instead of showing frozen quota information (#16201, #17039).
- Resume flows are more stable: picker no longer flashes false empty states, uses fresher thread names, stabilizes timestamp labels, preserves resume hints on zero-token exits, and avoids crashing when resuming the current thread (#16591, #16601, #16822, #16987, #17086).
- Composer/chat behavior smoother: fixed paste teardown, CJK word navigation, stale `/copy` output, percent-decoded local file links, and clearer truncated exec-output hints (#16202, #16829, #16648, #16810, #17076).
- Fast Mode no longer stays stuck on after `/fast off` in app-server-backed TUI sessions (#16833).
- MCP status and startup are less noisy and faster: hyphenated server names list tools correctly, `/mcp` avoids slow full inventory probes, disabled servers skip auth probing, and residency headers are honored by `codex mcp-server` (#16674, #16831, #17098, #16952).
- Sandbox/network/platform tightening: clearer read-only `apply_patch` errors, refreshed network proxy policy after sandbox changes, suppressed irrelevant bubblewrap warnings, macOS HTTP-client sandbox panic fix, Windows firewall address handling (#16885, #17040, #16667, #16670, #17053).

---

## v0.118.0 (2026-03-31)

[Release notes](https://github.com/openai/codex/releases/tag/rust-v0.118.0)

**New features:**
- **`codex exec` now supports prompt-plus-stdin** — pipe input *and* pass a separate prompt on the command line in the same call (#15917). Closes a long-standing gap between Codex and Claude Code's `claude -p` ergonomics. **(verify after upgrade)**
- Windows sandbox runs can enforce proxy-only networking with OS-level egress rules, instead of relying on environment variables (#12220).
- App-server clients can start ChatGPT sign-in with a device code flow, useful when browser callback login is unreliable or unavailable (#15525).
- Custom model providers can fetch and refresh short-lived bearer tokens dynamically, instead of being limited to static credentials (#16286, #16287, #16288).

**Bug fixes:**
- Project-local `.codex` files are now protected even on first creation, closing a gap where the initial write could bypass approval checks (#15067).
- Linux sandbox launches more reliable: Codex once again finds a trusted system `bwrap` on normal multi-entry `PATH`s (#15791, #15973).
- App-server-backed TUI regained several missing workflows: hook notifications replay correctly, `/copy` and `/resume <name>` work again, `/agent` no longer shows stale threads, and the skills picker scrolls past the first page (#16013, #16021, #16050, #16014, #16109, #16110).
- MCP startup more robust: local servers get a longer startup window, and failed handshakes surface warnings in the TUI again instead of looking like clean startups (#16080, #16041).

---

## v0.117.0 (2026-03-22)

[Release notes](https://github.com/openai/codex/releases/tag/rust-v0.117.0)

**New features:**
- **Plugins are now a first-class workflow** — Codex can sync product-scoped plugins at startup, browse them in `/plugins`, and install or remove them with clearer auth/setup handling (#15041, #15042, #15195, #15215, #15217, #15264, #15275, #15342, #15580, #15606, #15802). **(verify after upgrade)** — this brings Codex closer to Claude Code's plugin/marketplace ecosystem.
- **Sub-agents now use readable path-based addresses** like `/root/agent_a`, with structured inter-agent messaging and agent listing for multi-agent v2 workflows (#15313, #15515, #15556, #15570, #15621, #15647).
- The `/title` terminal-title picker now works in both classic TUI and app-server TUI, making parallel sessions easier to tell apart (#12334, #15860).
- App-server clients can send `!` shell commands, watch filesystem changes, and connect to remote websocket servers with bearer-token auth (#14988, #14533, #14847, #14853).
- Image workflows smoother: `view_image` now returns image URLs for code mode, generated images are reopenable from the TUI, and image-generation history survives resume (#15072, #15154, #15223).

**Bug fixes:**
- Linux sandboxed tool calls more reliable on older distributions with older `bubblewrap`; Windows restricted-token sandboxing now supports more split-policy carveout layouts (#15693, #14172).
- Remote multi-agent sessions show agent names instead of raw IDs and recover more gracefully from stale turn-steering races (#15513, #15714, #15163).
- Plugin-backed mentions and product gating behave more predictably (#15372, #15263, #15279).

---

## v0.116.0 (2026-03-15)

[Release notes](https://github.com/openai/codex/releases/tag/rust-v0.116.0)

**New features:**
- App-server TUI now supports device-code ChatGPT sign-in during onboarding and can refresh existing ChatGPT tokens (#14952).
- Plugin setup is smoother: Codex can prompt to install missing plugins or connectors, honor a configured suggestion allowlist, and sync install/uninstall state remotely (#14896, #15022, #14878).
- Added a `userpromptsubmit` hook so prompts can be blocked or augmented before execution and before they enter history (#14626).
- Realtime sessions now start with recent thread context and are less likely to self-interrupt during audio playback (#14829, #14827).

**Bug fixes:**
- Fixed first-turn stall where websocket prewarm could delay `turn/start` (#14838).
- Restored conversation history for remote resume/fork in the app-server TUI; stopped duplicate live transcript output from legacy stream events (#14930, #14892).
- Improved Linux sandbox startup on symlinked checkouts, missing writable roots, and Ubuntu/AppArmor hosts by preferring system `bwrap` when available (#14849, #14890, #14963).

---

## v0.115.0 (2026-03-08)

[Release notes](https://github.com/openai/codex/releases/tag/rust-v0.115.0)

**New features:**
- Supported models can request full-resolution image inspection through both `view_image` and `codex.emitImage(..., detail: "original")` (#14175).
- `js_repl` exposes `codex.cwd` and `codex.homeDir`, and saved `codex.tool(...)` / `codex.emitImage(...)` references keep working across cells (#14385, #14503).
- Realtime websocket sessions gained dedicated transcription mode + v2 handoff support through the `codex` tool, with unified `[realtime]` session config (#14554, #14556, #14606).
- The v2 app-server now exposes filesystem RPCs for file reads, writes, copies, directory operations, and path watching, plus a new Python SDK for integrating with that API (#14245, #14435).
- Smart Approvals can route review requests through a guardian subagent in core, app-server, and TUI (#13860, #14668).
- App integrations now use the Responses API tool-search flow, suggest missing tools, and fall back cleanly when the active model doesn't support search-based lookup (#14274, #14287, #14732).

**Bug fixes:**
- Spawned subagents inherit sandbox and network rules more reliably, including project-profile layering, persisted host approvals, and symlinked writable roots (#14619, #14650, #14674, #14807).
- The TUI no longer stalls on exit after creating subagents; interrupting a turn no longer tears down background terminals by default (#14816, #14602).
- `codex exec --profile` once again preserves profile-scoped settings when starting or resuming a thread (#14524).

---

## How to use this changelog

When you upgrade your local install:

1. Run `codex --help` and `codex <subcommand> --help` for any new subcommands listed above
2. Reverify everything tagged `(verify after upgrade)` — especially `codex exec-server` (top-level subcommand introduced in v0.119) and the `codex exec` prompt-plus-stdin behavior added in v0.118
3. Update [exec-mode-flags.md](exec-mode-flags.md) and [subcommands.md](subcommands.md) with anything new that appears in the live `--help`
4. Update the verified-against version stamp at the top of those files

The changelog file itself doesn't get touched on upgrade — it tracks the historical gap between this repo's tested install and current upstream.
