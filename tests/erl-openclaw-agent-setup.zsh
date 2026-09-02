#!/bin/zsh

#------------------------------------------------------------------------------
# erl-openclaw-agent-setup.zsh
# Тип: ERL OpenClaw setup regression test
# Назначение: проверить self-contained dry-run, apply, check, conflicts и rollback Lexi workspace
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
setup="$repo/.scripts/erl/dev/erl-openclaw-agent-setup.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-openclaw-agent-setup-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

new_workspace() {
  local root="$1"
  mkdir -p -- "$root"
  cp -- "$repo/.gitignore" "$root/.gitignore"
  git -C "$root" init -q
}

profile_args=(--user-name Саша --timezone Europe/Sofia)
workspace="$fixture/fresh"
new_workspace "$workspace"

before="$(find "$workspace" -type f -print0 | sort -z | xargs -0 shasum -a 256)"
dry_run="$($setup --workspace "$workspace" "${profile_args[@]}")"
after="$(find "$workspace" -type f -print0 | sort -z | xargs -0 shasum -a 256)"
[[ "$before" == "$after" ]] || { print -ru2 -- 'FAIL: dry-run mutated target'; exit 1; }
[[ "$dry_run" == *$'create\tHEARTBEAT.md'* ]] || { print -ru2 -- 'FAIL: dry-run omitted create plan'; exit 1; }
[[ "$dry_run" == *'payload_hash='* ]] || { print -ru2 -- 'FAIL: dry-run omitted payload hash'; exit 1; }

apply_output="$($setup --workspace "$workspace" "${profile_args[@]}" --apply)"
[[ "$apply_output" == *'PASS: Lexi workspace setup complete'* ]] || { print -ru2 -- 'FAIL: fresh apply did not complete'; exit 1; }
$setup --workspace "$workspace" "${profile_args[@]}" --check >/dev/null

typeset -a expected_skills=(
  erl-book-ingest erl-chapter-vocabulary-extract erl-vocabulary-ingest
  erl-chapter-vocabulary-ingest erl-book-reduce erl-classic-reduce-reconcile erl-check
)
for skill in "${expected_skills[@]}"; do
  [[ -f "$workspace/skills/$skill/SKILL.md" ]] || { print -ru2 -- "FAIL: missing skill $skill"; exit 1; }
