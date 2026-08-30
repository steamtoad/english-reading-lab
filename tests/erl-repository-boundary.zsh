#!/bin/zsh

#------------------------------------------------------------------------------
# erl-repository-boundary.zsh
# Тип: ERL architecture regression test
# Назначение: проверить, что ERL repository не владеет production host core
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
typeset -a violations
violations=()

command -v git >/dev/null || {
  print -ru2 -- 'FAIL: git is required'
  exit 1
}

git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  print -ru2 -- "FAIL: not a Git worktree: $repo"
  exit 1
}

while IFS= read -r path; do
  [[ -n "$path" ]] || continue

  case "$path" in
    .scripts/erl/*)
      ;;
    *)
      violations+=("$path")
      ;;
  esac
done < <(git -C "$repo" ls-files -- '.scripts/**')

if (( ${#violations[@]} > 0 )); then
  print -ru2 -- 'FAIL: ERL repository tracks host-owned production files under .scripts/:'
  for path in "${violations[@]}"; do
    print -ru2 -- "  $path"
  done
  print -ru2 -- 'Expected tracked production files under .scripts/ to be limited to .scripts/erl/**'
  exit 1
fi

print -r -- 'PASS: ERL repository ownership boundary'
