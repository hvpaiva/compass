---
name: compass-decide
description: "Formalize architectural decisions as ADRs in MADR format. Human decides; COMPASS structures."
argument-hint: "[decision-title]"
---

# /compass:decide

Formalize an architectural decision as an ADR (Architectural Decision Record) in
MADR format.

This command can be invoked multiple times — once per decision. Each invocation
produces one ADR file.

## Pre-flight

1. Run `~/.claude/compass/scripts/compass-tools.sh preflight decide` to verify:
   - `.compass/FRAMING.md` exists
   - `.compass/ARCHITECTURE.md` exists (warn if missing but don't block — some
     decisions may precede full architecture)
2. Read `~/.claude/compass/scripts/compass-tools.sh config get paths.adr` to resolve ADR output directory.
3. List existing ADRs in the output directory to show context.

## Required reading

Load before proceeding:

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/config.yaml`
- `.compass/FRAMING.md`
- `.compass/ARCHITECTURE.md` (if exists)
- Existing ADRs in the configured ADR directory (scan titles to avoid duplication)

## Execution

You ARE the adr-scribe for this phase. Read and embody the agent definition at
`~/.claude/compass/agents/adr-scribe.md`.

### Interaction flow

1. **Identify the decision**: If `$ARGUMENTS` contains a decision title, start with
   that. Otherwise, ask:

   If ARCHITECTURE.md exists and mentions unformalized decisions:
   ```
   header: "Decision"
   question: "Which decision should we formalize?"
   options: [list decisions noted in ARCHITECTURE.md that don't have ADRs yet]
   ```

   Otherwise, ask via free text: "What decision do you want to formalize?"

2. **Understand the context**: Ask about the context that led to this decision:
   - "What problem or need does this decision address?"
   - "What constraints shape this decision?" (connect to FRAMING.md if relevant)

3. **Explore alternatives**: Use AskUserQuestion to surface what was considered:
   ```
   header: "Alternatives"
   question: "What alternatives did you consider?"
   options: [if research dossiers mention alternatives for this topic, list them]
   ```
   For each alternative the human mentions, ask:
   - "Why was this rejected?"
   - "What would have to change for this to become viable?"

4. **Clarify the decision**: Confirm the actual decision clearly:
   - "So the decision is: [restate]. Is that accurate?"
   - "Is this decision reversible? What would trigger reconsideration?"

5. **Identify consequences**: Ask about impact:
   - "What does this decision enable?"
   - "What does it prevent or make harder?"
   - "Which components or modules are affected?"

6. **Link to artifacts**: Connect to existing COMPASS artifacts:
   - Which FRAMING.md constraints does this address?
   - Which research dossiers informed this?
   - Which parts of ARCHITECTURE.md does this affect?

## Producing the ADR

1. Get the next ADR number: run `~/.claude/compass/scripts/compass-tools.sh adr next-number`.
2. Write the ADR using the template at `~/.claude/compass/templates/ADR.md`.
3. Place it in the configured ADR directory (from `config.yaml`).
4. Present the ADR to the user for review before finalizing.

The ADR filename format: `ADR-{NNN}-{kebab-case-title}.md`

## Closing

1. Run `~/.claude/compass/scripts/compass-tools.sh session update` to record progress.
2. Show the ADR summary.
3. Ask:
   ```
   header: "Next"
   question: "What next?"
   options: [
     "Formalize another decision",
     "Review existing ADRs",
     "Move to specification — /compass:spec (suggest /clear first)",
     "Check status — /compass:status"
   ]
   ```
