#!/bin/zsh

#------------------------------------------------------------------------------
# zt-develop-publish-version.zsh
# Тип: Maintenance
# Назначение: публикация версии скриптов и документации в открытый репозиторий
#------------------------------------------------------------------------------

emulate -L zsh

src="${ZK_DEV_HOME:-/Users/steamtoad/zettelkasten}"
dst="${ZK_PUBLISH_HOME:-/Users/steamtoad/dev/zettelkasten-cli}"

apply=0

fail() {
  print -ru2 -- "ERROR $1"
  exit 1
}

case "$1" in
  --apply) apply=1 ;;
  --dry-run|"") apply=0 ;;
  *)
    print -ru2 -- "Usage: zt-develop-publish-version [--dry-run|--apply]"
    exit 1
    ;;
esac

[[ -d "$src" ]] || {
  print -ru2 -- "ERROR source not found: $src"
  exit 1
}

[[ -d "$dst" ]] || {
  print -ru2 -- "ERROR destination not found: $dst"
  exit 1
}

[[ -d "$src/.scripts" ]] || {
  print -ru2 -- "ERROR source .scripts not found: $src/.scripts"
  exit 1
}

for f in LICENSE README.MD .gitignore; do
  [[ -f "$src/$f" ]] || {
    print -ru2 -- "ERROR source file not found: $src/$f"
    exit 1
  }
done

print -r -- "== zt-develop-publish-version"
print -r -- "From: $src"
print -r -- "To:   $dst"
print -r -- ""

if (( apply == 0 )); then
  print -r -- "DRY RUN"
  rsync -av --dry-run --exclude='.DS_Store' "$src/.scripts/" "$dst/.scripts/" ||
    fail "dry-run failed for .scripts"
  rsync -av --dry-run "$src/LICENSE" "$src/README.MD" "$src/.gitignore" "$dst/" ||
    fail "dry-run failed for root artifacts"
  print -r -- ""
  print -r -- "Run with --apply to copy files."
  exit 0
fi

mkdir -p "$dst/.scripts" || fail "cannot create destination .scripts: $dst/.scripts"

rsync -av --exclude='.DS_Store' "$src/.scripts/" "$dst/.scripts/" ||
  fail "copy failed for .scripts"
rsync -av "$src/LICENSE" "$src/README.MD" "$src/.gitignore" "$dst/" ||
  fail "copy failed for root artifacts"

print -r -- ""
print -r -- "Publish copy complete."
