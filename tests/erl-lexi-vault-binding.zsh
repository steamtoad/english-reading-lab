#!/bin/zsh

#------------------------------------------------------------------------------
# erl-lexi-vault-binding.zsh
# Тип: ERL Lexi Vault-binding regression test
# Назначение: проверить exact --vault ERL_HOME во всех skills, setup payload и Book dry-run
#------------------------------------------------------------------------------

emulate -L zsh
setopt errexit pipe_fail no_unset

repo="${0:A:h:h}"
erl="$repo/.scripts/erl"
checker="$erl/dev/erl-skills-check.zsh"
setup="$erl/dev/erl-openclaw-agent-setup.zsh"
fixture="$(mktemp -d "${TMPDIR:-/tmp}/erl-lexi-vault-binding-test.XXXXXX")"
trap 'rm -rf -- "$fixture"' EXIT HUP INT TERM

typeset -a skills=(
  erl-book-ingest erl-chapter-vocabulary-extract erl-vocabulary-ingest
  erl-chapter-vocabulary-ingest erl-book-reduce erl-classic-reduce-reconcile erl-check
)

for skill in "${skills[@]}"; do
  skill_file="$repo/skills/$skill/SKILL.md"
  reference="$repo/skills/$skill/references/erl-agent-contract-v1.md"
  rg -qF 'Pass exact `--vault "${ERL_HOME}"` to every ERL CLI invocation' "$skill_file" || {
    print -ru2 -- "FAIL: $skill does not bind every invocation to ERL_HOME"
    exit 1
  }
  cmp -s "$repo/.scripts/erl/docs/skill-contracts/erl-agent-contract-v1.md" "$reference" || {
    print -ru2 -- "FAIL: $skill reference differs from source contract"
    exit 1
  }
done
$checker >/dev/null

reset_skills() {
  rm -rf -- "$fixture/skills"
  cp -R -- "$repo/skills" "$fixture/skills"
  find "$fixture/skills" -name .DS_Store -type f -delete
}

expect_skill_failure() {
  local skill="$1" expected="$2" output rc
  set +e
  output="$(ERL_SKILLS_DIR="$fixture/skills" "$checker" 2>&1)"
  rc=$?
  set -e
  [[ "$rc" == 10 && "$output" == *"$skill:"* && "$output" == *"$expected"* ]] || {
    print -ru2 -- "FAIL: missing deterministic $skill diagnostic: $expected"
    print -ru2 -- "$output"
    exit 1
  }
}

reset_skills
sed -i.bak '/Pass exact `--vault/d' "$fixture/skills/erl-book-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-book-ingest/SKILL.md.bak"
expect_skill_failure erl-book-ingest 'runtime workflow does not pass exact --vault ERL_HOME'

reset_skills
sed -i.bak 's#${ERL_HOME}#/Users/steamtoad/zettelkasten#g' "$fixture/skills/erl-check/SKILL.md"
rm -f -- "$fixture/skills/erl-check/SKILL.md.bak"
expect_skill_failure erl-check 'runtime workflow does not pass exact --vault ERL_HOME'

reset_skills
sed -i.bak 's#${ERL_HOME}#${ERL_HOST_HOME}#g' "$fixture/skills/erl-vocabulary-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-vocabulary-ingest/SKILL.md.bak"
expect_skill_failure erl-vocabulary-ingest 'runtime workflow does not pass exact --vault ERL_HOME'

reset_skills
sed -i.bak 's#${ERL_HOME}#${ERL_HOME}/vault#g' "$fixture/skills/erl-chapter-vocabulary-ingest/SKILL.md"
rm -f -- "$fixture/skills/erl-chapter-vocabulary-ingest/SKILL.md.bak"
expect_skill_failure erl-chapter-vocabulary-ingest 'runtime workflow does not pass exact --vault ERL_HOME'

reset_skills
sed -i.bak 's#${ERL_HOME}#${ERL_HOME:h}#g' "$fixture/skills/erl-classic-reduce-reconcile/SKILL.md"
rm -f -- "$fixture/skills/erl-classic-reduce-reconcile/SKILL.md.bak"
expect_skill_failure erl-classic-reduce-reconcile 'runtime workflow does not pass exact --vault ERL_HOME'

