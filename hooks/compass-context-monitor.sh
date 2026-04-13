#!/usr/bin/env bash

# compass-context-monitor.sh — Claude Code PostToolUse hook
# Monitors context usage and warns when approaching limits.
#
# Hook type: PostToolUse
# Matcher: (all tool uses, debounced internally)
#
# This hook reads the Claude Code statusline metrics and injects
# warnings when context is running low.

# Timeout guard
TIMEOUT_PID=$$
( sleep 5 && kill -0 "$TIMEOUT_PID" 2>/dev/null && kill "$TIMEOUT_PID" ) &
WATCHDOG=$!
trap "kill $WATCHDOG 2>/dev/null" EXIT

# Debounce — only check every 10 tool uses
COUNTER_FILE="/tmp/compass-ctx-counter-$$"
if [[ -f "$COUNTER_FILE" ]]; then
    COUNT=$(cat "$COUNTER_FILE")
    COUNT=$((COUNT + 1))
    echo "$COUNT" > "$COUNTER_FILE"
    [[ $((COUNT % 10)) -eq 0 ]] || exit 0
else
    echo "1" > "$COUNTER_FILE"
    exit 0
fi

# Look for Claude Code context metrics
# The statusline bridge file location varies — check common paths
SESSION_ID="${CLAUDE_SESSION_ID:-unknown}"
METRICS_FILE="/tmp/claude-ctx-${SESSION_ID}.json"

[[ -f "$METRICS_FILE" ]] || exit 0

# Try to read remaining percentage
REMAINING=$(grep -o '"remaining":[0-9.]*' "$METRICS_FILE" 2>/dev/null | head -1 | cut -d: -f2)

[[ -n "$REMAINING" ]] || exit 0

# Convert to integer for comparison
REMAINING_INT=${REMAINING%.*}

if [[ $REMAINING_INT -le 25 ]]; then
    cat <<EOF
{"additionalContext": "COMPASS CONTEXT MONITOR — CRITICAL: Context is at ${REMAINING_INT}% remaining. Save your work: run /compass:next to capture current state, then /clear before continuing. SESSION.md will preserve your position."}
EOF
elif [[ $REMAINING_INT -le 35 ]]; then
    cat <<EOF
{"additionalContext": "COMPASS CONTEXT MONITOR — WARNING: Context is at ${REMAINING_INT}% remaining. Consider finishing current task and running /clear soon. Use /compass:next to see where you are."}
EOF
fi
