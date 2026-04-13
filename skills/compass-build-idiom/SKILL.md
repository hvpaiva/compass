---
name: compass-build-idiom
description: "Language-aware idiom check. Reads code, identifies anti-patterns, gives directional guidance without code."
argument-hint: "[file-or-directory]"
---

# /compass:build-idiom

Review code the human has written for idiomatic patterns in the project's
primary language. Point out anti-patterns and give directional guidance —
without writing or suggesting specific code.

## Pre-flight

1. Read `compass-tools.sh config get project.language` to know the target language.
2. If `$ARGUMENTS` provided, use as target path. Otherwise, ask:
   ```
   header: "Target"
   question: "What should I review for idioms?"
   options: ["Recent changes (git diff)", "Specific file", "Specific directory"]
   ```

## Required reading

- `~/.claude/compass/constitution.md`
- `~/.claude/compass/references/inverted-contract.md`
- `.compass/config.yaml`

## Execution

Spawn the `idiom-checker` agent:

```
Agent(
  subagent_type: "general-purpose"
  description: "Idiom check: {target}"
  prompt: |
    You are the COMPASS idiom-checker agent.

    <required_reading>
    - ~/.claude/compass/agents/idiom-checker.md (read FIRST)
    - ~/.claude/compass/references/inverted-contract.md
    - .compass/config.yaml
    </required_reading>

    Language: {language from config}
    Target: {file, directory, or "git diff HEAD~1" for recent changes}

    Read the target code and review for idiomatic patterns.
    Report findings as directional guidance without code.
)
```

## Post-execution

Present findings to the user. No artifacts produced — this is conversational
feedback. Run `compass-tools.sh session update`.
