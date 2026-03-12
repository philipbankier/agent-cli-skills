# Gemini CLI Headless Mode Flags

Complete reference for Gemini CLI non-interactive (headless) mode flags.

## Core Flags

| Flag | Short | Description | Default |
|------|-------|-------------|---------|
| `-p <prompt>` | `--prompt` | Run in headless mode with the given prompt | — |
| `-y` | `--yes` | Auto-approve all actions without prompting | Off |
| `-m <model>` | `--model` | Select the model to use | gemini-2-5-pro |
| `--output-format <fmt>` | — | Output format: `text`, `json`, `jsonl` | `text` |
| `-f` | `--free` | Key-free mode (Google account auth) | — |

## Model Selection

| Model | Flag | Best For |
|---|---|---|
| Gemini 2.5 Pro | `-m gemini-2-5-pro` (default) | General-purpose, 1M token context |
| Gemini 2.5 Flash | `-m gemini-2-5-flash` | Speed, lower latency |
| Gemini 3 Pro | `-m gemini-3-pro-preview` | Complex reasoning, agentic coding |
| Auto (Gemini 3) | `-m auto-gemini-3` | System selects best Gemini 3 model |
| Auto (Gemini 2.5) | `-m auto-gemini-2-5` | System selects best Gemini 2.5 model |

## Output Formats

| Format | Flag | Description |
|--------|------|-------------|
| Text | Default (or `--output-format text`) | Plain text response |
| JSON | `--output-format json` | Single JSON object with response, statistics, errors |
| JSONL | `--output-format jsonl` | Streaming newline-delimited JSON events |

### JSON Response Shape

```json
{
  "response": "The main text response",
  "statistics": {
    "model_requests": 3,
    "input_tokens": 1500,
    "output_tokens": 200
  },
  "error": null
}
```

### JSONL Event Types

Each line is a self-contained JSON object. Event types include:
- Session metadata
- Message content chunks
- Tool calls and results
- Aggregated statistics

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error or API failure |
| 42 | Input error (invalid prompt or arguments) |
| 53 | Turn limit exceeded |

## Input Methods

| Method | Example |
|--------|---------|
| Flag | `gemini -p "Your prompt"` |
| Pipe | `echo "prompt" \| gemini` |
| Heredoc | `gemini -p <<< "prompt"` |
| File redirect | `gemini -p "analyze" < file.py` |

## Authentication Flags

| Method | How |
|--------|-----|
| Google OAuth | `gemini login` (interactive, opens browser) |
| API Key (env) | `GEMINI_API_KEY=your-key gemini -p "prompt"` |
| API Key (.env) | Add to `~/.gemini/.env` or `./.gemini/.env` |
| Key-free mode | `gemini -f` or `gemini --free` |

## Flag Interactions

| Combination | Behavior |
|-------------|----------|
| `-p` + piped stdin | Prompt from flag, additional context from stdin |
| `-y` + `-m gemini-2-5-flash` | Fast, fully autonomous (good for batch) |
| `--output-format jsonl` + `-p` | Streaming events in headless mode |
| `-m` + no value | Error — model flag requires a value |

## Rate Limits by Auth Method

| Auth | Requests/Day | Requests/Minute |
|------|-------------|-----------------|
| Google Account | 1000 | 60 |
| API Key (unpaid) | 250 | 10 |
| API Key (paid) | Varies by plan | Varies by plan |