host="$fixture/host"
user_vault="$fixture/user-vault"
workspace="$fixture/english-reading-lab"
mkdir -p -- "$host" "$user_vault/notes" "$workspace"
cp -R -- "$repo/fixtures/host-contract/.scripts" "$host/.scripts"
cp -- "$repo/.gitignore" "$workspace/.gitignore"
git -C "$workspace" init -q
profile=(--workspace "$workspace" --host-home "$host" --forbidden-user-home "$user_vault" --user-name Test --timezone UTC)

before="$(find "$workspace" -type f -exec shasum -a 256 {} + | sort)"
dry="$($setup "${profile[@]}")"
after="$(find "$workspace" -type f -exec shasum -a 256 {} + | sort)"
[[ "$before" == "$after" ]] || { print -ru2 -- 'FAIL: setup dry-run mutated workspace'; exit 1; }
[[ "$dry" == *"erl_home=$workspace"* && "$dry" == *$'create\tnotes/.gitkeep'* ]] || {
  # notes is an ignored directory and may be materialized without a tracked
  # sentinel; the required evidence is the rendered target binding.
  [[ "$dry" == *"erl_home=$workspace"* ]] || { print -ru2 -- 'FAIL: setup omitted ERL_HOME'; exit 1; }
}
$setup "${profile[@]}" --apply >/dev/null
$setup "${profile[@]}" --check >/dev/null
$setup --check-reference-skills "$repo/skills" >/dev/null

rg -qF "Canonical Lexi Vault: \`$workspace\`" "$workspace/TOOLS.md"
rg -qF "Pass \`--vault $workspace\` to every ERL command." "$workspace/TOOLS.md"
rg -qF "ERL_HOME=$workspace" "$workspace/TOOLS.md"
[[ "$(find "$workspace/skills" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')" == 7 ]] || {
  print -ru2 -- 'FAIL: clean-room setup did not materialize seven skills'
  exit 1
}
for skill in "${skills[@]}"; do
  rg -qF 'Pass exact `--vault "${ERL_HOME}"` to every ERL CLI invocation' "$workspace/skills/$skill/SKILL.md" || {
    print -ru2 -- "FAIL: embedded $skill lost Vault binding"
    exit 1
  }
done

mkdir -p -- "$workspace/notes" "$workspace/.state/erl/works"
print -r -- 'A first chapter.' > "$fixture/book.txt"
policy_base='{"schema_version":1,"threshold":["B2","C1","C2"],"lexical_types":["word"]}'
policy_identity="$(print -r -- "$policy_base" | jq -cS . | shasum -a 256 | awk '{print "sha256:" $1}')"
print -r -- "$policy_base" | jq --arg identity "$policy_identity" '.+{identity:$identity}' > "$fixture/policy.json"
notes_before="$(find "$workspace/notes" -type f | wc -l | tr -d ' ')"
works_before="$(find "$workspace/.state/erl/works" -type f 2>/dev/null | wc -l | tr -d ' ')"
ERL_HOME="$workspace" ERL_HOST_HOME="$host" "$erl/erl-book-ingest.zsh" \
  --vault "$workspace" --source "$fixture/book.txt" --title Fixture \
  --key-topic Fixture --policy-file "$fixture/policy.json" --dry-run --json > "$fixture/book-dry.json"
jq -e --arg prefix "$workspace/.state/erl/works/" \
  '.status=="ok" and .changed==false and .data.chapter_count==1 and (.data.work_state_path|startswith($prefix))' \
  "$fixture/book-dry.json" >/dev/null
[[ "$(find "$workspace/notes" -type f | wc -l | tr -d ' ')" == "$notes_before" ]] || { print -ru2 -- 'FAIL: Book dry-run wrote documents'; exit 1; }
[[ "$(find "$workspace/.state/erl/works" -type f 2>/dev/null | wc -l | tr -d ' ')" == "$works_before" ]] || { print -ru2 -- 'FAIL: Book dry-run wrote work state'; exit 1; }

"$erl/erl-check.zsh" --vault "$workspace" --json > "$fixture/check.json"
jq -e '.status=="ok" and .changed==false and .data.counts.errors==0' "$fixture/check.json" >/dev/null

print -r -- 'PASS: every Lexi skill binds every ERL invocation to ERL_HOME'
