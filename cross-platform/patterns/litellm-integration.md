# LiteLLM Integration with CLI Subscriptions

Use your Claude Code and Codex CLI subscriptions as LLM backends for LiteLLM-powered agents — no API keys required.

## Architecture

```
Your Agent (LiteLLM)
    |
    |  litellm.completion(api_base="http://localhost:8317")
    v
CLIProxyAPI (local proxy)
    |
    |  Direct API call using CLI OAuth tokens
    v
Provider API (Anthropic / OpenAI)
```

LiteLLM thinks it's talking to a standard API. CLIProxyAPI handles credential injection transparently.

## Prerequisites

1. **CLI logged in** — at least one of:
   ```bash
   claude auth login    # for Claude models
   codex login          # for OpenAI/GPT models
   ```

2. **CLIProxyAPI running** — see [API Proxy Pattern](api-proxy-pattern.md) for setup:
   ```bash
   # Install and start
   go install github.com/router-for-me/CLIProxyAPI/v6/cmd/cli-proxy-api@latest
   cli-proxy-api
   # Now listening on http://localhost:8317
   ```

3. **LiteLLM installed:**
   ```bash
   pip install litellm
   ```

## Claude Code → LiteLLM

```python
import litellm

response = litellm.completion(
    model="anthropic/claude-sonnet-4-6",
    api_base="http://localhost:8317",
    api_key="your-proxy-key",
    messages=[{"role": "user", "content": "Explain this error: IndexError"}]
)
print(response.choices[0].message.content)
```

With streaming:

```python
response = litellm.completion(
    model="anthropic/claude-sonnet-4-6",
    api_base="http://localhost:8317",
    api_key="your-proxy-key",
    messages=[{"role": "user", "content": "Write a Python web scraper"}],
    stream=True
)
for chunk in response:
    print(chunk.choices[0].delta.content or "", end="")
```

## Codex CLI → LiteLLM

```python
import litellm

response = litellm.completion(
    model="openai/gpt-5.4",
    api_base="http://localhost:8317/v1",
    api_key="your-proxy-key",
    messages=[{"role": "user", "content": "Review this code for bugs"}]
)
print(response.choices[0].message.content)
```

## Using Both Simultaneously

LiteLLM's Router lets you load-balance or fallback between Claude and Codex:

```python
from litellm import Router

router = Router(
    model_list=[
        {
            "model_name": "primary",          # your alias
            "litellm_params": {
                "model": "anthropic/claude-sonnet-4-6",
                "api_base": "http://localhost:8317",
                "api_key": "your-proxy-key",
            },
        },
        {
            "model_name": "primary",          # same alias = fallback
            "litellm_params": {
                "model": "openai/gpt-5.4",
                "api_base": "http://localhost:8317/v1",
                "api_key": "your-proxy-key",
            },
        },
    ],
    fallbacks=[{"primary": ["primary"]}],
)

# LiteLLM routes to Claude first, falls back to GPT if Claude is overloaded
response = router.completion(
    model="primary",
    messages=[{"role": "user", "content": "Analyze this codebase"}]
)
```

## LiteLLM Proxy Server (Team Setup)

For teams, run LiteLLM as a shared proxy in front of CLIProxyAPI:

```yaml
# litellm_config.yaml
model_list:
  - model_name: claude
    litellm_params:
      model: anthropic/claude-sonnet-4-6
      api_base: http://localhost:8317
      api_key: your-proxy-key

  - model_name: gpt
    litellm_params:
      model: openai/gpt-5.4
      api_base: http://localhost:8317/v1
      api_key: your-proxy-key
```

```bash
litellm --config litellm_config.yaml --port 4000
# Team members point their agents at http://your-server:4000
```

## Which Provider to Choose

| Factor | Claude Code (Sonnet/Opus 4.6) | Codex CLI (GPT-5.4) |
|--------|-------------------------------|---------------------|
| **Coding tasks** | Excellent | Excellent |
| **Long context** | 200K tokens | 128K tokens |
| **Structured output** | Native `--json-schema` via CLI | Native `--output-schema` via CLI |
| **Reasoning** | Strong (Opus for hard problems) | Strong (o3 for hard problems) |
| **Cost via subscription** | Included in Claude Code plan | Included in ChatGPT Plus/Pro |
| **Rate limits** | Depends on plan tier | Depends on plan tier |

**Recommendation:** Use both via Router. Claude Sonnet 4.6 as primary (best coding + long context), GPT-5.4 as fallback. If one provider is rate-limited, LiteLLM automatically falls back to the other.

## Environment Variables Pattern

For production agents, use environment variables instead of hardcoded values:

```python
import os
import litellm

response = litellm.completion(
    model=os.getenv("LLM_MODEL", "anthropic/claude-sonnet-4-6"),
    api_base=os.getenv("LLM_API_BASE", "http://localhost:8317"),
    api_key=os.getenv("LLM_API_KEY", "your-proxy-key"),
    messages=[{"role": "user", "content": prompt}]
)
```

```bash
# .env
LLM_MODEL=anthropic/claude-sonnet-4-6
LLM_API_BASE=http://localhost:8317
LLM_API_KEY=your-proxy-key
```

## Limitations

- **No CLI-native features** — Going through CLIProxyAPI → API means you lose CLI-specific features like `--json-schema`, `--tools`, `--permission-mode`. These are CLI flags, not API parameters.
- **Auth token expiry** — CLI OAuth tokens expire. If requests start failing, re-run `claude auth login` or `codex login`.
- **Not for CLI scripting** — If your agent runs shell commands (not API calls), use direct CLI invocation instead. See the [CLI automation guides](../../skills/claude-code/guides/automate-cli.md).
