#!/bin/bash
# auto-fix-github-issues skill - Main execution script
# This script is invoked by the /auto-fix-issues command

set -e

SKILL_DIR="$HOME/.claude/skills/auto-fix-github-issues"
CONFIG_FILE="$SKILL_DIR/config.json"
STATE_DIR="$HOME/.claude/state/auto-fix-github-issues"

# Check if gh is available
if ! command -v gh &> /dev/null; then
    echo "Error: GitHub CLI (gh) is not installed"
    exit 1
fi

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "Error: jq is not installed"
    exit 1
fi

# Load configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: config.json not found at $CONFIG_FILE"
    exit 1
fi

enabled=$(jq -r '.enabled' "$CONFIG_FILE")
if [ "$enabled" != "true" ]; then
    echo "auto-fix-github-issues is disabled in config.json"
    exit 0
fi

# Get repositories as array
repos=$(jq -c '.repositories[] | select(.enabled == true)' "$CONFIG_FILE")

if [ -z "$repos" ]; then
    echo "No enabled repositories found in config.json"
    exit 0
fi

echo "[auto-fix-github-issues] Starting..."

# Process each repository
echo "$repos" | jq -r '. | "@ \(.owner)/\(.repo)"' 2>/dev/null | while IFS= read -r repo; do
    owner=$(echo "$repo" | cut -d'/' -f1)
    repo_name=$(echo "$repo" | cut -d'/' -f2)

    echo ""
    echo "=== Processing $owner/$repo_name ==="

    # Fetch open issues sorted by creation time
    issues=$(gh issue list --repo "$owner/$repo_name" --state open --json number,title,body,createdAt --limit 50 2>/dev/null || echo "[]")

    if [ "$issues" == "[]" ] || [ -z "$issues" ]; then
        echo "No open issues found"
        continue
    fi

    # Sort by createdAt
    sorted_issues=$(echo "$issues" | jq 'sort_by(.createdAt)')

    echo "$sorted_issues" | jq -r '.[] | "Issue #\(.number): \(.title)"'
    echo "Found $(echo "$sorted_issues" | jq length) open issues"
    echo "Use Claude Code with the auto-fix-github-issues skill to process these issues"
done

echo ""
echo "[auto-fix-github-issues] Scan complete"