#!/bin/zsh

#------------------------------------------------------------------------------
# erl-vocabulary-ingest
# Тип: ERL CLI
# Назначение: загрузить vocabulary entry в ERL
#------------------------------------------------------------------------------

setopt errexit
setopt nounset
setopt pipefail

ERL_ROOT="${ERL_ROOT:-.erl}"
script_dir="${0:A:h}"
ERL_CHECK="${ERL_CHECK:-${script_dir}/erl-check.zsh}"
VOCABULARY_DIR="${ERL_VOCABULARY_DIR:-${ERL_ROOT}/vocabulary}"

input=""
forced_id=""

die() {
    print -u2 -- "erl-vocabulary-ingest: $*"
    exit 2
}

usage() {
    cat <<'EOF'
Usage:
  erl-vocabulary-ingest --input FILE
  erl-vocabulary-ingest --input -
  erl-vocabulary-ingest --input FILE --id ID
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --input)
            (( $# >= 2 )) || die "--input requires an argument"
            input="$2"
            shift 2
            ;;
        --id)
            (( $# >= 2 )) || die "--id requires an argument"
            forced_id="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1"
            ;;
    esac
done

[[ -n "$input" ]] || die "--input is required"

command -v jq >/dev/null 2>&1 || die "jq not found"
[[ -x "$ERL_CHECK" ]] || die "$ERL_CHECK not found or not executable"

tmp_input=""

cleanup() {
    [[ -n "$tmp_input" && -f "$tmp_input" ]] && rm -f -- "$tmp_input"
}

trap cleanup EXIT INT TERM

if [[ "$input" == "-" ]]; then
    tmp_input="$(mktemp "${TMPDIR:-/tmp}/erl-vocabulary.XXXXXX")"
    cat > "$tmp_input"
    input="$tmp_input"
fi

[[ -f "$input" ]] || die "input file not found: $input"

jq -e 'type == "object"' "$input" >/dev/null \
    || die "input must be a JSON object"

id="$forced_id"

if [[ -z "$id" ]]; then
    id="$(jq -r '.id // .uuid // empty' "$input")"
fi

if [[ -z "$id" ]]; then
    term="$(jq -r '.term // empty' "$input")"

    [[ -n "$term" ]] \
        || die "missing .id/.uuid/.term; use --id"

    id="$(print -rn -- "$term" | jq -sRr '@uri')"
fi

[[ "$id" =~ '^[A-Za-z0-9._%~-]+$' ]] \
    || die "unsafe vocabulary id: $id"

mkdir -p -- "$VOCABULARY_DIR"

destination="${VOCABULARY_DIR}/${id}.json"
tmp_destination="$(mktemp "${destination}.tmp.XXXXXX")"
backup_destination=""

jq -S '.' "$input" > "$tmp_destination"
if [[ -f "$destination" ]]; then
    backup_destination="$(mktemp "${destination}.backup.XXXXXX")"
    cp -- "$destination" "$backup_destination"
fi
mv -- "$tmp_destination" "$destination"

if ! "$ERL_CHECK" >&2; then
    if [[ -n "$backup_destination" ]]; then
        mv -- "$backup_destination" "$destination"
    else
        rm -f -- "$destination"
    fi
    print -u2 -- "erl-vocabulary-ingest: erl-check failed; mutation rolled back:"
    print -u2 -- "  $destination"
    exit 3
fi
[[ -z "$backup_destination" ]] || rm -f -- "$backup_destination"

print -r -- "$destination"
