# Gemini CLI Extensions

How to build, install, and manage extensions for Gemini CLI.

## What Are Extensions?

Extensions are Gemini CLI's most powerful customization mechanism. Unlike skills (which are documentation-only), extensions are full packages that can bundle:

- **Skills** — Specialized knowledge packages
- **MCP Servers** — Model Context Protocol integrations for external tools
- **Commands** — Custom slash commands
- **Themes** — Visual customization for the TUI
- **Hooks** — Event-driven automation
- **Sub-agents** — Specialized agent configurations

This makes extensions a superset of what Claude Code and Codex CLI call "skills."

## Installing Extensions

```bash
# Install from GitHub
gemini extensions install https://github.com/user/my-extension

# List installed extensions
gemini extensions list

# Check status in interactive mode
/extensions
```

## Extension Directory Structure

```
my-extension/
├── extension.json          # Manifest (required)
├── skills/                 # Agent skills
│   └── my-skill/
│       └── SKILL.md
├── mcp/                    # MCP server configs
│   └── server.json
├── commands/               # Custom slash commands
│   └── my-command.js
├── themes/                 # Visual themes
│   └── dark.json
└── hooks/                  # Event hooks
    └── on-start.sh
```

## The extension.json Manifest

```json
{
  "name": "my-extension",
  "version": "1.0.0",
  "description": "What this extension does",
  "author": "Your Name",
  "skills": ["skills/my-skill"],
  "mcp_servers": ["mcp/server.json"],
  "commands": ["commands/my-command.js"],
  "hooks": {
    "on_start": "hooks/on-start.sh"
  }
}
```

## Skills Within Extensions

Extension skills follow the same format as standalone skills:

```
my-extension/skills/code-reviewer/
├── SKILL.md
├── guides/
│   └── review-patterns.md
└── reference/
    └── checklist.md
```

The SKILL.md uses standard frontmatter:

```yaml
---
name: code-reviewer
description: Review code for bugs, security issues, and quality problems.
---
```

### Skill Activation Flow

1. **Discovery** — CLI scans extension skills at startup, loads metadata
2. **Activation** — Model identifies matching task, calls `activate_skill` tool
3. **Approval** — User confirms skill activation
4. **Injection** — Skill content loaded into context
5. **Execution** — Model follows skill instructions

## MCP Servers in Extensions

Extensions can bundle MCP server configurations:

```json
// mcp/github-server.json
{
  "command": "npx",
  "args": ["@modelcontextprotocol/server-github"],
  "env": {
    "GITHUB_TOKEN": "${GITHUB_TOKEN}"
  }
}
```

This is a key differentiator from Claude Code and Codex CLI, where MCP servers are configured separately in settings files.

## Custom Commands

Add slash commands that users can invoke in the TUI:

```javascript
// commands/review.js
module.exports = {
  name: 'review',
  description: 'Run a code review on the current file',
  execute: async (args, context) => {
    // Command implementation
    return `Reviewing ${args.file}...`;
  }
};
```

## Hooks

Event-driven scripts that run on specific triggers:

```bash
# hooks/on-start.sh — Runs when Gemini CLI starts
#!/usr/bin/env bash
echo "Extension loaded. Type /help for custom commands."
```

## Building an Extension

### Step 1: Scaffold

```bash
mkdir my-extension && cd my-extension
mkdir -p skills/my-skill mcp commands hooks

# Create manifest
cat > extension.json << 'EOF'
{
  "name": "my-extension",
  "version": "0.1.0",
  "description": "My custom Gemini CLI extension",
  "skills": ["skills/my-skill"]
}
EOF

# Create skill
cat > skills/my-skill/SKILL.md << 'EOF'
---
name: my-skill
description: Does something useful.
---

# My Skill

## Quick Start
Ask Gemini to do the thing.
EOF
```

### Step 2: Test Locally

```bash
# Install from local path
gemini extensions install ./my-extension

# Verify it loads
gemini  # Start interactive mode
/extensions  # Check status
```

### Step 3: Publish

Push to GitHub and share the install URL:

```bash
gemini extensions install https://github.com/you/my-extension
```

Extensions can also be published to the community gallery at [geminicli.com/extensions/](https://geminicli.com/extensions/).

## Skill Precedence

When multiple sources provide skills with the same name:

1. **Workspace skills** (`.gemini/skills/`) — highest precedence
2. **User skills** (`~/.gemini/skills/`)
3. **Extension-bundled skills** — lowest precedence

Higher-precedence skills override lower-precedence ones.

## vs. Claude Code and Codex CLI

| Capability | Claude Code | Codex CLI | Gemini CLI |
|---|---|---|---|
| Skills | `.claude/skills/` | `.agents/skills/` | `.gemini/skills/` + extensions |
| MCP Servers | Settings config | Config file | Bundled in extensions |
| Custom commands | — | — | Extensions |
| Themes | — | — | Extensions |
| Hooks | `.claude/hooks/` | — | Extensions |
| Distribution | Git clone | Git clone / skill installer | `gemini extensions install` |

Gemini's extension system is the most comprehensive, bundling capabilities that other CLIs distribute separately.
