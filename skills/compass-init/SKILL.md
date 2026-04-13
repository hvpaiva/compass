---
name: compass-init
description: "Initialize COMPASS for a project. Detects greenfield/brownfield, asks config questions, scaffolds .compass/ directory."
---

# /compass:init

Initialize COMPASS for the current project.

## Required reading

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`

## Pre-checks

1. Check if `.compass/config.yaml` already exists in the project root.
   - If yes: inform the user that COMPASS is already initialized. Show current config.
     Ask if they want to reconfigure. If no, stop.
2. Confirm you have write access to the project root.

## Step 1 — Detect project type

Run `ls` and `git log --oneline -5 2>/dev/null` to assess the project state.

- **Greenfield**: directory is empty or near-empty (no source files, no git history).
- **Brownfield**: existing source files, git history, or documentation found.

Inform the user which type was detected.

## Step 2 — Brownfield analysis (if applicable)

If brownfield detected, ask the user via AskUserQuestion:

```
header: "Baseline"
question: "This project has existing code. Analyze it to create a baseline snapshot?"
options: ["Yes — analyze the codebase", "No — skip baseline analysis"]
```

If yes, spawn the `baseline-analyzer` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Analyze existing codebase for COMPASS baseline"
  prompt: [load ~/.claude/compass/agents/baseline-analyzer.md and include project root path]
)
```

The agent will produce `.compass/BASELINE.md`.

## Step 3 — Configuration questions

Ask each configuration question using AskUserQuestion. Use detected project info
to set intelligent defaults (e.g., detect language from file extensions).

### Question 1 — Project language

```
header: "Language"
question: "Primary project language?"
options: [detected language first, then: "Rust", "Go", "Python", "TypeScript", "Shell"]
```

### Question 2 — Document language

```
header: "Docs lang"
question: "What language should COMPASS artifacts be written in?"
options: [
  "English (Recommended)",
  "Português brasileiro",
  "Español"
]
```

### Question 3 — ADR location

```
header: "ADRs"
question: "Where should Architectural Decision Records be stored?"
options: [".compass/ADR/", "docs/adrs/", "docs/decisions/"]
```

### Question 4 — Spec location

```
header: "Spec"
question: "Where should the specification document live?"
options: [".compass/SPEC.md", "docs/spec.md"]
```

### Question 5 — Socratic intensity

```
header: "Style"
question: "How Socratic should COMPASS be?"
options: [
  "High — almost never gives direction, only asks questions",
  "Balanced — asks first, then gives directional guidance",
  "Low — more direct, less questioning"
]
```

### Question 6 — Scope guardian

```
header: "Guardian"
question: "Enable automatic scope guardian during build phase?"
options: ["Yes — detect drift automatically on every file edit", "No — I will invoke it manually"]
```

### Question 7 — Conventional commits

```
header: "Commits"
question: "Validate conventional commit format?"
options: ["Yes — block non-conventional commits", "No — do not enforce"]
```

### Question 8 — Git tracking

```
header: "Git"
question: "Track .compass/ artifacts in git?"
options: ["Yes — version all COMPASS artifacts", "No — add .compass/ to .gitignore"]
```

## Step 4 — Scaffold .compass/ directory

Run `~/.claude/compass/scripts/compass-tools.sh init <project-root>` with the resolved config values.

This creates:
```
.compass/
├── config.yaml
├── constitution.md    (copy of global constitution)
├── SESSION.md         (empty template)
├── BASELINE.md        (if brownfield analysis was done)
├── RESEARCH/
├── ADR/               (or configured path)
└── UNITS/
```

## Step 5 — Confirm and suggest next step

1. Run `~/.claude/compass/scripts/compass-tools.sh session update` to record progress.
2. Show the user:
   - Summary of configuration choices
   - Directory structure created
   - Location of config.yaml for future changes
3. Suggest: "Project initialized. Next step: `/compass:frame` to define mission, scope, and constraints."
4. Suggest `/clear` before starting `/compass:frame` for a fresh context.
