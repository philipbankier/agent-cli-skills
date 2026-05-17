> Part of the [grok-build skill](../SKILL.md).

# Grok Build Code Snippets

Ready-to-run patterns verified or derived from local 2026-05-17 tests against
`grok 0.1.211 (2f2cd6d5c2)`.

## Bash: JSON Smoke Test

```bash
#!/usr/bin/env bash
set -euo pipefail

text=$(
  grok -p "Reply with exactly OK" \
    --output-format json \
    --disable-web-search \
    --no-plan \
    --max-turns 10 |
    jq -r '.text'
)

test "$text" = "OK"
```

## Bash: Resume With Captured Session ID

```bash
#!/usr/bin/env bash
set -euo pipefail

session_id=$(
  grok -p "Remember the word BRAVO. Reply with exactly stored." \
    --output-format json \
    --disable-web-search \
    --no-plan \
    --max-turns 10 |
    jq -r '.sessionId'
)

grok -p "What word did I ask you to remember? Reply with just the word." \
  --resume "$session_id" \
  --output-format plain \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

## Bash: Prompt File

```bash
#!/usr/bin/env bash
set -euo pipefail

prompt_file=$(mktemp)
trap 'rm -f "$prompt_file"' EXIT

printf 'Summarize this repository in three bullets.\n' > "$prompt_file"

grok --prompt-file "$prompt_file" \
  --output-format json \
  --disable-web-search \
  --no-plan \
  --max-turns 10
```

## Bash: Streaming Text Extraction

```bash
grok -p "Reply with exactly OK" \
  --output-format streaming-json \
  --disable-web-search \
  --no-plan \
  --max-turns 10 |
  jq -r 'select(.type == "text") | .data'
```

## Node.js: ACP Initialize

```javascript
import { spawn } from "node:child_process";
import readline from "node:readline";

const proc = spawn("grok", ["agent", "stdio"], {
  stdio: ["pipe", "pipe", "inherit"],
});

const rl = readline.createInterface({ input: proc.stdout });

rl.once("line", (line) => {
  const message = JSON.parse(line);
  console.log(message.result?.protocolVersion);
  console.log(message.result?._meta?.agentVersion);
  proc.kill();
});

proc.stdin.write(JSON.stringify({
  jsonrpc: "2.0",
  id: 1,
  method: "initialize",
  params: {
    protocolVersion: 1,
    clientCapabilities: {},
  },
}) + "\n");
```

## Preflight Checklist

```bash
grok --version
grok inspect
grok models
```

Use the `inspect` output to identify loaded instructions, skills, plugins, hooks,
and MCP servers before interpreting a headless failure.
