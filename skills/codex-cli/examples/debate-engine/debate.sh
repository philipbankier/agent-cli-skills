#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Multi-Perspective Debate Engine — Codex CLI Edition
#
# Spawns 5 AI "debaters" in parallel using codex exec, each with a unique
# perspective. A moderator then synthesizes the arguments.
#
# Usage:
#   ./debate.sh "Should AI replace teachers?"
#   ./debate.sh "Is remote work better than office work?"
#
# Requirements:
#   - Codex CLI: npm install -g @openai/codex
#   - Authenticated: codex login or OPENAI_API_KEY
#   - jq: brew install jq (or apt install jq)
# ============================================================================

TOPIC="${1:?Usage: ./debate.sh \"Your debate topic here\"}"
OUTDIR="/tmp/debate-codex-$(date +%s)"
mkdir -p "$OUTDIR"

echo "=== Multi-Perspective Debate Engine (Codex CLI) ==="
echo "Topic: $TOPIC"
echo "Output: $OUTDIR/"
echo ""

# --- Debater Perspectives ---
declare -A PERSPECTIVES
PERSPECTIVES=(
  ["optimist"]="You are an optimistic futurist who sees transformative potential in new technologies and social changes. Argue in favor with evidence and enthusiasm."
  ["skeptic"]="You are a critical skeptic who identifies risks, unintended consequences, and hidden costs. Argue against with evidence and caution."
  ["historian"]="You are a historian who draws parallels to past technological and social transitions. Provide historical context and lessons learned."
  ["futurist"]="You are a technology futurist focused on emerging trends and 10-year horizons. Predict how this will evolve based on current trajectories."
  ["practitioner"]="You are a hands-on practitioner with real-world experience. Focus on what actually works vs what sounds good in theory."
)

# --- Launch Debaters in Parallel ---
echo "Launching 5 debaters in parallel..."
echo ""

for role in "${!PERSPECTIVES[@]}"; do
  persona="${PERSPECTIVES[$role]}"
  prompt="$persona

Topic: $TOPIC

Provide your argument in this exact JSON format:
{
  \"role\": \"$role\",
  \"position\": \"for or against (one word)\",
  \"argument\": \"Your main argument in 2-3 sentences\",
  \"evidence\": [\"Evidence point 1\", \"Evidence point 2\", \"Evidence point 3\"],
  \"confidence\": 0.0 to 1.0
}

Respond with ONLY the JSON object, no other text."

  codex exec "$prompt" --ephemeral -o "$OUTDIR/$role.txt" &
  echo "  [$role] started (PID $!)"
done

echo ""
echo "Waiting for all debaters..."
wait
echo "All debaters finished."
echo ""

# --- Parse Results ---
echo "=== Individual Arguments ==="
echo ""

COMBINED="["
FIRST=true
for role in "${!PERSPECTIVES[@]}"; do
  file="$OUTDIR/$role.txt"
  if [ -f "$file" ]; then
    # Try to extract JSON from the response
    content=$(cat "$file")
    json=$(echo "$content" | grep -o '{.*}' | head -1 || echo "")

    if [ -n "$json" ] && echo "$json" | jq '.' >/dev/null 2>&1; then
      echo "[$role] $(echo "$json" | jq -r '.position // "unknown"'): $(echo "$json" | jq -r '.argument // "No argument"')"
      if [ "$FIRST" = true ]; then
        COMBINED="$COMBINED$json"
        FIRST=false
      else
        COMBINED="$COMBINED,$json"
      fi
    else
      echo "[$role] (raw response, could not parse JSON)"
      echo "  $content" | head -3
    fi
  else
    echo "[$role] No response"
  fi
  echo ""
done
COMBINED="$COMBINED]"

# Save combined arguments
echo "$COMBINED" | jq '.' > "$OUTDIR/all-arguments.json" 2>/dev/null || echo "$COMBINED" > "$OUTDIR/all-arguments.json"

# --- Moderator Synthesis ---
echo "=== Moderator Synthesis ==="
echo ""

MODERATOR_PROMPT="You are a balanced moderator synthesizing a multi-perspective debate.

Topic: $TOPIC

Arguments from 5 perspectives:
$COMBINED

Synthesize these arguments into a balanced verdict. Consider the strength of each perspective's evidence and reasoning. Provide:
1. A one-paragraph verdict
2. The strongest argument from each side
3. Your recommended course of action

Be concise and balanced."

codex exec "$MODERATOR_PROMPT" --ephemeral -o "$OUTDIR/verdict.txt"

echo ""
cat "$OUTDIR/verdict.txt"
echo ""
echo ""
echo "=== Full results saved to $OUTDIR/ ==="
ls "$OUTDIR/"
