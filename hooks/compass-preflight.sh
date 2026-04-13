#!/usr/bin/env bash

# compass-preflight.sh — Claude Code PreToolUse hook
# Checks phase prerequisites before /compass:* commands execute.
#
# Hook type: PreToolUse
# Matcher: tool_name == "Skill" and skill name starts with "compass-"
#
# This hook injects advisory context about missing prerequisites.
# It does NOT block execution — the skill itself handles missing prereqs.

# Timeout guard
TIMEOUT_PID=$$
( sleep 5 && kill -0 "$TIMEOUT_PID" 2>/dev/null && kill "$TIMEOUT_PID" ) &
WATCHDOG=$!
trap "kill $WATCHDOG 2>/dev/null" EXIT

# Read hook input
INPUT=$(cat)

# Check if this is a compass skill invocation
SKILL_NAME=$(echo "$INPUT" | grep -o '"skill":"[^"]*"' | head -1 | cut -d'"' -f4)

case "$SKILL_NAME" in
    compass-*) ;;
    *) exit 0 ;;
esac

# Extract phase from skill name
PHASE="${SKILL_NAME#compass-}"

# Find compass-tools.sh
TOOLS_SCRIPT=""
for candidate in \
    "$HOME/.claude/compass/scripts/compass-tools.sh" \
    "$(dirname "$(dirname "$0")")/scripts/compass-tools.sh"; do
    if [[ -x "$candidate" ]]; then
        TOOLS_SCRIPT="$candidate"
        break
    fi
done

[[ -n "$TOOLS_SCRIPT" ]] || exit 0

# Run preflight check
RESULT=$("$TOOLS_SCRIPT" preflight "$PHASE" 2>/dev/null)
[[ $? -eq 0 ]] || exit 0

READY=$(echo "$RESULT" | grep -o '"ready":[a-z]*' | cut -d: -f2)

if [[ "$READY" == "false" ]]; then
    MISSING=$(echo "$RESULT" | grep -o '"missing":\[[^]]*\]' | sed 's/"missing":\[//;s/\]//;s/"//g')
    cat <<EOF
{"additionalContext": "COMPASS PREFLIGHT: Phase '$PHASE' has missing prerequisites: $MISSING. The skill will handle this, but be aware."}
EOF
fi
