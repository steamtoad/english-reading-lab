#!/bin/zsh

#------------------------------------------------------------------------------
# erl-reconcile
# Тип: ERL CLI
# Назначение: безопасно согласовать два JSON objects
#------------------------------------------------------------------------------

setopt errexit
setopt nounset
setopt pipefail

left=""
right=""
base=""
output="-"

die() {
    print -u2 -- "erl-reconcile: $*"
    exit 2
}

usage() {
    cat <<'EOF'
Usage:
  erl-reconcile --left LEFT.json --right RIGHT.json
  erl-reconcile --base BASE.json --left LEFT.json --right RIGHT.json
  erl-reconcile --left LEFT.json --right RIGHT.json --output RESULT.json

Exit codes:
  0  reconciliation succeeded
  2  invalid invocation/input
  3  unresolved conflict
EOF
}

while (( $# > 0 )); do
    case "$1" in
        --left)
            (( $# >= 2 )) || die "--left requires an argument"
            left="$2"
            shift 2
            ;;
        --right)
            (( $# >= 2 )) || die "--right requires an argument"
            right="$2"
            shift 2
            ;;
        --base)
            (( $# >= 2 )) || die "--base requires an argument"
            base="$2"
            shift 2
            ;;
        --output)
            (( $# >= 2 )) || die "--output requires an argument"
            output="$2"
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

[[ -n "$left" ]] || die "--left is required"
[[ -n "$right" ]] || die "--right is required"

[[ -f "$left" ]] || die "left file not found: $left"
[[ -f "$right" ]] || die "right file not found: $right"

if [[ -n "$base" ]]; then
    [[ -f "$base" ]] || die "base file not found: $base"
fi

command -v jq >/dev/null 2>&1 || die "jq not found"

jq -e 'type == "object"' "$left" >/dev/null \
    || die "left must be a JSON object"

jq -e 'type == "object"' "$right" >/dev/null \
    || die "right must be a JSON object"

if [[ -n "$base" ]]; then
    jq -e 'type == "object"' "$base" >/dev/null \
        || die "base must be a JSON object"
fi

if [[ -n "$base" ]]; then
    result="$(
        jq -n -S \
            --slurpfile base "$base" \
            --slurpfile left "$left" \
            --slurpfile right "$right" '
            def state($object; $key):
                if ($object | has($key))
                then {
                    present: true,
                    value: $object[$key]
                }
                else {
                    present: false
                }
                end;

            def install($result; $key; $state):
                if $state.present
                then $result + {($key): $state.value}
                else $result
                end;

            ($base[0]) as $b
            | ($left[0]) as $l
            | ($right[0]) as $r

            | (
                (
                    ($b | keys_unsorted)
                    + ($l | keys_unsorted)
                    + ($r | keys_unsorted)
                )
                | unique
            ) as $keys

            | reduce $keys[] as $key
                ({
                    status: "ok",
                    result: {},
                    conflicts: []
                };

                 state($b; $key) as $bs
                 | state($l; $key) as $ls
                 | state($r; $key) as $rs

                 | if $ls == $rs then
                       .result = install(.result; $key; $ls)

                   elif $ls == $bs then
                       .result = install(.result; $key; $rs)

                   elif $rs == $bs then
                       .result = install(.result; $key; $ls)

                   else
                       .status = "conflict"
                       | .conflicts += [{
                           key: $key,
                           base: $bs,
                           left: $ls,
                           right: $rs
                       }]
                   end
                )
        '
    )"
else
    result="$(
        jq -n -S \
            --slurpfile left "$left" \
            --slurpfile right "$right" '
            def state($object; $key):
                if ($object | has($key))
                then {
                    present: true,
                    value: $object[$key]
                }
                else {
                    present: false
                }
                end;

            def install($result; $key; $state):
                if $state.present
                then $result + {($key): $state.value}
                else $result
                end;

            {} as $b
            | ($left[0]) as $l
            | ($right[0]) as $r

            | (
                (
                    ($l | keys_unsorted)
                    + ($r | keys_unsorted)
                )
                | unique
            ) as $keys

            | reduce $keys[] as $key
                ({
                    status: "ok",
                    result: {},
                    conflicts: []
                };

                 state($b; $key) as $bs
                 | state($l; $key) as $ls
                 | state($r; $key) as $rs

                 | if $ls == $rs then
                       .result = install(.result; $key; $ls)

                   elif $ls == $bs then
                       .result = install(.result; $key; $rs)

                   elif $rs == $bs then
                       .result = install(.result; $key; $ls)

                   else
                       .status = "conflict"
                       | .conflicts += [{
                           key: $key,
                           left: $ls,
                           right: $rs
                       }]
                   end
                )
        '
    )"
fi

status="$(jq -r '.status' <<< "$result")"

if [[ "$status" == "conflict" ]]; then
    print -r -- "$result"
    exit 3
fi

if [[ "$output" == "-" ]]; then
    jq -S '.result' <<< "$result"
else
    tmp_output="$(mktemp "${output}.tmp.XXXXXX")"

    jq -S '.result' <<< "$result" > "$tmp_output"

    mv -- "$tmp_output" "$output"
fi