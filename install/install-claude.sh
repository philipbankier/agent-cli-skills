#!/usr/bin/env bash
set -euo pipefail

# Install the Claude Code automation skill into your project's .claude/skills/ directory.
# Usage: curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-claude.sh | bash

REPO="https://github.com/philipbankier/agent-cli-skills.git"
SKILL_DIR=".claude/skills/claude-code-automation"
SKILL_PATH="skills/claude-code"

if [ -d "$SKILL_DIR" ]; then
  echo "Skill already installed at $SKILL_DIR"
  echo "To update, remove it first: rm -rf $SKILL_DIR"
  exit 1
fi

echo "Installing Claude Code automation skill..."

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

git clone --filter=blob:none --sparse --depth 1 "$REPO" "$TMPDIR/repo" 2>/dev/null
cd "$TMPDIR/repo"
git sparse-checkout set "$SKILL_PATH" 2>/dev/null

cd - > /dev/null
mkdir -p "$(dirname "$SKILL_DIR")"
cp -r "$TMPDIR/repo/$SKILL_PATH" "$SKILL_DIR"

echo ""
echo "Installed to $SKILL_DIR"
echo "Your agent will automatically discover the skill when it encounters relevant tasks."
echo ""
echo "Prerequisites:"
echo "  - Claude Code CLI: npm install -g @anthropic-ai/claude-code"
echo "  - Authenticated: claude auth status"
