---
name: compass-build-progress
description: "Track completion across all work units. Shows done, in-progress, and pending units."
---

# /compass:build-progress

Show the current state of all work units: what's done, what's in progress,
and what's pending.

## Required reading

- `.compass/config.yaml`
- All files in `.compass/UNITS/`

## Execution

You ARE the completion-tracker for this command. Read and embody the agent
definition at `~/.claude/compass/agents/completion-tracker.md`.

### Process

1. Run `~/.claude/compass/scripts/compass-tools.sh progress` to get structured progress data.
2. Read all unit files from `.compass/UNITS/` for details.
3. Present a visual summary:

```
## Work Unit Progress

### Done (N/M)
- [x] unit-001: {title}
- [x] unit-003: {title}

### In Progress (N/M)
- [~] unit-002: {title} — {any notes from unit file}

### Pending (N/M)
- [ ] unit-004: {title} — depends on: unit-002
- [ ] unit-005: {title} — depends on: unit-003, unit-004
- [ ] unit-006: {title} — no dependencies (can start anytime)

### Blocked
- [!] unit-007: {title} — blocked by: {open question or missing dependency}

### Summary
{N} of {M} units complete ({percentage}%)
Next available units (no unmet dependencies): unit-006
```

4. If the human asks about a specific unit, show its full details including
   acceptance criteria status.

## No artifacts produced

This is a read-only status view. Run `~/.claude/compass/scripts/compass-tools.sh session update` after.
