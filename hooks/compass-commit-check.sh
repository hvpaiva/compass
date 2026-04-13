#!/usr/bin/env bash

# compass-commit-check.sh — Claude Code PreToolUse hook
# Validates conventional commit format before git commit.
#
# Hook type: PreToolUse
# Matcher: tool_name == "Bash" and command contains "git commit"
#
# OPT-IN: Only active when hooks.commit_check is true in .compass/config.yaml.
# When active, BLOCKS non-conventional commits (exit 2).

# Timeout guard
TIMEOUT_PID=$$
( sleep 5 && kill -0 "$TIMEOUT_PID" 2>/dev/null && kill "$TIMEOUT_PID" ) &
WATCHDOG=$!
trap "kill $WATCHDOG 2>/dev/null" EXIT

# Read hook input
INPUT=$(cat)

# Check if this is a git commit command
COMMAND=$(echo "$INPUT" | grep -o '"command":"[^"]*"' | head -1 | cut -d'"' -f4)

case "$COMMAND" in
    *"git commit"*) ;;
    *) exit 0 ;;
esac

# Find .compass/ and check if commit check is enabled
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

CONFIG="$COMPASS_DIR/config.yaml"
[[ -f "$CONFIG" ]] || exit 0

ENABLED=$(grep -A1 "hooks:" "$CONFIG" | grep "commit_check:" | awk '{print $2}')
[[ "$ENABLED" == "true" ]] || exit 0

# Extract commit message from -m flag
MSG=$(echo "$COMMAND" | grep -oP '(?<=-m\s)["\x27]([^"\x27]*)["\x27]' | tr -d "\"'" | head -1)

# If no -m flag found (might use heredoc or other format), skip validation
[[ -n "$MSG" ]] || exit 0

# Validate conventional commit format
# Pattern: type(scope)?: description
# Types: feat, fix, chore, docs, refactor, test, ci, perf, build, style, revert
PATTERN='^(feat|fix|chore|docs|refactor|test|ci|perf|build|style|revert)(\([a-zA-Z0-9_-]+\))?!?:.+'

if ! echo "$MSG" | grep -qE "$PATTERN"; then
    # Exit 2 = block the tool call
    cat <<EOF
{"error": "COMPASS COMMIT CHECK: Commit message does not follow conventional commits format. Expected: type(scope)?: description. Types: feat, fix, chore, docs, refactor, test, ci, perf, build, style, revert. Got: '$MSG'"}
EOF
    exit 2
fi
