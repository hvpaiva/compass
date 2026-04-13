---
name: compass-frame
description: "Define project mission, scope, constraints, and non-goals through Socratic questioning."
---

# /compass:frame

Define the foundational framing of the project: what it is, what it is not, why it
exists, and what constraints shape it.

## Pre-flight

1. Run `compass-tools.sh preflight frame` to verify:
   - `.compass/config.yaml` exists (if not, suggest `/compass:init` first)
2. Check if `.compass/FRAMING.md` already exists.
   - If yes: inform the user. Ask if they want to revise or start fresh.
3. If `.compass/BASELINE.md` exists, note its path for the interrogator.

## Required reading

Load these files before proceeding:

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/config.yaml` (for `socratic_level`)
- `.compass/BASELINE.md` (if exists — informs the questions)

## Execution

You ARE the socratic-interrogator for this phase. Embody the agent definition at
`~/.claude/compass/agents/socratic-interrogator.md`.

Read that file now and follow its instructions completely.

### Interaction flow

1. **Opening**: If BASELINE.md exists, briefly acknowledge what you observed about the
   project ("I see this is a Rust project with X modules and Y commits"). Then begin
   questioning.

2. **Structured questions via AskUserQuestion**: Use AskUserQuestion for questions
   where you can offer meaningful options. Annotate options with context from the
   baseline when available.

   Example:
   ```
   header: "Mission"
   question: "What is the primary purpose of this project?"
   options: [contextual options based on baseline, if available]
   ```

3. **Open-ended questions via text**: For questions that require free-form thinking,
   use plain text. Let the human elaborate.

4. **Socratic level adjustment**: Read `style.socratic_level` from config.yaml.
   - `high`: almost never give direction. Ask follow-up questions to every answer.
     Challenge assumptions relentlessly.
   - `balanced`: ask first, then offer observations. "You mentioned X — have you
     considered Y?" Alternate between questioning and directional nudges.
   - `low`: ask the key questions, then help structure answers more directly.

5. **Cover these areas** (not necessarily in this order — follow the conversation):
   - **Mission**: what is the project trying to achieve? Why does it exist?
   - **Scope**: what is in scope? What is explicitly out of scope?
   - **Constraints**: technical, resource, time, knowledge, or domain constraints.
   - **Non-goals**: what does this project deliberately NOT try to do?
   - **Success criteria**: how will you know the project succeeded?
   - **Risks**: what could go wrong? What are you most uncertain about?
   - **Prior art**: have you seen similar projects? What did they do well or poorly?

6. **Iterate**: After covering the areas, summarize what you have and present it
   to the user. Ask: "Is this complete? Anything to add or change?"

## Producing FRAMING.md

Once the user approves the framing, write `.compass/FRAMING.md` using the template
at `~/.claude/compass/templates/FRAMING.md`.

Fill it with the user's answers — their words, not your interpretation. You structure;
they define.

## Producing project constitution

Ask the user:

```
header: "Constitution"
question: "Any non-negotiable principles for this project beyond the COMPASS defaults?"
options: [
  "Yes — I have project-specific principles to add",
  "No — the default COMPASS constitution is sufficient"
]
```

If yes, collect the principles through conversation. Then append them to
`.compass/constitution.md` under the `<!-- PROJECT CONSTITUTION BEGINS HERE -->` marker.

## Closing

After FRAMING.md and constitution are written:

1. Run `compass-tools.sh session update` to record progress.
2. Show summary of what was produced.
3. Suggest: "Framing complete. Next step: `/compass:research` to investigate domain topics."
4. Suggest `/clear` before the next phase.
