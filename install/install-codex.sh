#!/usr/bin/env bash
set -euo pipefail

# Install the Codex CLI automation skill into your project's .agents/skills/ directory.
# Usage: curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-codex.sh | bash

REPO="https://github.com/philipbankier/agent-cli-skills.git"
SKILL_DIR=".agents/skills/codex-cli-automation"
SKILL_PATH="skills/codex-cli"

if [ -d "$SKILL_DIR" ]; then
  echo "Skill already installed at $SKILL_DIR"
  echo "To update, remove it first: rm -rf $SKILL_DIR"
  exit 1
fi

echo "Installing Codex CLI automation skill..."

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
echo "  - Codex CLI: npm install -g @openai/codex"
echo "  - Authenticated: codex login or OPENAI_API_KEY set"
