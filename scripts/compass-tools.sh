#!/usr/bin/env bash

# compass-tools.sh — Deterministic CLI for COMPASS state management.
# No LLM calls. No network. Pure file operations.
#
# Usage: compass-tools.sh <command> [args...]
#
# Commands:
#   status --json         Full project state as JSON
#   preflight <phase>     Check prerequisites for a phase
#   adr next-number       Return next ADR number
#   progress              Unit completion stats
#   drift [--json]        Compare recent diff against spec/ADRs/framing
#   session update        Update SESSION.md with current state
#   unit update-status <unit-number> <status>  Update unit status
#   config get <key>      Read config value (dot notation)
#   config set <key> <val> Write config value
#   init <project-root>   Scaffold .compass/ directory

COMPASS_DIR=""
CONFIG_FILE=""

# --- Utility functions ---

find_compass_dir() {
    local dir="$PWD"
    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/.compass" ]]; then
            COMPASS_DIR="$dir/.compass"
            CONFIG_FILE="$COMPASS_DIR/config.yaml"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

die() {
    echo "error: $1" >&2
    exit 1
}

# Simple YAML value reader — handles flat "key: value" and dotted paths
# Supports: paths.adr, project.language, style.socratic_level, etc.
yaml_get() {
    local file="$1"
    local key="$2"

    [[ -f "$file" ]] || return 1

    # Convert dot notation to nested lookup
    # For "paths.adr", find the "paths:" block then "adr:" within it
    local IFS='.'
    read -ra parts <<< "$key"

    if [[ ${#parts[@]} -eq 1 ]]; then
        grep -E "^${parts[0]}:" "$file" | head -1 | sed 's/^[^:]*:[[:space:]]*//' | sed 's/^"//' | sed 's/"$//'
    elif [[ ${#parts[@]} -eq 2 ]]; then
        awk -v section="${parts[0]}" -v key="${parts[1]}" '
            $0 ~ "^"section":" { in_section=1; next }
            in_section && /^[a-zA-Z]/ { in_section=0 }
            in_section && $0 ~ "^[[:space:]]+"key":" {
                sub(/^[[:space:]]+[^:]+:[[:space:]]+/, "")
                gsub(/^"/, ""); gsub(/"$/, "")
                print
                exit
            }
        ' "$file"
    fi
}

yaml_set() {
    local file="$1"
    local key="$2"
    local value="$3"

    [[ -f "$file" ]] || return 1

    local IFS='.'
    read -ra parts <<< "$key"

    if [[ ${#parts[@]} -eq 1 ]]; then
        sed -i "s|^${parts[0]}:.*|${parts[0]}: ${value}|" "$file"
    elif [[ ${#parts[@]} -eq 2 ]]; then
        # Find the section, then replace the key within it
        awk -v section="${parts[0]}" -v key="${parts[1]}" -v val="$value" '
            $0 ~ "^"section":" { in_section=1; print; next }
            in_section && /^[a-zA-Z]/ { in_section=0 }
            in_section && $0 ~ "^[[:space:]]+"key":" {
                # Preserve indentation
                match($0, /^[[:space:]]+/)
                indent = substr($0, RSTART, RLENGTH)
                print indent key ": " val
                next
            }
            { print }
        ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
}

# --- Commands ---

cmd_status() {
    find_compass_dir || die "no .compass/ directory found"

    local phase="unknown"
    local has_config="false"
    local has_baseline="false"
    local has_framing="false"
    local has_architecture="false"
    local has_spec="false"
    local dossier_count=0
    local adr_count=0
    local unit_total=0
    local unit_done=0
    local unit_progress=0
    local unit_pending=0
    local unit_blocked=0

    [[ -f "$CONFIG_FILE" ]] && has_config="true"
    [[ -f "$COMPASS_DIR/BASELINE.md" ]] && has_baseline="true"
    [[ -f "$COMPASS_DIR/FRAMING.md" ]] && has_framing="true"
    [[ -f "$COMPASS_DIR/ARCHITECTURE.md" ]] && has_architecture="true"

    # Resolve spec path from config
    local spec_path
    spec_path=$(yaml_get "$CONFIG_FILE" "paths.spec" 2>/dev/null)
    spec_path="${spec_path:-.compass/SPEC.md}"
    local project_root="${COMPASS_DIR%/.compass}"
    local has_spec="false"
    [[ -f "$project_root/$spec_path" ]] && has_spec="true"

    # Count research dossiers
    local research_dir
    research_dir=$(yaml_get "$CONFIG_FILE" "paths.research" 2>/dev/null)
    research_dir="${research_dir:-.compass/RESEARCH}"
    if [[ -d "$project_root/$research_dir" ]]; then
        dossier_count=$(find "$project_root/$research_dir" -name 'dossier-*.md' 2>/dev/null | wc -l)
    fi

    # Count ADRs
    local adr_dir
    adr_dir=$(yaml_get "$CONFIG_FILE" "paths.adr" 2>/dev/null)
    adr_dir="${adr_dir:-.compass/ADR}"
    if [[ -d "$project_root/$adr_dir" ]]; then
        adr_count=$(find "$project_root/$adr_dir" -name 'ADR-*.md' 2>/dev/null | wc -l)
    fi

    # Count units by status
    local units_dir
    units_dir=$(yaml_get "$CONFIG_FILE" "paths.units" 2>/dev/null)
    units_dir="${units_dir:-.compass/UNITS}"
    if [[ -d "$project_root/$units_dir" ]]; then
        unit_total=$(find "$project_root/$units_dir" -name 'unit-*.md' 2>/dev/null | wc -l)
        for f in "$project_root/$units_dir"/unit-*.md; do
            [[ -f "$f" ]] || continue
            local status
            status=$(awk '/^## Status/{getline; print; exit}' "$f" | tr -d '[:space:]')
            case "$status" in
                done) ((unit_done++)) ;;
                in-progress) ((unit_progress++)) ;;
                blocked) ((unit_blocked++)) ;;
                *) ((unit_pending++)) ;;
            esac
        done
    fi

    # Determine current phase
    if [[ "$has_config" == "false" ]]; then
        phase="not-initialized"
    elif [[ "$has_framing" == "false" ]]; then
        phase="frame"
    elif [[ $dossier_count -eq 0 ]]; then
        phase="research"
    elif [[ "$has_architecture" == "false" ]]; then
        phase="architect"
    elif [[ $adr_count -eq 0 ]]; then
        phase="decide"
    elif [[ "$has_spec" == "false" ]]; then
        phase="spec"
    elif [[ $unit_total -eq 0 ]]; then
        phase="build-units"
    else
        phase="build"
    fi

    if [[ "$1" == "--json" ]]; then
        cat <<ENDJSON
{
  "phase": "$phase",
  "config": $has_config,
  "baseline": $has_baseline,
  "framing": $has_framing,
  "architecture": $has_architecture,
  "spec": $has_spec,
  "dossiers": $dossier_count,
  "adrs": $adr_count,
  "units": {
    "total": $unit_total,
    "done": $unit_done,
    "in_progress": $unit_progress,
    "pending": $unit_pending,
    "blocked": $unit_blocked
  }
}
ENDJSON
    else
        echo "Phase: $phase"
        echo "Dossiers: $dossier_count | ADRs: $adr_count | Units: $unit_done/$unit_total done"
    fi
}

cmd_preflight() {
    local phase="$1"
    [[ -n "$phase" ]] || die "usage: compass-tools.sh preflight <phase>"

    find_compass_dir || die "no .compass/ directory found — run /compass:init first"

    local project_root="${COMPASS_DIR%/.compass}"
    local missing=()

    case "$phase" in
        init)
            # No prerequisites for init
            ;;
        frame)
            [[ -f "$CONFIG_FILE" ]] || missing+=("config.yaml — run /compass:init")
            ;;
        research)
            [[ -f "$COMPASS_DIR/FRAMING.md" ]] || missing+=("FRAMING.md — run /compass:frame")
            ;;
        architect)
            [[ -f "$COMPASS_DIR/FRAMING.md" ]] || missing+=("FRAMING.md — run /compass:frame")
            local research_dir
            research_dir=$(yaml_get "$CONFIG_FILE" "paths.research" 2>/dev/null)
            research_dir="${research_dir:-.compass/RESEARCH}"
            local count
            count=$(find "$project_root/$research_dir" -name 'dossier-*.md' 2>/dev/null | wc -l)
            [[ $count -gt 0 ]] || missing+=("research dossiers — run /compass:research")
            ;;
        decide)
            [[ -f "$COMPASS_DIR/FRAMING.md" ]] || missing+=("FRAMING.md — run /compass:frame")
            ;;
        spec)
            [[ -f "$COMPASS_DIR/FRAMING.md" ]] || missing+=("FRAMING.md — run /compass:frame")
            [[ -f "$COMPASS_DIR/ARCHITECTURE.md" ]] || missing+=("ARCHITECTURE.md — run /compass:architect")
            local adr_dir
            adr_dir=$(yaml_get "$CONFIG_FILE" "paths.adr" 2>/dev/null)
            adr_dir="${adr_dir:-.compass/ADR}"
            local count
            count=$(find "$project_root/$adr_dir" -name 'ADR-*.md' 2>/dev/null | wc -l)
            [[ $count -gt 0 ]] || missing+=("ADRs — run /compass:decide")
            ;;
        build-units|build-ready|build-duck|build-idiom|build-tests|build-review|build-progress|build-transform)
            local spec_path
            spec_path=$(yaml_get "$CONFIG_FILE" "paths.spec" 2>/dev/null)
            spec_path="${spec_path:-.compass/SPEC.md}"
            [[ -f "$project_root/$spec_path" ]] || missing+=("SPEC.md — run /compass:spec")
            ;;
    esac

    if [[ ${#missing[@]} -eq 0 ]]; then
        echo '{"ready": true, "missing": []}'
    else
        local json_missing=""
        for m in "${missing[@]}"; do
            [[ -n "$json_missing" ]] && json_missing+=","
            json_missing+="\"$m\""
        done
        echo "{\"ready\": false, \"missing\": [$json_missing]}"
    fi
}

cmd_adr_next() {
    find_compass_dir || die "no .compass/ directory found"

    local project_root="${COMPASS_DIR%/.compass}"
    local adr_dir
    adr_dir=$(yaml_get "$CONFIG_FILE" "paths.adr" 2>/dev/null)
    adr_dir="${adr_dir:-.compass/ADR}"

    local max=0
    for f in "$project_root/$adr_dir"/ADR-*.md; do
        [[ -f "$f" ]] || continue
        local num
        num=$(basename "$f" | grep -oE 'ADR-([0-9]+)' | grep -oE '[0-9]+')
        if [[ $num -gt $max ]]; then
            max=$num
        fi
    done

    printf "%03d\n" $((max + 1))
}

cmd_progress() {
    find_compass_dir || die "no .compass/ directory found"

    local project_root="${COMPASS_DIR%/.compass}"
    local units_dir
    units_dir=$(yaml_get "$CONFIG_FILE" "paths.units" 2>/dev/null)
    units_dir="${units_dir:-.compass/UNITS}"

    if [[ ! -d "$project_root/$units_dir" ]]; then
        echo '{"total": 0, "done": 0, "in_progress": 0, "pending": 0, "blocked": 0, "units": []}'
        return
    fi

    local total=0 done=0 progress=0 pending=0 blocked=0
    local units_json="["
    local first=true

    for f in "$project_root/$units_dir"/unit-*.md; do
        [[ -f "$f" ]] || continue
        ((total++))

        local name status title deps
        name=$(basename "$f" .md)
        status=$(awk '/^## Status/{getline; print; exit}' "$f" | tr -d '[:space:]')
        title=$(head -1 "$f" | sed 's/^# //')

        case "$status" in
            done) ((done++)) ;;
            in-progress) ((progress++)) ;;
            blocked) ((blocked++)) ;;
            *) status="pending"; ((pending++)) ;;
        esac

        [[ "$first" == "true" ]] && first=false || units_json+=","
        units_json+="{\"name\":\"$name\",\"title\":\"$title\",\"status\":\"$status\"}"
    done

    units_json+="]"

    cat <<ENDJSON
{
  "total": $total,
  "done": $done,
  "in_progress": $progress,
  "pending": $pending,
  "blocked": $blocked,
  "units": $units_json
}
ENDJSON
}

cmd_session_update() {
    find_compass_dir || die "no .compass/ directory found"

    local session_file="$COMPASS_DIR/SESSION.md"
    local timestamp
    timestamp=$(date -u '+%Y-%m-%dT%H:%M:%SZ')

    # Get current status
    local status_output
    status_output=$(cmd_status)

    local phase
    phase=$(echo "$status_output" | head -1 | sed 's/Phase: //')

    cat > "$session_file" <<EOF
# COMPASS Session State

Last updated: $timestamp

## Current phase

$phase

## Phase progress

$status_output

## Recent decisions

(updated by agents after decisions)

## Stopped at

(updated by agents or context monitor)

## Next recommended action

(determined by /compass:next)
EOF
}

cmd_config_get() {
    local key="$1"
    [[ -n "$key" ]] || die "usage: compass-tools.sh config get <key>"

    find_compass_dir || die "no .compass/ directory found"

    local value
    value=$(yaml_get "$CONFIG_FILE" "$key")
    [[ -n "$value" ]] && echo "$value" || die "key not found: $key"
}

cmd_config_set() {
    local key="$1"
    local value="$2"
    [[ -n "$key" && -n "$value" ]] || die "usage: compass-tools.sh config set <key> <value>"

    find_compass_dir || die "no .compass/ directory found"

    yaml_set "$CONFIG_FILE" "$key" "$value"
}

cmd_drift() {
    find_compass_dir || die "no .compass/ directory found"

    local project_root="${COMPASS_DIR%/.compass}"

    # Check spec exists
    local spec_path
    spec_path=$(yaml_get "$CONFIG_FILE" "paths.spec" 2>/dev/null)
    spec_path="${spec_path:-.compass/SPEC.md}"
    [[ -f "$project_root/$spec_path" ]] || die "no spec file found at $spec_path"

    # Get the diff — either from argument or git
    local diff_content=""
    if [[ -n "${1:-}" && -f "$1" ]]; then
        diff_content=$(cat "$1")
    else
        # Use git diff of staged + unstaged changes
        diff_content=$(cd "$project_root" && git diff HEAD 2>/dev/null)
        if [[ -z "$diff_content" ]]; then
            diff_content=$(cd "$project_root" && git diff 2>/dev/null)
        fi
    fi

    [[ -n "$diff_content" ]] || die "no diff found (provide a file or have uncommitted git changes)"

    # Extract changed files (outside .compass/)
    local changed_files
    changed_files=$(echo "$diff_content" | grep -E '^\+\+\+ b/' | sed 's|^+++ b/||' | grep -v '\.compass/' || true)

    [[ -n "$changed_files" ]] || { echo '{"files": 0, "drift_possible": false}'; return; }

    local file_count
    file_count=$(echo "$changed_files" | wc -l)

    # Collect spec sections and ADR titles for reference
    local spec_sections=""
    if [[ -f "$project_root/$spec_path" ]]; then
        spec_sections=$(grep -E '^##+ ' "$project_root/$spec_path" | head -20)
    fi

    local adr_dir
    adr_dir=$(yaml_get "$CONFIG_FILE" "paths.adr" 2>/dev/null)
    adr_dir="${adr_dir:-.compass/ADR}"
    local adr_titles=""
    if [[ -d "$project_root/$adr_dir" ]]; then
        adr_titles=$(for f in "$project_root/$adr_dir"/ADR-*.md; do
            [[ -f "$f" ]] && head -1 "$f" | sed 's/^# //'
        done)
    fi

    if [[ "$1" == "--json" || "${2:-}" == "--json" ]]; then
        # Output JSON for the scope-guardian agent to consume
        local files_json="["
        local first=true
        while IFS= read -r f; do
            [[ "$first" == "true" ]] && first=false || files_json+=","
            files_json+="\"$f\""
        done <<< "$changed_files"
        files_json+="]"

        cat <<ENDJSON
{
  "files_changed": $file_count,
  "drift_possible": true,
  "changed_files": $files_json,
  "spec_path": "$spec_path",
  "adr_dir": "$adr_dir",
  "framing_path": ".compass/FRAMING.md"
}
ENDJSON
    else
        echo "Files changed outside .compass/: $file_count"
        echo "$changed_files" | sed 's/^/  /'
        echo ""
        echo "Spec sections to check against:"
        echo "$spec_sections" | sed 's/^/  /'
        echo ""
        echo "Active ADRs:"
        echo "$adr_titles" | sed 's/^/  /'
    fi
}

cmd_unit_update_status() {
    local unit_num="$1"
    local new_status="$2"

    [[ -n "$unit_num" && -n "$new_status" ]] || die "usage: compass-tools.sh unit update-status <unit-number> <status>"

    # Validate status
    case "$new_status" in
        pending|in-progress|done|blocked) ;;
        *) die "invalid status: $new_status (valid: pending, in-progress, done, blocked)" ;;
    esac

    find_compass_dir || die "no .compass/ directory found"

    local project_root="${COMPASS_DIR%/.compass}"
    local units_dir
    units_dir=$(yaml_get "$CONFIG_FILE" "paths.units" 2>/dev/null)
    units_dir="${units_dir:-.compass/UNITS}"

    # Find the unit file matching the number
    local padded
    padded=$(printf "%03d" "$unit_num")
    local unit_file=""
    for f in "$project_root/$units_dir"/unit-"$padded"-*.md; do
        [[ -f "$f" ]] && unit_file="$f" && break
    done

    [[ -n "$unit_file" ]] || die "no unit file found for number $unit_num"

    # Replace the status line (line after ## Status)
    awk -v new_status="$new_status" '
        /^## Status/ { print; getline; print new_status; next }
        { print }
    ' "$unit_file" > "$unit_file.tmp" && mv "$unit_file.tmp" "$unit_file"

    echo "unit-$padded status updated to: $new_status"
}

