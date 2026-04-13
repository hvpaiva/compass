---
name: compass-build-scope
description: "Manual scope guardian invocation. Analyze recent changes for drift against spec, ADRs, and framing."
argument-hint: "[git-ref]"
---

# /compass:build-scope

Manually invoke the scope guardian to analyze recent changes for drift against
the project's specification, ADRs, and framing.

Use this when you want a full drift analysis — not just the brief advisory
from the automatic hook.

## Pre-flight

1. Run `~/.claude/compass/scripts/compass-tools.sh preflight build-scope` to verify:
   - `.compass/SPEC.md` (or configured path) exists
   - At least one ADR exists
2. If `$ARGUMENTS` provided, use as git ref (e.g., `HEAD~3`, a branch name, a commit hash).
   Otherwise, analyze uncommitted changes (`git diff`).

## Required reading

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/config.yaml`

## Execution

1. Run `~/.claude/compass/scripts/compass-tools.sh drift --json` to get structured diff data.
   If a git ref was provided, run `git diff {ref} -- . ':!.compass/'` first and
   pipe to a temp file, then `~/.claude/compass/scripts/compass-tools.sh drift <tempfile> --json`.

2. Spawn the `scope-guardian` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Scope guardian: drift analysis"
  prompt: |
    You are the COMPASS scope-guardian agent.

    <required_reading>
    - ~/.claude/compass/agents/scope-guardian.md (read FIRST)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/FRAMING.md
    - .compass/SPEC.md (or configured path)
    - All ADRs in configured ADR directory
    </required_reading>

    Drift analysis data:
    {paste drift JSON output here}

    For each changed file listed in the drift data, read the file and compare
    its content against:
    1. SPEC.md — is the behavior specified?
    2. ADRs — does it contradict any active decision?
    3. FRAMING.md — does it violate scope or non-goals?

    Produce the FULL scope guardian report (not the brief hook version).
)
```

## Post-execution

Present the full drift report to the user. Run `~/.claude/compass/scripts/compass-tools.sh session update`.
