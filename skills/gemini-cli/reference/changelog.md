> Part of the [gemini-cli skill](../SKILL.md).

# Gemini CLI Upstream Changelog (v0.34.0 → v0.37.2)

This file captures changes shipped between our locally-tested install (v0.33.0) and the current upstream release (v0.37.2). Entries are summarized from the **official GitHub release notes** for `google-gemini/gemini-cli`. The release notes themselves are the source of truth — when in doubt, follow the link.

> **Verification status:** Local install is v0.33.0. Entries below are documented from release notes, not from live `--help` runs against the new versions. Tag entries marked `(verify after upgrade)` apply when you upgrade to v0.34+ — re-run `gemini --help` and per-subcommand `--help` to confirm.

> **Signal-to-noise note:** Gemini CLI's release notes are auto-generated PR title lists rather than curated highlights. The summaries below extract the user-facing changes worth knowing about and skip routine refactors, test cleanups, and dependency bumps. Always check the linked release page if you need the full PR list.

Source: `gh api repos/google-gemini/gemini-cli/releases/tags/v<version>` on 2026-04-14.

---

## v0.37.2 (2026-04-13)

[Release notes](https://github.com/google-gemini/gemini-cli/releases/tag/v0.37.2)

Patch release: cherry-pick from main onto `release/v0.37.1-pr-24565`. No new user-facing features.

---

## v0.37.0 / v0.37.1 (2026-04-08 / 2026-04-09)

[v0.37.0 release notes](https://github.com/google-gemini/gemini-cli/releases/tag/v0.37.0) · [v0.37.1 release notes](https://github.com/google-gemini/gemini-cli/releases/tag/v0.37.1)

**New features:**
- **Sandbox `forbiddenPaths`** — `forbiddenPaths` now implemented for OS-specific sandbox managers (#23282). Lets you explicitly block agent access to paths the OS sandbox would otherwise allow.
- **Browser agent `maxActionsPerTask` setting** — bound how many actions the browser agent takes per task (#23216). Useful as a cost/time guard.
- **CI skill for automated failure replication** — `feat(skills): add ci skill for automated failure replication` (#23720). Likely surfaces in `gemini skills list` after install.
- **Inline `agentCardJson` for remote agents** (#23743) — pass remote agent definitions inline instead of by reference.
- **Agents enabled by default** — earlier "disable agents by default" config was reverted (#23672). **(verify after upgrade)** — defaults that affect behavior are worth re-confirming on a fresh install.
- Conditional `additional_permissions` exposure in shell tool (#23729) — finer-grained control over what the shell tool can request.

**Bug fixes:**
- Skip console log/info output in headless mode (#22739) — quieter `gemini -p` runs.
- Plan mode telemetry attribute keys updated (#23685).
- Premature MCP discovery completion fix (#23637) — improves reliability of MCP server tool listing.
- Fixed dynamic model routing for `gemini-3.1-pro` to customtools model (#23641).
- Browser security: detect embedded URLs in query params to prevent allowedDomains bypass (#23225); added proxy bypass constraint to domain restriction system prompt (#23229).

---

## v0.36.0 (2026-04-01)

[Release notes](https://github.com/google-gemini/gemini-cli/releases/tag/v0.36.0)

**New features:**
- **Subagent local execution and tool isolation** (#22718) — subagents can run locally and have their tool surfaces isolated from the parent.
- **Multi-registry architecture for subagent tool filtering** (#22712) — supports tool routing across multiple registries.
- **Auto-add VSCode workspace folders to Gemini context** (#21380) — when running inside VS Code, additional workspace roots are picked up automatically.
- **`blocked` task status** (#22735) — adds a third state alongside in-progress / completed for tracker tools.
- **Task tracker protocol integrated into core system prompt** (#22442).
- **Dynamic model resolution in `ModelConfigService`** (#22578) — supports model aliasing at the config layer.
- Agent acknowledgment command + enhanced registry discovery for A2A (#22389).

**Bug fixes:**
- Resume robustness improvements: use active sessionId in useLogger (#22606).
- Expand tilde in policy paths from settings.json (#22772).
- Updated Docker image reference for GitHub MCP server (#22938).
- Subagent grouping and UI state persistence fixes (#22252).

---

## v0.35.0 (2026-03-24)

[Release notes](https://github.com/google-gemini/gemini-cli/releases/tag/v0.35.0)

**New features:**
- **Customizable keyboard shortcuts** (#21945, #21972, #22042) — first-class keybinding configuration with support for literal character keybindings and extended Kitty protocol keys; `-` prefix removes a binding.
- **`--admin-policy` flag** for supplemental admin policies (#20360). **(verify after upgrade)** — a new top-level flag that should appear in `gemini --help`.
- **Vim mode motions added**: `X`, `~`, `r`, `f/F/t/T`, `df/dt` and friends (#21932).
- A2A agent timeout increased to 30 minutes (#21028) — accommodates long-running agents.
- Parallelized user quota and experiments fetching in `refreshAuth` (#21648) — faster startup.
- Include `initiationMethod` in conversation interaction telemetry (#22054).

**Bug fixes:**
- `/clear` and `/resume` cleanup (#22007).
- Reap orphaned descendant processes on PTY abort (#21124) — fixes #20941.
- Update language detection to use LSP 3.18 identifiers (#21931).
- Handle `EISDIR` in `robustRealpath` on Windows (#21984).
- Cursor position fixes in NORMAL mode after deletes (#21973).
- Allow scrolling keys in copy mode (#19933).
- Remove OAuth check from `handleFallback` (#21962).

---

## v0.34.0 (2026-03-15)

[Release notes](https://github.com/google-gemini/gemini-cli/releases/tag/v0.34.0)

**New features:**
- **Tracker CRUD tools and visualization** (#19489) — new built-in tools for managing tasks/trackers.
- **Chat resume footer on session quit** (#20667) — quit-time hint about how to resume the session.
- **`@file` autocomplete improvements** — prioritize filenames in completion ranking (#21064).
- **Improved semantic focus colors and history visibility** (#20745).
- Added extra safety checks against proto pollution (#20396).
- Multi-arch docker builds enabled for sandbox (#19821).
- Smarter shell autocomplete rendering — more shell-native feeling (#20931).

**Bug fixes:**
- Model persistence across all scenarios (#21051).
- Concurrent auto-update guard (#21016).
- Defensive coding to reduce risk of "Maximum update depth" errors (#20940).
- MCP `notifications/tools/list_changed` support fix (#21050).
- Register extension lifecycle events in `DebugProfiler` (#20101).

---

## How to use this changelog

When you upgrade your local install from v0.33.0 to v0.34+:

1. Run `gemini --help` and look for new top-level flags, especially `--admin-policy` (added in v0.35.0)
2. Run `gemini skills list` and `gemini extensions list` to see if any new built-in skills (e.g. the CI skill from v0.37) appear
3. Re-verify the items tagged `(verify after upgrade)` above, especially the "agents enabled by default" change in v0.37
4. Update [cli-flags.md](cli-flags.md) and [subcommands.md](subcommands.md) with any new flags or subcommands that appear in the live `--help`
5. Update the verified-against version stamp at the top of those files

The changelog file itself doesn't get touched on upgrade — it tracks the historical gap between this repo's tested install and current upstream.
