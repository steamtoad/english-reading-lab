#!/bin/zsh

#------------------------------------------------------------------------------
# erl-reduce
# Тип: ERL CLI
# Назначение: свести несколько JSON objects к одному объекту
#------------------------------------------------------------------------------

setopt errexit
setopt nounset
setopt pipefail

input=""
strategy="error"

die() {
    print -u2 -- "erl-reduce: $*"
    exit 2
}

usage() {
    cat <<'EOF'
Usage:
  erl-reduce --input FILE
  erl-reduce --input -
  erl-reduce --input FILE --strategy error
  erl-reduce --input FILE --strategy first-wins
  erl-reduce --input FILE --strategy last-wins

Input:
  JSON array, JSONL, or consecutive JSON objects.

Exit codes:
  0  reduced successfully
  2  invalid invocation/input
  3  semantic conflict with strategy=error
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --input)
            (( $# >= 2 )) || die "--input requires an argument"
            input="$2"
            shift 2
            ;;
        --strategy)
            (( $# >= 2 )) || die "--strategy requires an argument"
            strategy="$2"
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

case "$strategy" in
    error|first-wins|last-wins)
        ;;
    *)
        die "unknown strategy: $strategy"
        ;;
esac

command -v jq >/dev/null 2>&1 || die "jq not found"

tmp_input=""

cleanup() {
    [[ -n "$tmp_input" && -f "$tmp_input" ]] && rm -f -- "$tmp_input"
}

trap cleanup EXIT INT TERM

if [[ "$input" == "-" ]]; then
    tmp_input="$(mktemp "${TMPDIR:-/tmp}/erl-reduce.XXXXXX")"
    cat > "$tmp_input"
    input="$tmp_input"
fi

[[ -f "$input" ]] || die "input file not found: $input"

normalized="$(
    jq -s '
        [
            .[]
            | if type == "array"
              then .[]
              else .
              end
        ]
    ' "$input"
)" || die "invalid JSON"

jq -e 'all(.[]; type == "object")' <<< "$normalized" >/dev/null \
    || die "all reduce items must be JSON objects"

case "$strategy" in
    last-wins)
        jq -S '
            reduce .[] as $item
                ({};
                 . * $item)
        ' <<< "$normalized"
        ;;

    first-wins)
        jq -S '
            reduce (reverse[]) as $item
                ({};
                 . * $item)
        ' <<< "$normalized"
        ;;

    error)
        result="$(
            jq -S '
                def conflicting_keys($a; $b):
                    [
                        ($a | keys_unsorted[]) as $key
                        | select($b | has($key))
                        | select($a[$key] != $b[$key])
                        | $key
                    ];

                reduce .[] as $item
                    ({
                        result: {},
                        conflicts: []
                    };
                     .conflicts += conflicting_keys(.result; $item)
                     | .result = (.result * $item))
                | .conflicts |= unique
            ' <<< "$normalized"
        )"

        conflict_count="$(
            jq -r '.conflicts | length' <<< "$result"
        )"

        if (( conflict_count > 0 )); then
            print -r -- "$result"
            exit 3
        fi

        jq -S '.result' <<< "$result"
        ;;
esac