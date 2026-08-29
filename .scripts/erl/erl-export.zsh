#!/bin/zsh

#------------------------------------------------------------------------------
# erl-export
# Тип: ERL CLI
# Назначение: экспортировать canonical ERL records
#------------------------------------------------------------------------------

setopt errexit
setopt nounset
setopt pipefail

ERL_ROOT="${ERL_ROOT:-.erl}"
script_dir="${0:A:h}"
ERL_CHECK="${ERL_CHECK:-${script_dir}/erl-check.zsh}"
RECORDS_DIR="${ERL_RECORDS_DIR:-${ERL_ROOT}/records}"

output="-"
format="json"

die() {
    print -u2 -- "erl-export: $*"
    exit 2
}

usage() {
    cat <<'EOF'
Usage:
  erl-export
  erl-export --output FILE
  erl-export --format jsonl
  erl-export --format json --output FILE

Options:
  --output FILE        output file; default "-" (stdout)
  --format json|jsonl  export format; default json
  -h, --help           show help
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --output)
            (( $# >= 2 )) || die "--output requires an argument"
            output="$2"
            shift 2
            ;;
        --format)
            (( $# >= 2 )) || die "--format requires an argument"
            format="$2"
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

[[ "$format" == "json" || "$format" == "jsonl" ]] \
    || die "unsupported format: $format"

command -v jq >/dev/null 2>&1 || die "jq not found"
[[ -x "$ERL_CHECK" ]] || die "$ERL_CHECK not found or not executable"

"$ERL_CHECK" >&2 || exit 3

if [[ -d "$RECORDS_DIR" ]]; then
    files=( "$RECORDS_DIR"/*.json(N) )
else
    files=()
fi

emit_json() {
    if (( ${#files[@]} == 0 )); then
        print '[]'
        return
    fi

    jq -S -s '
        sort_by(.id // .uuid // "")
    ' "${files[@]}"
}

emit_jsonl() {
    local file

    for file in "${files[@]}"; do
        jq -cS '.' "$file"
    done
}

emit() {
    case "$format" in
        json)
            emit_json
            ;;
        jsonl)
            emit_jsonl
            ;;
    esac
}

if [[ "$output" == "-" ]]; then
    emit
else
    output_dir="${output:h}"
    mkdir -p -- "$output_dir"

    tmp_output="$(mktemp "${output}.tmp.XXXXXX")"

    if ! emit > "$tmp_output"; then
        rm -f -- "$tmp_output"
        die "export failed"
    fi

    mv -- "$tmp_output" "$output"
fi
