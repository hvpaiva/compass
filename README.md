# COMPASS

**Collaborative Orientation, Mapping, Planning, Architecture, Spec & Supervision**

COMPASS is a Claude Code skill that inverts the typical AI coding workflow:
**the human writes all production code; the LLM acts as senior engineer, orientator,
researcher, and provocateur.**

COMPASS sub-agents are structurally blocked from generating production code. This is
not a guideline — it is enforced at the tools-restriction and system-prompt level in
every sub-agent.

---

## The inverted contract

| Traditional AI coding tools | COMPASS |
|---|---|
| Human defines requirements → LLM implements | Human implements → LLM orients |
| LLM writes code | LLM asks questions, reviews, challenges |
| Human reviews AI output | LLM reviews human output |
| Value: speed of implementation | Value: depth of understanding |

COMPASS exists for developers who want to **learn by building** — not delegate the
building to an AI. The LLM's role is to make the human a better engineer: asking the
hard questions, surfacing blind spots, citing real research, and tracking scope drift.

---

## Setup + six phases

```
init (setup) → frame → research → architect → decide → spec → build
```

| Step | Command | What happens | Who does what |
|---|---|---|---|
| **Init** (setup) | `/compass:init` | Configure COMPASS for this project. Detect greenfield/brownfield. Analyze existing codebase if present. | LLM asks config questions; human chooses. |
| **Frame** | `/compass:frame` | Define mission, scope, constraints, non-goals. | LLM asks probing questions; human defines the project. |
| **Research** | `/compass:research` | Investigate domain topics with cited sources. | LLM researches; human reviews findings and decides what matters. |
| **Architect** | `/compass:architect` | Challenge and document architectural proposals. | Human proposes architecture; LLM challenges with trade-offs. |
| **Decide** | `/compass:decide` | Formalize decisions as ADRs (MADR format). | Human makes decisions; LLM structures them with rationale. |
| **Spec** | `/compass:spec` | Write behavioral specification. | LLM asks about edge cases and invariants; human specifies. |
| **Build** | `/compass:build-*` | Implement against the spec with LLM supervision. | Human writes code; LLM reviews, audits, tracks, questions. |

Each phase produces artifacts in `.compass/`. Nothing advances without explicit human
approval (phase gates). The human may revisit any prior phase at any time.

---

## Build sub-commands

The build phase has specialized tools for different supervision needs:

| Command | Role |
|---|---|
| `/compass:build-units` | Decompose the spec into implementable work units |
| `/compass:build-ready` | Check readiness before implementing a unit |
| `/compass:build-duck` | Rubber duck — think out loud, get questions back |
| `/compass:build-idiom` | Language-aware idiom check (direction without code) |
| `/compass:build-tests` | Test audit — find coverage gaps |
| `/compass:build-review` | Architectural code review against ADRs |
| `/compass:build-progress` | Track completion across all units |
| `/compass:build-transform` | Mechanical text transformations (the only place COMPASS edits project files) |

---

## Navigation

| Command | Purpose |
|---|---|
| `/compass:next` | Where am I? What should I do next? |
| `/compass:status` | Full progress panorama across all phases |

---

## Project state

COMPASS externalizes all state to `.compass/` in the target project:

```
.compass/
├── config.yaml          # COMPASS configuration for this project
├── constitution.md      # Inverted contract + project-specific principles
├── SESSION.md           # Current session state (managed by script)
├── BASELINE.md          # Codebase snapshot (brownfield projects only)
├── FRAMING.md           # Mission, scope, constraints, non-goals
├── RESEARCH/
│   └── dossier-NNN-*.md # Domain research with cited sources
├── ARCHITECTURE.md      # Architectural decisions and structure
├── ADR/                 # Architectural Decision Records (MADR format)
│   └── ADR-NNN-*.md
├── SPEC.md              # Behavioral specification
└── UNITS/               # Implementable work units
    └── unit-NNN-*.md
```

State files are the source of truth — not conversation history. All state mutations
go through `compass-tools.sh` (deterministic, no LLM involved).

---

## Hooks

COMPASS installs Claude Code hooks for automatic supervision:

| Hook | When | What |
|---|---|---|
| **Scope guardian** | After Write/Edit outside `.compass/` | Compares diff against spec, ADRs, framing. Reports drift. |
| **Context monitor** | After every tool use (debounced) | Warns when context is running low. |
| **Pre-flight** | Before any `/compass:*` command | Checks that phase prerequisites are met. |
| **Commit check** | Before `git commit` (opt-in) | Validates conventional commit format. |

---

## The mechanical editing exception

COMPASS agents are blocked from writing production code. The one exception:
**mechanical text transformations** — repetitive, non-creative edits that the human
fully describes as an unambiguous rule.

Examples of allowed transformations:
- Replace `'` with `"` across a file
- Add trailing commas to every line in a block
- Convert a pasted list into enum variants following an existing pattern
- Rename a symbol in N locations
- Reorder imports per a convention

The criterion: if it requires judgment about design, architecture, or logic, COMPASS
will not do it. If it is pure textual manipulation, it will.

---

## Install

```bash
npx compass-cc@latest
```

The installer copies skills, agents, scripts, templates, hooks, and references
to the appropriate locations under `~/.claude/`. It also registers hooks in
`~/.claude/settings.json`.

See `install.sh` for details. Alternative install methods may be added in
the future.

---

## Philosophy

COMPASS is built on ten constitutional articles (see `constitution.md`):

1. **The inverted contract** — human implements, LLM orients
2. **Research precedes opinion** — no recommendation without cited sources
3. **Socratic provocation** — some agents exist to ask, not answer
4. **Externalized, versioned state** — all state in `.compass/`, not in conversation
5. **Fresh sub-agent contexts** — each invocation is stateless
6. **Phase gates with human approval** — nothing advances without human say-so
7. **Mandatory ADRs** — non-trivial decisions formalized in MADR format
8. **Scope guardian always on** — drift detection during build
9. **Deterministic logic in scripts** — bookkeeping by code, not by LLM
10. **Six phases** — frame → research → architect → decide → spec → build
