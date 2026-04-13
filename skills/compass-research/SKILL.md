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

1. Run `compass-tools.sh preflight research` to verify:
   - `.compass/FRAMING.md` exists (if not, suggest `/compass:frame` first)
2. If no `$ARGUMENTS` (topic) provided, ask the user:
   ```
   header: "Topic"
   question: "What topic should I research?"
   options: [suggest topics derived from FRAMING.md gaps and risks, if identifiable]
   ```

## Required reading

Load before proceeding:

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/FRAMING.md` (to understand project context)
- `.compass/BASELINE.md` (if exists — for existing project context)
- `.compass/RESEARCH/*.md` (scan existing dossiers to avoid duplication)

## Execution

Spawn the `domain-researcher` agent for the actual research work:

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
    where {NNN} is the next dossier number (check existing files in .compass/RESEARCH/).

    Use the template at ~/.claude/compass/templates/RESEARCH-DOSSIER.md for structure.

    After writing the dossier, output a one-paragraph summary of key findings.
)
```

## Post-execution

1. Read the produced dossier and present a summary to the user.
2. Run `compass-tools.sh session update` to record progress.
3. Ask the user:
   ```
   header: "Research"
   question: "What next?"
   options: [
     "Research another topic",
     "Review/revise this dossier",
     "Move to architecture — /compass:architect",
     "Check status — /compass:status"
   ]
   ```
4. Suggest `/clear` before starting a new phase.
