---
name: compass-build-ready
description: "Check readiness before implementing a work unit. Verify dependencies, prerequisites, and context."
argument-hint: "<unit-number>"
---

# /compass:build-ready

Verify that everything is in place before the human starts implementing a work unit.

## Pre-flight

1. If no `$ARGUMENTS` (unit number) provided, list available units from
   `.compass/UNITS/` and ask:
   ```
   header: "Unit"
   question: "Which unit are you about to implement?"
   options: [list pending/in-progress units with titles]
   ```

## Required reading

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/UNITS/unit-{NNN}-*.md` (the target unit)
- All dependency units referenced by the target unit
- `.compass/SPEC.md` — sections referenced by the unit
- ADRs referenced by the unit

## Execution

Spawn the `readiness-checker` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Readiness check for unit {NNN}"
  prompt: |
    You are the COMPASS readiness-checker agent.

    <required_reading>
    - ~/.claude/compass/agents/readiness-checker.md (read FIRST)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/UNITS/unit-{NNN}-*.md (target unit)
    - Dependency unit files referenced in the target unit
    - .compass/SPEC.md sections referenced by the unit
    - ADRs referenced by the unit
    </required_reading>

    Check readiness for unit {NNN}. Verify:
    1. All dependency units are marked "done"
    2. Required source files/modules exist (if unit depends on prior work)
    3. Tests for dependency units pass (run test commands if available)
    4. No open questions remain unresolved in the unit file
    5. Referenced ADRs are in "Accepted" status

    Report: ready/not-ready with specific blockers if any.
)
```

## Post-execution

Present the readiness report. If ready, suggest the human begin implementing.
If not, list specific blockers and how to resolve them.

Update the unit status to `in-progress` via `~/.claude/compass/scripts/compass-tools.sh unit update-status {NNN} in-progress`
if the human confirms they're starting.

Run `~/.claude/compass/scripts/compass-tools.sh session update` to record progress.