cmd_init() {
    local project_root="${1:-.}"
    local compass_dir="$project_root/.compass"

    [[ -d "$compass_dir" ]] && die ".compass/ already exists at $project_root"

    mkdir -p "$compass_dir"/{RESEARCH,ADR,UNITS}

    echo "created: $compass_dir/"
    echo "created: $compass_dir/RESEARCH/"
    echo "created: $compass_dir/ADR/"
    echo "created: $compass_dir/UNITS/"
}

# --- Main dispatch ---

case "${1:-}" in
    status)
        shift; cmd_status "$@" ;;
    preflight)
        shift; cmd_preflight "$@" ;;
    adr)
        shift
        case "${1:-}" in
            next-number) cmd_adr_next ;;
            *) die "unknown adr subcommand: ${1:-}" ;;
        esac
        ;;
    progress)
        shift; cmd_progress "$@" ;;
    drift)
        shift; cmd_drift "$@" ;;
    unit)
        shift
        case "${1:-}" in
            update-status) shift; cmd_unit_update_status "$@" ;;
            *) die "unknown unit subcommand: ${1:-}" ;;
        esac
        ;;
    session)
        shift
        case "${1:-}" in
            update) cmd_session_update ;;
            *) die "unknown session subcommand: ${1:-}" ;;
        esac
        ;;
    config)
        shift
        case "${1:-}" in
            get) shift; cmd_config_get "$@" ;;
            set) shift; cmd_config_set "$@" ;;
            *) die "unknown config subcommand: ${1:-}" ;;
        esac
        ;;
    init)
        shift; cmd_init "$@" ;;
    *)
        cat <<USAGE
compass-tools.sh — Deterministic CLI for COMPASS state management.

Commands:
  status [--json]         Project state overview
  preflight <phase>       Check phase prerequisites
  adr next-number         Next ADR number (zero-padded)
  progress                Unit completion stats (JSON)
  drift [--json]          Diff analysis for scope guardian
  unit update-status N S  Update unit N to status S
  session update          Update SESSION.md
  config get <key>        Read config value (dot notation)
  config set <key> <val>  Write config value
  init [project-root]     Scaffold .compass/ directory
USAGE
        exit 1
        ;;
esac
