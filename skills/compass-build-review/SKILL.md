---
name: compass-build-review
description: "Architectural code review. Check alignment with ADRs, module boundaries, and abstraction fitness."
argument-hint: "[file-or-directory]"
---

# /compass:build-review

Architectural code review. Checks that implementation aligns with ADRs, respects
module boundaries defined in ARCHITECTURE.md, and that abstractions fit the design.

This is NOT a style review or line-by-line nit-pick. It focuses on structural and
architectural concerns.

## Pre-flight

1. If `$ARGUMENTS` provided, use as target. Otherwise, ask:
   ```
   header: "Target"
   question: "What should I review?"
   options: ["Recent changes (git diff)", "Specific file", "Specific directory", "Entire project"]
   ```

## Required reading

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/ARCHITECTURE.md` — the reference for boundaries and structure
- All ADRs — the reference for decisions
- `.compass/SPEC.md` — behavioral expectations

## Execution

Spawn the `review-coach` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Architectural review: {target}"
  prompt: |
    You are the COMPASS review-coach agent.

    <required_reading>
    - ~/.claude/compass/agents/review-coach.md (read FIRST)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/ARCHITECTURE.md
    - All ADRs in configured ADR directory
    - .compass/SPEC.md
    </required_reading>

    Target: {file, directory, or "git diff" for recent changes}

    Review the code for architectural alignment. Report concerns
    without suggesting code changes.
)
```

## Post-execution

Present findings. No artifacts produced — conversational feedback.
Run `~/.claude/compass/scripts/compass-tools.sh session update`.
