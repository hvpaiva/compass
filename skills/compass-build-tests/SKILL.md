---
name: compass-build-tests
description: "Test audit. Reads tests written by the human and identifies coverage gaps."
argument-hint: "[file-or-directory]"
---

# /compass:build-tests

Review tests the human has written. Identify coverage gaps by asking about
untested scenarios. Does not write tests.

## Pre-flight

1. If `$ARGUMENTS` provided, use as target. Otherwise, ask:
   ```
   header: "Target"
   question: "Which tests should I audit?"
   options: ["All tests", "Tests for a specific unit", "Specific test file"]
   ```
2. If "Tests for a specific unit" selected, list units and let user pick.

## Required reading

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/SPEC.md` — acceptance criteria are the benchmark
- The target unit file (if unit-specific audit)

## Execution

Spawn the `test-auditor` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Test audit: {target}"
  prompt: |
    You are the COMPASS test-auditor agent.

    <required_reading>
    - ~/.claude/compass/agents/test-auditor.md (read FIRST)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/SPEC.md (acceptance criteria are your benchmark)
    - .compass/UNITS/unit-{NNN}-*.md (if unit-specific)
    </required_reading>

    Target: {test file, directory, or unit reference}

    Read the tests and compare against the spec's acceptance criteria.
    Report coverage gaps as questions, not as test implementations.
)
```

## Post-execution

Present the audit findings. No artifacts produced — conversational feedback.
Run `compass-tools.sh session update`.
