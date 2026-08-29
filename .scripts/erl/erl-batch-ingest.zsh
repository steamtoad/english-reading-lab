#!/bin/zsh

#------------------------------------------------------------------------------
# erl-batch-ingest
# Тип: ERL CLI
# Назначение: атомарно загрузить набор JSON records
#------------------------------------------------------------------------------

setopt errexit
setopt nounset
setopt pipefail

ERL_ROOT="${ERL_ROOT:-.erl}"
script_dir="${0:A:h}"
ERL_CHECK="${ERL_CHECK:-${script_dir}/erl-check.zsh}"
RECORDS_DIR="${ERL_RECORDS_DIR:-${ERL_ROOT}/records}"

input=""

die() {
    print -u2 -- "erl-batch-ingest: $*"
    exit 2
}

usage() {
    cat <<'EOF'
Usage:
  erl-batch-ingest --input FILE
  erl-batch-ingest --input -

Input may be:
  - one JSON array of objects
  - JSONL
  - several consecutive JSON objects
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --input)
            (( $# >= 2 )) || die "--input requires an argument"
            input="$2"
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

mkdir -p -- "$ERL_ROOT"

tmp_input=""
candidate=""
backup=""
installed=0

cleanup() {
    [[ -n "$tmp_input" && -f "$tmp_input" ]] && rm -f -- "$tmp_input"
    [[ -n "$candidate" && -d "$candidate" ]] && rm -rf -- "$candidate"

    if (( installed == 0 )) && [[ -n "$backup" && -d "$backup" ]]; then
        if [[ ! -d "$RECORDS_DIR" ]]; then
            mv -- "$backup" "$RECORDS_DIR"
        fi
    fi
}

trap cleanup EXIT INT TERM

if [[ "$input" == "-" ]]; then
    tmp_input="$(mktemp "${TMPDIR:-/tmp}/erl-batch.XXXXXX")"
    cat > "$tmp_input"
    input="$tmp_input"
fi

[[ -f "$input" ]] || die "input file not found: $input"

# First verify that the whole stream is valid JSON.
jq -e '.' "$input" >/dev/null \
    || die "input contains invalid JSON"

candidate="$(mktemp -d "${ERL_ROOT}/.records.candidate.XXXXXX")"

# Candidate begins as a copy of current canonical records.
if [[ -d "$RECORDS_DIR" ]]; then
    cp -R "${RECORDS_DIR}/." "$candidate/"
fi

typeset -A seen_ids
count=0

while IFS= read -r object; do
    jq -e 'type == "object"' <<< "$object" >/dev/null \
        || die "batch contains a non-object item"

    id="$(jq -r '.id // .uuid // empty' <<< "$object")"

    [[ -n "$id" ]] \
        || die "batch item has neither .id nor .uuid"

    [[ "$id" =~ '^[A-Za-z0-9._%-]+$' ]] \
        || die "unsafe id: $id"

    if [[ -n "${seen_ids[$id]-}" ]]; then
        die "duplicate id inside batch: $id"
    fi

    seen_ids[$id]=1

    print -r -- "$object" \
        | jq -S '.' \
        > "${candidate}/${id}.json"

    (( count += 1 ))
done < <(
    jq -c '
        if type == "array"
        then .[]
        else .
        end
    ' "$input"
)

(( count > 0 )) || die "batch is empty"

backup="${RECORDS_DIR}.backup.$$"

if [[ -d "$RECORDS_DIR" ]]; then
    mv -- "$RECORDS_DIR" "$backup"
else
    backup=""
fi
mv -- "$candidate" "$RECORDS_DIR"
candidate=""

if ! "$ERL_CHECK" >&2; then
    print -u2 -- "erl-batch-ingest: validation failed; rolling back"

    rm -rf -- "$RECORDS_DIR"
    [[ -z "$backup" ]] || mv -- "$backup" "$RECORDS_DIR"
    backup=""

    exit 3
fi

[[ -z "$backup" ]] || rm -rf -- "$backup"
backup=""
installed=1

jq -n --argjson count "$count" '{
    status: "ok",
    ingested: $count
}'
