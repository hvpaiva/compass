---
name: compass-build-transform
description: "Mechanical text transformations. Executes repetitive, non-creative edits described as unambiguous rules."
argument-hint: "<description-of-transformation>"
---

# /compass:build-transform

Execute mechanical text transformations — repetitive, non-creative edits that
the human describes as an unambiguous rule.

This is the ONLY COMPASS command that modifies project source files.

## Required reading

- `~/.claude/compass/constitution.md` (Article 1.3 — mechanical editing exception)
- `~/.claude/compass/references/inverted-contract.md`

## Gate: Is this mechanical?

Before executing ANY transformation, evaluate against the constitution's
mechanical editing criteria:

1. **Repetitive?** The same operation applied across multiple locations.
2. **Non-creative?** No design, architectural, or logical judgment involved.
3. **Mechanically describable?** The human can express it as an unambiguous rule.

If ALL three are true → proceed.
If ANY is false → refuse and explain why:
"This transformation requires judgment about {design/architecture/logic},
which makes it production code under the COMPASS constitution. You'll need
to implement this yourself."

### Examples of ALLOWED transformations

- "Replace all single quotes with double quotes in src/config.rs"
- "Add trailing commas to every line in this enum block"
- "Convert this pasted list into enum variants following the existing pattern"
- "Rename `old_name` to `new_name` in all files under src/"
- "Reorder imports alphabetically in this file"
- "Convert tabs to spaces in these files"
- "Add `#[derive(Debug)]` to every struct in this module"

### Examples of REFUSED transformations

- "Implement error handling for this function" (requires logic judgment)
- "Refactor this into smaller functions" (requires design judgment)
- "Add validation to these inputs" (requires deciding what to validate)
- "Convert this to use async" (requires architectural judgment)
- "Fix the bug in this function" (requires understanding and solving)

## Execution

1. Confirm the transformation with the user: "I understand you want to {X}
   across {Y}. Is that correct?"
2. Show a preview of what will change (first 3-5 instances).
3. Ask for confirmation before applying.
4. Apply the transformation using Edit/Write tools.
5. Show summary: N files modified, M changes made.

## Post-execution

Run `compass-tools.sh session update` to note the transformation in SESSION.md.
