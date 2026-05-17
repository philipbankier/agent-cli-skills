# Grok Build + Codex CLI Expansion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify and document current Grok Build CLI and Codex CLI behavior with local command evidence, official docs, issue trackers, and current community gotchas.

**Architecture:** Treat local CLI behavior as the highest-confidence evidence, official docs as stable source material, and community posts/issues as anecdotal leads unless reproduced. Add Grok Build as a first-class skill only after headless, structured-output, session, ACP, and permission behavior pass local smoke tests.

**Tech Stack:** Markdown skill docs, shell-based CLI verification, JSON/JSONL validation with `jq`/Node where useful, GitHub/npm/web sources for volatile claims.

---

### Task 1: Local Codex CLI Behavior Matrix

**Files:**
- Modify: `docs/audits/2026-05-17-fresh-verification-audit-grok-build-intake.md`
- Modify: `skills/codex-cli/reference/exec-mode-flags.md`
- Modify: `skills/codex-cli/reference/subcommands.md`
- Modify: `skills/codex-cli/reference/json-output.md`
- Modify: `skills/codex-cli/reference/known-issues.md`
- Modify: `skills/codex-cli/SKILL.md`

- [ ] **Step 1: Create a disposable test repo**

Run:

```bash
tmpdir="$(mktemp -d /tmp/agent-cli-skills-codex.XXXXXX)"
cd "$tmpdir"
git init -q
printf 'alpha\nbeta\nTODO: verify me\n' > sample.txt
git add sample.txt
git commit -q -m init
```

- [ ] **Step 2: Capture Codex version and help**

Run:

```bash
codex --version
codex --help
codex exec --help
codex exec resume --help
codex resume --help
codex app-server --help
codex mcp-server --help
codex features --help
```

Expected: commands complete with exit 0 and show the current installed command surface.

- [ ] **Step 3: Verify non-interactive plain, JSONL, `-o`, stdin, and schema output**

Run:

```bash
codex exec "Reply with exactly OK" --ephemeral --sandbox read-only
codex exec "Reply with exactly OK" --ephemeral --sandbox read-only --json > codex-events.jsonl
codex exec "Reply with exactly OK" --ephemeral --sandbox read-only -o codex-final.txt
printf 'one\ntwo\nthree\n' | codex exec "Count the input lines. Reply with just the number." --ephemeral --sandbox read-only
cat > schema.json <<'JSON'
{"type":"object","properties":{"status":{"type":"string"},"count":{"type":"integer"}},"required":["status","count"],"additionalProperties":false}
JSON
codex exec "Return JSON with status ok and count 3" --ephemeral --sandbox read-only --output-schema schema.json -o codex-schema.json
```

Expected: final messages are parseable and JSONL contains current event types.

- [ ] **Step 4: Verify session resume semantics**

Run:

```bash
codex exec "Remember the word ALPHA. Reply with exactly stored." --sandbox read-only --json > codex-session-start.jsonl
codex exec --sandbox read-only resume --last "What word did I ask you to remember? Reply with just the word." -o codex-resume.txt
```

Expected: `codex-resume.txt` contains `ALPHA` or a clear failure that should be documented.

- [ ] **Step 5: Verify safety gotchas**

Run read-only and workspace-write prompts in the disposable repo only. Confirm whether `--full-auto` prints a deprecation warning and whether read-only prevents file writes.

### Task 2: Local Grok Build CLI Behavior Matrix

**Files:**
- Create: `skills/grok-build/SKILL.md`
- Create: `skills/grok-build/reference/cli-flags.md`
- Create: `skills/grok-build/reference/subcommands.md`
- Create: `skills/grok-build/reference/json-output.md`
- Create: `skills/grok-build/reference/known-issues.md`
- Create: `skills/grok-build/reference/code-snippets.md`
- Modify: `docs/audits/2026-05-17-fresh-verification-audit-grok-build-intake.md`

- [ ] **Step 1: Create a disposable test repo**

Run:

```bash
tmpdir="$(mktemp -d /tmp/agent-cli-skills-grok.XXXXXX)"
cd "$tmpdir"
git init -q
printf 'alpha\nbeta\nTODO: verify me\n' > sample.txt
git add sample.txt
git commit -q -m init
```

- [ ] **Step 2: Capture Grok version and help**

Run:

