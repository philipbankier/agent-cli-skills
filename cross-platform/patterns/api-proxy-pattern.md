# API Proxy Pattern

How to expose CLI agent credentials as SDK-compatible API endpoints — and when to use this instead of direct CLI scripting.

## Decision Router

**Choose your approach:**

| You need... | Use |
|-------------|-----|
| Shell scripting, CI/CD, batch processing | Direct CLI (`claude -p`, `codex exec`, `gemini -p`) |
| SDK compatibility for one app, learning the pattern | [CC-Bridge](../../skills/claude-code/guides/build-bridge.md) |
| Production multi-provider proxy with load balancing | [CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) |

## How CLI Proxy Servers Work

CLI agents authenticate via OAuth during interactive login (`claude auth login`, `codex login`, `gemini login`). This stores OAuth tokens locally. A proxy server can use these tokens to make API calls on your behalf — without needing separate API keys.

There are two architectural approaches:

### Approach A: CLI Wrapper (CC-Bridge)

```
Your App (SDK) → HTTP POST → Bridge Server → spawns `claude -p` → CLI → Anthropic API
```

- Actually executes the CLI as a subprocess
- Parses stdout (JSON/NDJSON) and transforms to API response format
- Simple, educational, Claude-only
- ~100-200ms overhead per request from process spawning
- See: [Build a Bridge Server](../../skills/claude-code/guides/build-bridge.md)

### Approach B: Credential Proxy (CLIProxyAPI)

```
Your App (SDK) → HTTP POST → Proxy Server → direct HTTP → Provider API (Anthropic/OpenAI/Google)
```

- Extracts OAuth tokens from CLI auth stores
- Makes direct API calls to provider endpoints — never spawns CLI processes
- Multi-provider (Claude, Codex, Gemini, Qwen, iFlow, Antigravity)
- No process spawning overhead
- Production features: multi-account load balancing, Docker, TLS, management API

## CLIProxyAPI

[CLIProxyAPI](https://github.com/router-for-me/CLIProxyAPI) (18k+ stars) is the production-ready implementation of the credential proxy approach.

### What It Does

- Reads OAuth tokens from CLI auth directories (`~/.claude/`, `~/.codex/`, `~/.gemini/`)
- Exposes OpenAI, Claude, and Gemini-compatible API endpoints on localhost
- Translates between API formats (send OpenAI format, route to Claude backend — or vice versa)
- Load-balances across multiple accounts with round-robin
- Supports streaming (SSE), function calling, multimodal input, and tool use

### Supported Providers

| Provider | Auth Source | API Endpoint |
|----------|-----------|-------------|
| Claude (Anthropic) | `claude auth login` OAuth | `api.anthropic.com` |
| Codex (OpenAI) | `codex login` OAuth | `chatgpt.com/backend-api/codex` |
| Gemini (Google) | `gemini login` OAuth | `cloudcode-pa.googleapis.com` |
| Qwen | `qwen login` OAuth | Qwen API |
| iFlow | iFlow OAuth | iFlow API |
| Antigravity | Antigravity auth | Antigravity API |

### Quick Setup

```bash
# Install
go install github.com/router-for-me/CLIProxyAPI/v6/cmd/cli-proxy-api@latest

# Or Docker
docker run -p 8317:8317 -v ~/.cli-proxy-api:/root/.cli-proxy-api ghcr.io/router-for-me/cliproxyapi

# Login to providers (same CLI login you already use)
claude auth login    # stores Claude OAuth tokens
codex login          # stores Codex OAuth tokens
gemini login         # stores Gemini OAuth tokens

# Start the proxy
cli-proxy-api
```

### Usage with SDKs

Once running, point any SDK at the proxy:

```python
# Python — Anthropic SDK
import anthropic
client = anthropic.Anthropic(
    api_key="your-proxy-api-key",
    base_url="http://localhost:8317"
)

# Python — OpenAI SDK
from openai import OpenAI
client = OpenAI(
    api_key="your-proxy-api-key",
    base_url="http://localhost:8317/v1"
)
```

```javascript
// Node.js — OpenAI SDK
import OpenAI from 'openai';
const client = new OpenAI({
    apiKey: 'your-proxy-api-key',
    baseURL: 'http://localhost:8317/v1'
});
```

### Key Features

**Multi-account load balancing:**
Login with multiple accounts. The proxy round-robins requests across them to distribute load and avoid rate limits.

**Model routing:**
Map model names to specific providers. Send `gpt-4o` and have it routed to Claude, or vice versa.

**Format translation:**
Send requests in OpenAI format, route to Claude backend. The proxy translates request/response formats transparently.

**Production deployment:**
Docker support, TLS, Postgres-backed token storage, management API with web control panel, request retry with credential rotation.

## Comparison Table

| Aspect | Direct CLI | CC-Bridge | CLIProxyAPI |
|--------|-----------|-----------|-------------|
| **Invocation** | `claude -p` / `codex exec` | HTTP → `claude -p` subprocess | HTTP → direct API call |
| **Auth** | CLI's own OAuth | CLI's own OAuth | Extracted CLI OAuth tokens |
| **Multi-provider** | One CLI at a time | Claude only | Claude, Codex, Gemini, Qwen, + |
| **Multi-account** | No | No | Yes (round-robin) |
| **SDK compatible** | No | Yes (Anthropic only) | Yes (OpenAI/Claude/Gemini) |
| **Format translation** | No | No | Yes (cross-format) |
| **Streaming** | NDJSON stdout | SSE | SSE |
| **Process overhead** | One process per call | One process per call | None (direct HTTP) |
| **Complexity** | Low | Medium | High |
| **Best for** | Scripts, CI/CD, agents | Learning, local dev | Production apps, multi-tenant |

## When Direct CLI Scripting Is Better

CLIProxyAPI is powerful, but direct CLI scripting (what this repo primarily teaches) is better when:

- **You need structured output** — `--json-schema` (Claude) and `--output-schema` (Codex) enforce JSON schemas at the CLI level. The proxy doesn't add this capability.
- **You need multi-agent orchestration** — Spawning parallel CLI processes with different system prompts (like our debate engine) is a CLI-native pattern. The proxy is request/response.
- **You're building CI/CD pipelines** — GitHub Actions, GitLab CI, etc. run shell commands natively. Adding an HTTP proxy server is unnecessary complexity.
- **You need agent-level tool execution** — CLI agents can read files, write code, and execute commands. The proxy only exposes chat/completion capabilities.
- **You want simplicity** — `echo "Review this" | claude -p` is one line. Setting up a proxy server is many.

## When CLIProxyAPI Is Better

Use the proxy when:

- **Your app already uses an AI SDK** — just change `base_url` and everything works
- **You need to switch providers transparently** — send OpenAI format, route to Claude
- **You need multi-account load balancing** — distribute across team accounts
- **You're building a multi-tenant service** — one proxy, many consumers
- **You want to avoid per-request process spawning overhead**
