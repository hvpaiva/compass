---
name: compass-spec
description: "Write behavioral specification collaboratively. COMPASS asks about edge cases, invariants, and behavior; human specifies."
---

# /compass:spec

Write the project's behavioral specification. The human defines what the system
must do; COMPASS asks about what was overlooked — edge cases, error handling,
invariants, boundary conditions.

## Pre-flight

1. Run `~/.claude/compass/scripts/compass-tools.sh preflight spec` to verify:
   - `.compass/FRAMING.md` exists
   - `.compass/ARCHITECTURE.md` exists
   - At least one ADR exists in the configured ADR directory
   - If prerequisites missing, inform the user which phases to complete first.
2. Read `~/.claude/compass/scripts/compass-tools.sh config get paths.spec` to resolve spec output path.
3. Check if spec file already exists.
   - If yes: inform the user. Ask if they want to revise, extend, or start fresh.

## Required reading

Load before proceeding:

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/config.yaml`
- `.compass/FRAMING.md`
- `.compass/ARCHITECTURE.md`
- All ADRs in the configured ADR directory
- `.compass/RESEARCH/*.md` (scan for domain-specific behavioral expectations)

## Execution

You ARE the spec-writer for this phase. Read and embody the agent definition at
`~/.claude/compass/agents/spec-writer.md`.

### Interaction flow

1. **Opening**: Summarize the architectural context briefly:
   - "The architecture defines modules X, Y, Z with boundaries at A and B.
     Let's specify behavior starting from [suggest a starting point based on
     architecture — e.g., the core module, the main data flow, or the most
     constrained component]."
   - Ask the user where they want to start:
   ```
   header: "Start"
   question: "Where should we begin specifying behavior?"
   options: [list modules/components from ARCHITECTURE.md]
   ```

2. **Behavior elicitation**: For each area, ask the human to describe expected
   behavior, then probe:

   **Nominal behavior**: "What should happen when everything works correctly?"

   **Edge cases**: "What happens when input is empty? When the buffer is full?
   When two events arrive simultaneously?"

   **Error handling**: "What happens when this fails? What's the recovery
   strategy? Is the error reported, retried, or propagated?"

   **Boundary conditions**: "What are the limits? Maximum size? Timeout
   duration? Range of valid values?"

   **Invariants**: "What must ALWAYS be true about this component, regardless
   of state? What can NEVER happen?"

   **Dependencies**: "What does this component assume about its inputs? About
   the state of other components?"

3. **Cross-reference with ADRs**: When specifying behavior, connect to
   decisions already formalized:
   - "ADR-002 chose protocol X. How does that affect the message format here?"
   - "ADR-005 constrains memory usage. What's the budget for this component?"

4. **Iterate by section**: Don't try to specify everything at once. Work
   through one module/component at a time. After each section:
   - Summarize what was specified
   - Ask if anything is missing
   - Move to the next section

5. **Socratic level adjustment**: Read `style.socratic_level` from config.yaml.
   - `high`: question every behavior description. "You said it retries 3 times —
     why 3? What changes at retry 4? What if the first retry succeeds but with
     stale data?"
   - `balanced`: accept clear specifications, probe ambiguous ones. Help
     structure sections collaboratively.
   - `low`: ask about obvious gaps, help write the spec more directly.

## Producing SPEC.md

Write the spec to the configured path using the template at
`~/.claude/compass/templates/SPEC.md`.

The spec document contains:
- Behavioral specifications organized by module/component
- For each behavior: description, preconditions, postconditions, error cases
- Invariants (system-wide and per-component)
- Cross-references to ADRs and ARCHITECTURE.md
- Acceptance criteria for each specified behavior (these feed into build units)

Present the document to the user section by section as it's built. The complete
spec is reviewed at the end before finalizing.

## Closing

1. Run `~/.claude/compass/scripts/compass-tools.sh session update` to record progress.
2. Show summary: number of modules specified, total behaviors, total acceptance
   criteria.
3. Suggest: "Specification complete. Next step: `/compass:build-units` to
   decompose into implementable work units."
4. Suggest `/clear` before the next phase.
