---
name: compass-next
description: "Where am I? What should I do next? Quick navigation aid based on current project state."
---

# /compass:next

Quick orientation command. Reads the current project state and tells the human
where they are and what the logical next step is.

## Execution

1. Run `~/.claude/compass/scripts/compass-tools.sh status --json` to get full project state.
2. If the command fails (no `.compass/` found), suggest: "No COMPASS project
   found. Run `/compass:init` to get started."

3. Determine the current position by checking artifact existence:

   ```
   No config.yaml         → "Run /compass:init"
   No FRAMING.md          → "Run /compass:frame"
   No RESEARCH/ dossiers  → "Run /compass:research <topic>"
   No ARCHITECTURE.md     → "Run /compass:architect"
   No ADRs                → "Run /compass:decide"
   No SPEC.md             → "Run /compass:spec"
   No UNITS/              → "Run /compass:build-units"
   UNITS exist            → check progress, suggest build sub-commands
   ```

4. Read `SESSION.md` for additional context: where the user stopped last time,
   any notes from the previous session.

5. Present a concise orientation:

   ```
   ## Where you are

   Phase: {current phase}
   Status: {brief description}

   ## What's next

   → {recommended next command with one-line explanation}

   ## Recent activity

   {from SESSION.md — last session summary, 2-3 lines max}
   ```

6. If in the build phase with units, also show a mini progress bar:
   ```
   Units: ████░░░░░░ 4/10 (40%) — 2 available to start
   ```

## Design notes

- This command must be FAST. Minimal reading, no spawning, no heavy analysis.
- It reads state from files and `~/.claude/compass/scripts/compass-tools.sh` — never from conversation memory.
- It works perfectly after a `/clear` because it depends only on `.compass/` files.
- Run `~/.claude/compass/scripts/compass-tools.sh session update` is NOT called — this is read-only.
