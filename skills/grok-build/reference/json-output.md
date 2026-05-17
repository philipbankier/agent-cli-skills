> Part of the [grok-build skill](../SKILL.md).

# Grok Build JSON Output

Output shapes for `--output-format json` and `--output-format streaming-json`.
Last verified against **Grok Build 0.1.211 (2f2cd6d5c2)** on 2026-05-17.

## Final JSON Object

```bash
grok -p "Reply with exactly OK" \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Observed output:

```json
{
  "text": "OK",
  "stopReason": "EndTurn",
  "sessionId": "019e346a-...",
  "requestId": "...",
  "thought": "The user query is: \"Reply with exactly OK\"\n"
}
```

Fields observed locally:

| Field | Meaning |
|---|---|
| `text` | Final assistant message |
| `stopReason` | Stop reason such as `EndTurn` or `Cancelled` |
| `sessionId` | Session id to use with `--resume` |
| `requestId` | Request id for tracing/debugging |
| `thought` | Reasoning/trace text; do not treat it as stable public output |

Use `jq -r '.text'` for the final answer and `jq -r '.sessionId'` for resume.

## Streaming JSONL

```bash
grok -p "Reply with exactly OK" \
  --output-format streaming-json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Observed events were newline-delimited JSON objects:

```jsonl
{"type":"thought","data":"The"}
{"type":"text","data":"OK"}
{"type":"end","stopReason":"EndTurn","sessionId":"...","requestId":"..."}
```

Do not assume `thought` chunking is stable. For scripts that only need the final
assistant answer, accumulate `type == "text"` chunks or use final `json` mode.

## Parsing Patterns

### Extract Final Text

```bash
grok -p "Reply with exactly OK" \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10 |
  jq -r '.text'
```

### Capture Session ID

```bash
session_id=$(
  grok -p "Analyze this repo briefly." \
    --output-format json \
    --disable-web-search \
    --no-plan \
    --max-turns 10 |
    jq -r '.sessionId'
)
```

### Accumulate Streaming Text

```bash
grok -p "Reply with exactly OK" \
  --output-format streaming-json \
  --disable-web-search \
  --no-plan \
  --max-turns 10 |
  jq -r 'select(.type == "text") | .data'
```

## Prompt JSON

Verified local form:

```bash
grok --prompt-json '[{"type":"text","text":"Reply with exactly OK"}]' \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

Unverified/failed forms should not be copied into public docs without a local
smoke test.
