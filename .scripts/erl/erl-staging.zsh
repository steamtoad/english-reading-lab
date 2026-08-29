#!/bin/zsh

#------------------------------------------------------------------------------
# erl-staging
# Тип: ERL CLI
# Назначение: управление staging area ERL
#------------------------------------------------------------------------------

setopt errexit
setopt nounset
setopt pipefail

ERL_ROOT="${ERL_ROOT:-.erl}"
script_dir="${0:A:h}"
ERL_CHECK="${ERL_CHECK:-${script_dir}/erl-check.zsh}"
STAGING_DIR="${ERL_STAGING_DIR:-${ERL_ROOT}/staging}"

die() {
    print -u2 -- "erl-staging: $*"
    exit 2
}

usage() {
    cat <<'EOF'
Usage:
  erl-staging put FILE
  erl-staging put - --id ID
  erl-staging list
  erl-staging show ID
  erl-staging drop ID
EOF
}

safe_id() {
    [[ "$1" =~ '^[A-Za-z0-9._%-]+$' ]]
}

command_put() {
    local input=""
    local forced_id=""
    local tmp_input=""
    local id=""
    local destination=""
    local tmp_destination=""

    (( $# >= 1 )) || die "put requires FILE"

    input="$1"
    shift

    while (( $# > 0 )); do
        case "$1" in
            --id)
                (( $# >= 2 )) || die "--id requires an argument"
                forced_id="$2"
                shift 2
                ;;
            *)
                die "unknown put argument: $1"
                ;;
        esac
    done

    if [[ "$input" == "-" ]]; then
        tmp_input="$(mktemp "${TMPDIR:-/tmp}/erl-staging.XXXXXX")"
        cat > "$tmp_input"
        input="$tmp_input"
    fi

    [[ -f "$input" ]] || die "input file not found: $input"

    jq -e 'type == "object"' "$input" >/dev/null \
        || die "staging input must be a JSON object"

    id="$forced_id"

    if [[ -z "$id" ]]; then
        id="$(jq -r '.id // .uuid // empty' "$input")"
    fi

    [[ -n "$id" ]] || {
        [[ -n "$tmp_input" ]] && rm -f -- "$tmp_input"
        die "missing .id/.uuid; use --id"
    }

    safe_id "$id" || die "unsafe id: $id"

    mkdir -p -- "$STAGING_DIR"

    destination="${STAGING_DIR}/${id}.json"
    tmp_destination="$(mktemp "${destination}.tmp.XXXXXX")"

    jq -S '.' "$input" > "$tmp_destination"
    mv -- "$tmp_destination" "$destination"

    [[ -n "$tmp_input" ]] && rm -f -- "$tmp_input"

    print -r -- "$destination"
}

command_list() {
    local files
    local file

    if [[ -d "$STAGING_DIR" ]]; then
        files=( "$STAGING_DIR"/*.json(N) )
    else
        files=()
    fi

    if (( ${#files[@]} == 0 )); then
        print '[]'
        return
    fi

    for file in "${files[@]}"; do
        print -r -- "${file:t:r}"
    done | jq -R -s '
        split("\n")
        | map(select(length > 0))
        | sort
    '
}

command_show() {
    local id="$1"
    local file=""

    safe_id "$id" || die "unsafe id: $id"

    file="${STAGING_DIR}/${id}.json"

    [[ -f "$file" ]] || die "staging object not found: $id"

    jq -S '.' "$file"
}

command_drop() {
    local id="$1"
    local file=""
    local backup=""

    safe_id "$id" || die "unsafe id: $id"

    file="${STAGING_DIR}/${id}.json"

    [[ -f "$file" ]] || die "staging object not found: $id"

    [[ -x "$ERL_CHECK" ]] || die "$ERL_CHECK not found or not executable"
    backup="$(mktemp "${file}.backup.XXXXXX")"
    mv -- "$file" "$backup"

    if ! "$ERL_CHECK" >&2; then
        mv -- "$backup" "$file"
        print -u2 -- "erl-staging: erl-check failed; drop rolled back: $id"
        exit 3
    fi
    rm -f -- "$backup"
}

command -v jq >/dev/null 2>&1 || die "jq not found"

(( $# >= 1 )) || {
    usage
    exit 2
}

subcommand="$1"
shift

case "$subcommand" in
    put)
        command_put "$@"
        ;;
    list)
        command_list
        ;;
    show)
        (( $# == 1 )) || die "show requires ID"
        command_show "$1"
        ;;
    drop)
        (( $# == 1 )) || die "drop requires ID"
        command_drop "$1"
        ;;
    -h|--help|help)
        usage
        ;;
    *)
        die "unknown subcommand: $subcommand"
        ;;
esac
