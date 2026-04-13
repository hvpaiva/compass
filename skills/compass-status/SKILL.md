---
name: compass-status
description: "Full progress panorama across all COMPASS phases, artifacts, and work units."
---

# /compass:status

Comprehensive status view of the entire COMPASS project. Shows every phase,
every artifact, and (in build phase) every work unit.

## Execution

1. Run `compass-tools.sh status --json` for structured state data.
2. Read `.compass/config.yaml` for configuration context.
3. Scan all `.compass/` artifacts.

4. Present the full panorama:

```
## COMPASS Status

### Configuration
- Language: {language}
- ADR path: {path}
- Scope guardian: {on/off}
- Socratic level: {level}

### Phases

| Phase | Status | Artifacts |
|-------|--------|-----------|
| Init | ✓ done | config.yaml, BASELINE.md |
| Frame | ✓ done | FRAMING.md, constitution.md |
| Research | ✓ done | 5 dossiers |
| Architect | ✓ done | ARCHITECTURE.md |
| Decide | ✓ done | 4 ADRs |
| Spec | ✓ done | SPEC.md |
| Build | ● active | 10 units (4 done, 1 in-progress, 5 pending) |

### Research Dossiers
1. dossier-001-{topic} ✓
2. dossier-002-{topic} ✓
3. ...

### ADRs
1. ADR-001-{title} — Accepted
2. ADR-002-{title} — Accepted
3. ADR-003-{title} — Proposed
4. ...

### Work Units (if in build phase)
- [x] unit-001: {title}
- [x] unit-002: {title}
- [~] unit-003: {title} (in progress)
- [ ] unit-004: {title} (pending — depends on unit-003)
- ...

Progress: ████░░░░░░ 4/10 (40%)
Available to start: unit-005, unit-006

### Session
Last activity: {from SESSION.md}
Stopped at: {from SESSION.md}
```

5. If any phase has issues (e.g., ADR in "Proposed" status while build is active),
   flag it:
   ```
   ### Attention
   - ADR-003 is still "Proposed" but build phase is active. Consider finalizing
     with /compass:decide.
   ```

## Design notes

- This is a read-only panorama. No artifacts produced, no state modified.
- Heavier than `/compass:next` — reads more files for the complete picture.
- Useful for orientation after a long break or context clear.
- Run `compass-tools.sh session update` is NOT called — this is read-only.
