#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Multi-Perspective Debate Engine — Gemini CLI Edition
#
# Spawns 5 AI "debaters" in parallel using gemini -p, each with a unique
# perspective. A moderator then synthesizes the arguments.
#
# Usage:
#   ./debate.sh "Should AI replace teachers?"
#   ./debate.sh "Is remote work better than office work?"
#   ./debate.sh --output-dir ./sample-output "Should AI replace teachers?"
#
# Requirements:
#   - Gemini CLI: npm install -g @google/gemini-cli
#   - Authenticated: gemini login or GEMINI_API_KEY
#   - jq: brew install jq (or apt install jq)
#
# Note: Uses gemini-2-5-flash for debaters (speed) and gemini-2-5-pro for
# the moderator (quality). Each debater uses 1 request from your daily quota.
# ============================================================================

OUTPUT_DIR=""
TOPIC=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      TOPIC="$1"
      shift
      ;;
  esac
done

if [[ -z "$TOPIC" ]]; then
  echo "Usage: ./debate.sh [--output-dir DIR] \"Your debate topic here\""
  exit 1
fi

MODEL_FAST="gemini-2-5-flash"
MODEL_QUALITY="gemini-2-5-pro"

if [[ -n "$OUTPUT_DIR" ]]; then
  mkdir -p "$OUTPUT_DIR"
  OUTDIR="$OUTPUT_DIR"
else
  OUTDIR=$(mktemp -d)
  trap 'rm -rf "$OUTDIR"' EXIT
fi

echo "=== Multi-Perspective Debate Engine (Gemini CLI) ==="
echo "Topic: $TOPIC"
echo "Debaters: $MODEL_FAST | Moderator: $MODEL_QUALITY"
echo "Output: $OUTDIR/"
echo ""

# --- Debater Perspectives ---
ROLES=("optimist" "skeptic" "historian" "futurist" "practitioner")
PERSONAS=(
  "You are an optimistic futurist who sees transformative potential in new technologies and social changes. Argue in favor with evidence and enthusiasm."
  "You are a critical skeptic who identifies risks, unintended consequences, and hidden costs. Argue against with evidence and caution."
  "You are a historian who draws parallels to past technological and social transitions. Provide historical context and lessons learned."
  "You are a technology futurist focused on emerging trends and 10-year horizons. Predict how this will evolve based on current trajectories."
  "You are a hands-on practitioner with real-world experience. Focus on what actually works vs what sounds good in theory."
)

# --- Launch Debaters in Parallel ---
echo "Launching 5 debaters in parallel..."
echo ""

for i in "${!ROLES[@]}"; do
  role="${ROLES[$i]}"
  persona="${PERSONAS[$i]}"

  prompt="${persona}

Topic: ${TOPIC}

Provide your argument in this exact JSON format:
{
  \"role\": \"${role}\",
  \"position\": \"for or against (one word)\",
  \"argument\": \"Your main argument in 2-3 sentences\",
  \"evidence\": [\"Evidence point 1\", \"Evidence point 2\", \"Evidence point 3\"],
  \"confidence\": 0.0 to 1.0
}

Respond with ONLY the JSON object, no other text."

  gemini -p "$prompt" -m "$MODEL_FAST" > "$OUTDIR/$role.txt" &
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
for role in "${ROLES[@]}"; do
  file="$OUTDIR/$role.txt"
  if [ -f "$file" ]; then
    content=$(cat "$file")
    # Extract JSON: try direct parse, then fall back to extracting between { and }
    json=$(jq -c '.' "$file" 2>/dev/null || \
           sed -n '/^{/,/^}/p' "$file" | jq -c '.' 2>/dev/null || \
           echo "")

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

gemini -p "$MODERATOR_PROMPT" -m "$MODEL_QUALITY" | tee "$OUTDIR/verdict.txt"

echo ""
echo ""
echo "=== Full results saved to $OUTDIR/ ==="
ls "$OUTDIR/"
