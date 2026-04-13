#!/usr/bin/env bash

# compass-scope-guardian.sh — Claude Code PostToolUse hook
# Triggers on Write/Edit outside .compass/ during build phase.
# Compares changes against SPEC.md, ADRs, and FRAMING.md.
#
# Hook type: PostToolUse
# Matcher: tool_name in ["Write", "Edit"]
#
# This hook injects advisory context — it does not block operations.
# The scope-guardian agent interprets the findings.

# Timeout guard — do not block Claude Code
TIMEOUT_PID=$$
( sleep 8 && kill -0 "$TIMEOUT_PID" 2>/dev/null && kill "$TIMEOUT_PID" ) &
WATCHDOG=$!
trap "kill $WATCHDOG 2>/dev/null" EXIT

# Read hook input from stdin
INPUT=$(cat)

# Extract tool name and file path
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name":"[^"]*"' | head -1 | cut -d'"' -f4)
FILE_PATH=$(echo "$INPUT" | grep -o '"file_path":"[^"]*"' | head -1 | cut -d'"' -f4)

# Only process Write/Edit
case "$TOOL_NAME" in
    Write|Edit) ;;
    *) exit 0 ;;
esac

# Skip if editing inside .compass/
case "$FILE_PATH" in
    */.compass/*) exit 0 ;;
esac

# Find .compass/ directory
COMPASS_DIR=""
DIR="$PWD"
while [[ "$DIR" != "/" ]]; do
    if [[ -d "$DIR/.compass" ]]; then
        COMPASS_DIR="$DIR/.compass"
        break
    fi
    DIR=$(dirname "$DIR")
done

[[ -n "$COMPASS_DIR" ]] || exit 0

# Check if scope guardian is enabled
CONFIG="$COMPASS_DIR/config.yaml"
if [[ -f "$CONFIG" ]]; then
    ENABLED=$(grep -A1 "hooks:" "$CONFIG" | grep "scope_guardian:" | awk '{print $2}')
    [[ "$ENABLED" == "false" ]] && exit 0
fi

# Check if we're in build phase (units exist)
UNITS_DIR="$COMPASS_DIR/UNITS"
[[ -d "$UNITS_DIR" ]] || exit 0
UNIT_COUNT=$(find "$UNITS_DIR" -name 'unit-*.md' 2>/dev/null | wc -l)
[[ $UNIT_COUNT -gt 0 ]] || exit 0

# Check if spec exists
SPEC_FILE="$COMPASS_DIR/SPEC.md"
[[ -f "$SPEC_FILE" ]] || exit 0

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

# Run drift analysis if tools script is available
FILENAME=$(basename "$FILE_PATH")
if [[ -n "$TOOLS_SCRIPT" ]]; then
    DRIFT_OUTPUT=$("$TOOLS_SCRIPT" drift --json 2>/dev/null || true)
    if [[ -n "$DRIFT_OUTPUT" ]]; then
        FILE_COUNT=$(echo "$DRIFT_OUTPUT" | grep -o '"files_changed":[0-9]*' | cut -d: -f2)
        CHANGED=$(echo "$DRIFT_OUTPUT" | grep -o '"changed_files":\[[^]]*\]' | sed 's/"changed_files"://;s/\[//;s/\]//;s/"//g' | tr ',' ', ')
        cat <<EOF
{"additionalContext": "SCOPE GUARDIAN: '$FILENAME' modified outside .compass/ during build phase. Drift analysis: $FILE_COUNT file(s) changed ($CHANGED). Check these against SPEC.md, active ADRs, and FRAMING.md. Report any drift to the user: out-of-scope additions, ADR contradictions, or unspecified behavior."}
EOF
        exit 0
    fi
fi

# Fallback if tools script not found
cat <<EOF
{"additionalContext": "SCOPE GUARDIAN: File '$FILENAME' was modified outside .compass/ during the build phase. Check whether this change aligns with SPEC.md, active ADRs, and FRAMING.md. Report any drift to the user."}
EOF
