#!/usr/bin/env bash
set -euo pipefail

# Install the Gemini CLI automation skill into your project's .gemini/skills/ directory.
# Usage: curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-gemini.sh | bash

REPO="https://github.com/philipbankier/agent-cli-skills.git"
SKILL_DIR=".gemini/skills/gemini-cli-automation"
SKILL_PATH="skills/gemini-cli"

if [ -d "$SKILL_DIR" ]; then
  echo "Skill already installed at $SKILL_DIR"
  echo "To update, remove it first: rm -rf $SKILL_DIR"
  exit 1
fi

echo "Installing Gemini CLI automation skill..."

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
echo "  - Gemini CLI: npm install -g @google/gemini-cli"
echo "  - Authenticated: gemini login or GEMINI_API_KEY set"
