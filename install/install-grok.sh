#!/usr/bin/env bash
set -euo pipefail

# Install the Grok Build automation skill into your project's .grok/skills/ directory.
# Usage: curl -fsSL https://raw.githubusercontent.com/philipbankier/agent-cli-skills/main/install/install-grok.sh | bash

REPO="https://github.com/philipbankier/agent-cli-skills.git"
SKILL_DIR=".grok/skills/grok-build-automation"
SKILL_PATH="skills/grok-build"

if [ -d "$SKILL_DIR" ]; then
  echo "Skill already installed at $SKILL_DIR"
  echo "To update, remove it first: rm -rf $SKILL_DIR"
  exit 1
fi

echo "Installing Grok Build automation skill..."

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
echo "Grok Build will discover the skill from .grok/skills/."
echo ""
echo "Prerequisites:"
echo "  - Grok Build: curl -fsSL https://x.ai/cli/install.sh | bash"
echo "  - Authenticated: grok login or GROK_CODE_XAI_API_KEY set"
