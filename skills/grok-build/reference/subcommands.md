> Part of the [grok-build skill](../SKILL.md).

# Grok Build Subcommand Reference

Last verified against `grok --help` and selected subcommand help for
**Grok Build 0.1.211 (2f2cd6d5c2)** on 2026-05-17.

## Subcommand Tree

Observed top-level commands:

```text
grok
|-- agent
|   |-- stdio
|   |-- headless
|   |-- serve
|   `-- leader
|-- import
|-- inspect
|-- leader
|-- login
|-- mcp
|-- memory
|-- models
|-- sessions
|   |-- list
|   `-- search
|-- setup
|-- share
|-- ssh
|-- trace
|-- update
|-- version
`-- worktree
    |-- list
    |-- show
    |-- rm
    |-- gc
    `-- db
```

Only the safe/read-only parts of this tree were exercised. Treat write, worktree,
MCP, leader, update, and SSH flows as requiring fresh verification.

## `grok inspect`

Use this before headless automation:

```bash
grok inspect
```

Local `grok inspect` reported:

- project trust state
- project instructions
- permissions source
- loaded skills/plugins/agents/MCP servers
- config sources

This is the fastest way to discover why a headless run emits warnings or behaves
differently from a clean install.

## `grok models`

```bash
grok models
```

Local output showed:

```text
You are logged in with grok.com.

Default model: grok-build

Available models:
  * grok-build (default)
```

## ACP: `grok agent stdio`

Official docs describe `grok agent stdio` as an ACP agent over JSON-RPC on
stdin/stdout. Local initialize smoke test passed.

Minimal initialize request:

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":1,"clientCapabilities":{}}}' |
  grok agent stdio
```

Observed local response included:

- `protocolVersion: 1`
- `agentCapabilities.loadSession: true`
- prompt capabilities with `embeddedContext: true`
- MCP capabilities for `http` and `sse`
- auth methods `cached_token` and `grok.com`
- `_meta.agentVersion: 0.1.211`
- `_meta.modelState.currentModelId: grok-build`

Official docs also mention API-key auth with `GROK_CODE_XAI_API_KEY`; local ACP
handshake did not advertise `xai.api_key` in this cached-token environment.

## Sessions

```bash
grok sessions --help
grok sessions list
grok sessions search <query>
```

Prefer JSON `sessionId` capture for script resume. The help-exposed
`--session-id` named-session path needs more local verification.

## Memory

```bash
grok memory --help
```

Memory commands were only help-checked. Do not document persistence semantics
until tested.

## Worktrees

```bash
grok worktree --help
```

The installed CLI exposes worktree commands, and public commentary emphasizes
parallel worktree flows, but no worktree mutation was run in this audit. Treat
this as future scope.
