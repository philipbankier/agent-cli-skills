#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# Free-Tier Batch Analyzer — Gemini CLI
#
# Processes an entire directory of files through Gemini's free tier,
# with built-in rate limiting to stay within quotas.
#
# Usage:
#   ./batch-analyze.sh src "*.py" "List all functions and their docstrings"
#   ./batch-analyze.sh . "*.ts" "Check for security vulnerabilities"
#   ./batch-analyze.sh docs "*.md" "Summarize this document in one line"
#
# Requirements:
#   - Gemini CLI: npm install -g @google/gemini-cli
#   - Authenticated: gemini login (Google account for full free tier)
#
# Free Tier Limits:
#   - Google Account: 1000 requests/day, 60/minute
#   - API Key (unpaid): 250 requests/day, 10/minute
# ============================================================================

DIR="${1:?Usage: ./batch-analyze.sh <directory> <glob-pattern> <prompt>}"
PATTERN="${2:?Usage: ./batch-analyze.sh <directory> <glob-pattern> <prompt>}"
PROMPT="${3:?Usage: ./batch-analyze.sh <directory> <glob-pattern> <prompt>}"
MODEL="${MODEL:-gemini-2-5-flash}"
MAX_PARALLEL="${MAX_PARALLEL:-5}"
RATE_PAUSE="${RATE_PAUSE:-1}"

OUTDIR=$(mktemp -d)
trap 'rm -rf "$OUTDIR"' EXIT

echo "=== Gemini Free-Tier Batch Analyzer ==="
echo "Directory: $DIR"
echo "Pattern:   $PATTERN"
echo "Model:     $MODEL"
echo "Parallel:  $MAX_PARALLEL"
echo "Output:    $OUTDIR/"
echo ""

# --- Collect files ---
FILES=()
while IFS= read -r -d '' f; do
  FILES+=("$f")
done < <(find "$DIR" -name "$PATTERN" -type f -print0 | sort -z)

TOTAL=${#FILES[@]}

if [ "$TOTAL" -eq 0 ]; then
  echo "No files found matching $PATTERN in $DIR"
  exit 1
fi

echo "Found $TOTAL files to process."
echo ""

# --- Process files ---
PROCESSED=0
ERRORS=0
BATCH=0

for f in "${FILES[@]}"; do
  name=$(echo "$f" | sed 's/[^a-zA-Z0-9._-]/_/g')
  PROCESSED=$((PROCESSED + 1))

  echo "[$PROCESSED/$TOTAL] $f"

  # Run Gemini on the file
  if gemini -p "$PROMPT" -m "$MODEL" < "$f" > "$OUTDIR/$name.txt" 2>/dev/null; then
    echo "  → OK ($(wc -c < "$OUTDIR/$name.txt" | tr -d ' ') bytes)"
  else
    echo "  → ERROR (exit $?)"
    ERRORS=$((ERRORS + 1))
    echo "ERROR: Exit code $?" > "$OUTDIR/$name.txt"
  fi

  BATCH=$((BATCH + 1))

  # Rate limiting
  if [ $BATCH -ge $MAX_PARALLEL ]; then
    sleep "$RATE_PAUSE"
    BATCH=0
  fi
done

echo ""
echo "=== Summary ==="
echo "Processed: $PROCESSED files"
echo "Errors:    $ERRORS"
echo "Output:    $OUTDIR/"
echo ""

# --- Generate aggregate report ---
echo "Generating aggregate report..."
REPORT="$OUTDIR/_REPORT.md"

{
  echo "# Batch Analysis Report"
  echo ""
  echo "- **Directory**: $DIR"
  echo "- **Pattern**: $PATTERN"
  echo "- **Prompt**: $PROMPT"
  echo "- **Model**: $MODEL"
  echo "- **Files processed**: $PROCESSED"
  echo "- **Errors**: $ERRORS"
  echo ""

  for f in "${FILES[@]}"; do
    name=$(echo "$f" | sed 's/[^a-zA-Z0-9._-]/_/g')
    outfile="$OUTDIR/$name.txt"
    if [ -f "$outfile" ]; then
      echo "## $f"
      echo ""
      cat "$outfile"
      echo ""
      echo "---"
      echo ""
    fi
  done
} > "$REPORT"

echo "Report saved to $REPORT"
echo ""
echo "Quick view: head -50 $REPORT"
