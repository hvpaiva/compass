---
name: compass-research
description: "Investigate a domain topic with cited sources. Produces structured research dossier."
argument-hint: "<topic>"
---

# /compass:research

Investigate a domain topic and produce a structured research dossier with cited sources.

This command can be invoked multiple times — once per topic. Each invocation produces
one dossier in `.compass/RESEARCH/`.

## Pre-flight

1. Run `~/.claude/compass/scripts/compass-tools.sh preflight research` to verify:
   - `.compass/FRAMING.md` exists (if not, suggest `/compass:frame` first)
2. If no `$ARGUMENTS` (topic) provided, use AskUserQuestion with **multiSelect: true**
   to let the user pick one or more topics at once:
   ```
   header: "Topics"
   question: "Which topics do you want to research?"
   multiSelect: true
   options: [derive 2-4 topics from FRAMING.md gaps, risks, and unknowns]
   ```
   The user can also type a custom topic via the "Other" option.
   Run one research agent per selected topic (in parallel when possible).

## Required reading

Load before proceeding:

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/FRAMING.md` (to understand project context)
- `.compass/BASELINE.md` (if exists — for existing project context)
- `.compass/RESEARCH/*.md` (scan existing dossiers to avoid duplication)

## Execution

For **each** selected topic, spawn a `domain-researcher` agent. When there are multiple
topics, launch all agents **in parallel** (one Agent tool call per topic in the same message).

Pre-assign dossier numbers sequentially before spawning (e.g., if the next number is 003
and the user picked 3 topics, assign 003, 004, 005) to avoid race conditions.

```
Agent(
  subagent_type: "general-purpose"
  description: "Research: {topic}"
  prompt: |
    You are the COMPASS domain-researcher agent.

    <required_reading>
    - ~/.claude/compass/agents/domain-researcher.md (read this FIRST — it defines your role and constraints)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/FRAMING.md
    - .compass/BASELINE.md (if exists)
    </required_reading>

    Research topic: {topic}

    Project context: [summarize FRAMING.md key points — mission, scope, constraints]

    Produce a research dossier at: .compass/RESEARCH/dossier-{NNN}-{slug}.md
    (your assigned number is {NNN} — do not change it).

    Use the template at ~/.claude/compass/templates/RESEARCH-DOSSIER.md for structure.

    After writing the dossier, output a one-paragraph summary of key findings.
)
```

## Post-execution

1. Read all produced dossiers and present a summary of each to the user.
2. Run `~/.claude/compass/scripts/compass-tools.sh session update` to record progress.
3. Ask the user what to do next (as a regular text message, not AskUserQuestion):
   - Research another topic
   - Review/revise a dossier
   - Move to architecture — `/compass:architect`
   - Check status — `/compass:status`
4. Suggest `/clear` before starting a new phase.
