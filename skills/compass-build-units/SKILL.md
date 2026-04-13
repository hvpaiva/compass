---
name: compass-build-units
description: "Decompose the specification into implementable work units with acceptance criteria and dependencies."
---

# /compass:build-units

Decompose SPEC.md into implementable work units. Each unit is a discrete piece of
work with clear acceptance criteria, dependencies, and scope.

## Pre-flight

1. Run `compass-tools.sh preflight build-units` to verify:
   - `.compass/SPEC.md` (or configured spec path) exists
   - `.compass/ARCHITECTURE.md` exists
   - If prerequisites missing, inform the user which phases to complete first.
2. Check if `.compass/UNITS/` already has unit files.
   - If yes: inform the user. Ask if they want to regenerate, add more, or revise.

## Required reading

Load before proceeding:

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/config.yaml`
- `.compass/FRAMING.md`
- `.compass/ARCHITECTURE.md`
- `.compass/SPEC.md` (full spec — this is the input)
- All ADRs in the configured ADR directory

## Execution

Spawn the `unit-decomposer` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Decompose spec into work units"
  prompt: |
    You are the COMPASS unit-decomposer agent.

    <required_reading>
    - ~/.claude/compass/agents/unit-decomposer.md (read FIRST)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/FRAMING.md
    - .compass/ARCHITECTURE.md
    - .compass/SPEC.md (or configured path)
    - All ADRs in configured ADR directory
    </required_reading>

    Decompose the specification into implementable work units.
    Write each unit to .compass/UNITS/unit-{NNN}-{slug}.md using the template
    at ~/.claude/compass/templates/UNIT.md.

    After writing all units, produce a summary: total units, dependency graph
    (which units must be completed before others), and suggested implementation
    order.
)
```

## Post-execution

1. Read the produced units and present a summary to the user:
   - Total number of units
   - Dependency graph (textual)
   - Suggested implementation order
2. Ask the user to review. They may:
   - Merge units that are too granular
   - Split units that are too large
   - Adjust dependencies
   - Add units that were missed
3. Run `compass-tools.sh session update` to record progress.
4. Suggest: "Work units defined. Use `/compass:build-ready` to check readiness
   before starting a unit, or `/compass:build-progress` to see the full board."
5. Suggest `/clear` before starting implementation.