done
[[ "$(find "$workspace/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" == 7 ]] || {
  print -ru2 -- 'FAIL: setup did not materialize exactly seven skills'
  exit 1
}
for rel in openclaw-workspace-state.json HEARTBEAT.md IDENTITY.md SOUL.md TOOLS.md USER.md .scripts/erl/docs/lexi-agent.md; do
  [[ -f "$workspace/$rel" ]] || { print -ru2 -- "FAIL: missing managed artifact $rel"; exit 1; }
  git -C "$workspace" check-ignore -q -- "$rel" || { print -ru2 -- "FAIL: managed artifact is not ignored: $rel"; exit 1; }
done
rg -qF "$workspace" "$workspace/TOOLS.md"
rg -qF "Canonical Lexi Vault: \`$workspace\`" "$workspace/TOOLS.md"
rg -qF "Pass \`--vault $workspace\` to every ERL command." "$workspace/TOOLS.md"
rg -qF '**Name:** Саша' "$workspace/USER.md"
rg -qF '**Timezone:** Europe/Sofia' "$workspace/USER.md"

mtime_before="$(stat -f '%m' "$workspace/IDENTITY.md")"
state_before="$(shasum -a 256 "$workspace/openclaw-workspace-state.json")"
sleep 1
second_apply="$($setup --workspace "$workspace" "${profile_args[@]}" --apply)"
mtime_after="$(stat -f '%m' "$workspace/IDENTITY.md")"
state_after="$(shasum -a 256 "$workspace/openclaw-workspace-state.json")"
[[ "$mtime_before" == "$mtime_after" && "$state_before" == "$state_after" ]] || {
  print -ru2 -- 'FAIL: idempotent apply rewrote managed artifacts'
  exit 1
}
[[ "$second_apply" != *$'create\t'* && "$second_apply" != *$'conflict\t'* ]] || {
  print -ru2 -- 'FAIL: idempotent apply did not classify all artifacts as keep'
  exit 1
}

print -r -- 'local edit' >> "$workspace/USER.md"
identity_hash="$(shasum -a 256 "$workspace/IDENTITY.md")"
set +e
conflict_output="$($setup --workspace "$workspace" "${profile_args[@]}" --apply 2>&1)"
conflict_rc=$?
set -e
[[ "$conflict_rc" == 10 && "$conflict_output" == *$'conflict\tUSER.md'* ]] || {
  print -ru2 -- 'FAIL: default apply did not reject a managed conflict'
  exit 1
}
rg -qxF 'local edit' "$workspace/USER.md"
[[ "$(shasum -a 256 "$workspace/IDENTITY.md")" == "$identity_hash" ]] || {
  print -ru2 -- 'FAIL: conflict preflight partially mutated another artifact'
  exit 1
}
print -r -- 'unknown user skill' > "$workspace/skills/local-extra.txt"
replace_output="$($setup --workspace "$workspace" "${profile_args[@]}" --replace-managed --apply)"
[[ -f "$workspace/skills/local-extra.txt" ]] || { print -ru2 -- 'FAIL: replacement removed unknown file'; exit 1; }
journal="${replace_output##*journal=}"
[[ -f "$journal/backups/USER.md" ]] || { print -ru2 -- 'FAIL: replacement backup is missing'; exit 1; }
rg -qxF 'local edit' "$journal/backups/USER.md"
$setup --workspace "$workspace" "${profile_args[@]}" --check >/dev/null

rollback_workspace="$fixture/rollback"
new_workspace "$rollback_workspace"
print -r -- 'original identity' > "$rollback_workspace/IDENTITY.md"
set +e
rollback_output="$(ERL_AGENT_SETUP_FAIL_AFTER=2 $setup --workspace "$rollback_workspace" "${profile_args[@]}" --replace-managed --apply 2>&1)"
rollback_rc=$?
set -e
[[ "$rollback_rc" == 20 ]] || { print -ru2 -- "FAIL: injected failure returned $rollback_rc"; print -ru2 -- "$rollback_output"; exit 1; }
rg -qxF 'original identity' "$rollback_workspace/IDENTITY.md"
[[ ! -e "$rollback_workspace/HEARTBEAT.md" && ! -e "$rollback_workspace/openclaw-workspace-state.json" ]] || {
  print -ru2 -- 'FAIL: rollback left partially published managed artifacts'
  exit 1
}
rg -q 'status=recovery-required' "$rollback_workspace/.state/erl/agent-setup-transactions"/*/status

symlink_workspace="$fixture/symlink"
new_workspace "$symlink_workspace"
ln -s /tmp "$symlink_workspace/SOUL.md"
set +e
symlink_output="$($setup --workspace "$symlink_workspace" "${profile_args[@]}" --replace-managed --apply 2>&1)"
symlink_rc=$?
set -e
[[ "$symlink_rc" == 10 && "$symlink_output" == *'replacement target is not a regular file'* ]] || {
  print -ru2 -- 'FAIL: unsafe replacement target was not rejected'
  exit 1
}
[[ -L "$symlink_workspace/SOUL.md" ]] || { print -ru2 -- 'FAIL: unsafe target was mutated'; exit 1; }

rg -q 'unsafe payload path' "$setup"
rg -q 'duplicate payload' "$setup"
rg -q 'secret-like value' "$setup"
rg -q 'prohibited distribution artifact' "$setup"

expect_reference_failure() {
  local expected="$1" reference="$2" output rc
  set +e
  output="$($setup --check-reference-skills "$reference" 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == 10 && "$output" == *"$expected"* ]] || {
    print -ru2 -- "FAIL: expected reference synchronization diagnostic: $expected"
    print -ru2 -- "$output"
    exit 1
  }
}

reference="$fixture/reference-skills"
cp -R "$repo/skills" "$reference"
$setup --check-reference-skills "$reference" >/dev/null

rm -f -- "$reference/erl-check/SKILL.md"
expect_reference_failure 'reference skill path missing: erl-check/SKILL.md' "$reference"
cp -R "$repo/skills" "$reference-reset"
rm -rf -- "$reference"
mv "$reference-reset" "$reference"

print -r -- 'unexpected reference member' > "$reference/erl-check/references/extra.md"
expect_reference_failure 'reference skill path extra: erl-check/references/extra.md' "$reference"
rm -f -- "$reference/erl-check/references/extra.md"

print -r -- '\nreference drift' >> "$reference/erl-check/SKILL.md"
expect_reference_failure 'reference skill content drift: erl-check/SKILL.md' "$reference"
cp -- "$repo/skills/erl-check/SKILL.md" "$reference/erl-check/SKILL.md"

rm -f -- "$reference/erl-check/SKILL.md"
ln -s "$repo/skills/erl-check/SKILL.md" "$reference/erl-check/SKILL.md"
expect_reference_failure 'reference symlink is forbidden: erl-check/SKILL.md' "$reference"

set +e
missing_reference_output="$($setup --check-reference-skills "$fixture/no-reference-skills" 2>&1)"
missing_reference_rc=$?
set -e
[[ "$missing_reference_rc" == 10 && "$missing_reference_output" == *'reference skills directory not found'* ]] || {
  print -ru2 -- 'FAIL: missing development reference did not produce explicit diagnostic'
  exit 1
}

# Runtime bootstrap remains independent of the development reference directory.
if rg -q 'repo_root.*/skills' "$setup"; then
  print -ru2 -- 'FAIL: runtime setup reads reference skills from repository root'
  exit 1
fi

print -r -- 'PASS: self-contained OpenClaw Lexi agent setup contract'