```bash
grok --version
grok --help
grok agent --help
grok agent stdio --help
grok sessions --help
grok memory --help
grok models --help
grok inspect
```

Expected: commands complete with exit 0 and show installed Grok Build `0.1.x` behavior.

- [ ] **Step 3: Verify headless output formats and prompt inputs**

Run:

```bash
grok -p "Reply with exactly OK" --output-format plain --disable-web-search --no-plan --max-turns 10
grok -p "Reply with exactly OK" --output-format json --disable-web-search --no-plan --max-turns 10
grok -p "Reply with exactly OK" --output-format streaming-json --disable-web-search --no-plan --max-turns 10
printf 'Reply with exactly OK\n' > prompt.txt
grok --prompt-file prompt.txt --output-format json --disable-web-search --no-plan --max-turns 10
```

Expected: plain output is `OK`, JSON output is parseable, streaming output is newline-delimited JSON events, and prompt-file works.

- [ ] **Step 4: Verify session and ACP behavior**

Run:

```bash
grok -p "Remember the word BRAVO. Reply with exactly stored." --session-id agent-cli-skills-test --disable-web-search --no-plan --max-turns 10
grok -p "What word did I ask you to remember? Reply with just the word." --resume agent-cli-skills-test --disable-web-search --no-plan --max-turns 10
```

Then initialize `grok agent stdio` with a JSON-RPC `initialize` request and record the protocol version, model metadata, and auth methods.

- [ ] **Step 5: Verify permission, worktree, sandbox, and local-only flags conservatively**

Run help-only checks first. Only run write tests in the disposable repo. Document which flags are verified by behavior versus only exposed by help.

### Task 3: Research Official Docs, Issues, And Community Advice

**Files:**
- Modify: `docs/audits/2026-05-17-fresh-verification-audit-grok-build-intake.md`
- Modify: `skills/codex-cli/reference/known-issues.md`
- Create: `skills/grok-build/reference/known-issues.md`

- [ ] **Step 1: Official docs**

Use official OpenAI Codex docs and xAI Grok Build docs for claims about supported flags, modes, security, and auth.

- [ ] **Step 2: Issue trackers**

Use GitHub issues and releases for Codex regressions, especially resume, app-server, MCP server, sandboxing, and config behavior.

- [ ] **Step 3: Community posts**

Capture community advice as anecdotal unless reproduced locally. Prioritize recent posts about AGENTS.md, skills, worktrees, MCP, approval/sandbox defaults, `/goal`, and Grok Build launch gotchas.

### Task 4: Public Documentation Update

**Files:**
- Modify: `README.md`
- Modify: `cross-platform/comparison.md`
- Modify: `skills/codex-cli/SKILL.md`
- Modify: `skills/codex-cli/reference/exec-mode-flags.md`
- Modify: `skills/codex-cli/reference/subcommands.md`
- Modify: `skills/codex-cli/reference/json-output.md`
- Modify: `skills/codex-cli/reference/known-issues.md`
- Create: `skills/grok-build/SKILL.md`
- Create: `skills/grok-build/reference/cli-flags.md`
- Create: `skills/grok-build/reference/subcommands.md`
- Create: `skills/grok-build/reference/json-output.md`
- Create: `skills/grok-build/reference/known-issues.md`
- Create: `skills/grok-build/reference/code-snippets.md`

- [ ] **Step 1: Update Codex docs**

Bring Codex references from v0.114-era assumptions to verified v0.130 behavior. Prefer explicit sandbox flags over deprecated `--full-auto` recipes.

- [ ] **Step 2: Add Grok Build docs**

Add only verified Grok Build behavior. Mark help-only surfaces as "exposed by help, not workflow-verified."

- [ ] **Step 3: Update cross-platform index**

Add Grok Build where the matrix can make accurate, tested claims and leave unclear comparisons blank or caveated.

### Task 5: Verification

**Files:**
- Modify: no docs unless verification finds a problem.

- [ ] **Step 1: Run syntax and formatting checks**

Run:

```bash
find . -name '*.sh' -print0 | xargs -0 -n1 bash -n
git diff --check
LC_ALL=C rg -n "[^[:ascii:]]" README.md cross-platform skills docs
```

- [ ] **Step 2: Re-read changed docs**

Read the final diff and confirm every public claim is either locally verified, official-doc sourced, issue-sourced, or explicitly marked as anecdotal/community.
