## 1. Primary regression contract

- [x] 1.1 Создать primary test `tests/erl-lexi-host-root-separation.zsh`, проверяющий `ERL-ARCH-010` и `ERL-AGENT-SETUP-012`; запустить test и получить PASS.
- [x] 1.2 Добавить positive fixture с target `/Users/steamtoad/pub/english-reading-lab`, host `/Users/steamtoad/dev/zettelkasten-cli` и отдельным user Vault; проверить exact role resolution.
- [x] 1.3 Добавить negative fixtures для `/Users/steamtoad/zettelkasten` в каждой target/host role, equal/swapped roots, env/descriptor drift, relative paths и missing markers; проверить deterministic fail-before-mutation diagnostics.

## 2. Runtime root-role validation

- [x] 2.1 Добавить ERL-local preflight, canonicalizing target/host roots и проверяющий role-specific markers, disjoint identity и configured forbidden user root; запустить focused common-library tests.
- [x] 2.2 Обновить host object-command resolution так, чтобы current Lexi profile использовал только `/Users/steamtoad/dev/zettelkasten-cli/.scripts/objects/`; проверить fixture trace без lookup в `/Users/steamtoad/zettelkasten`.
- [x] 2.3 Проверить все public mutating ERL commands на fail-closed behavior при invalid root roles и отсутствие изменений `notes/`/`.state/erl/works/`.

## 3. Setup configuration и repair transaction

- [x] 3.1 Расширить setup explicit/rendered inputs для `ERL_HOME`, `ERL_HOST_HOME` и forbidden user Vault; проверить dry-run output с тремя различными roles и portability fixture другой машины.
- [x] 3.2 Включить local host contract в managed transaction либо эквивалентный journal participant; проверить conflict detection, byte-exact backup, atomic publication, rollback и recovery-required injection cases.
- [x] 3.3 Добавить migration fixture с `host_root: /Users/steamtoad/zettelkasten`; проверить default no-mutation conflict и reviewed replacement на `/Users/steamtoad/dev/zettelkasten-cli`.
- [x] 3.4 Увеличить setup payload version/hash и проверить idempotent apply/check после successful root-binding replacement.

## 4. Skills, payload и functional proof

- [x] 4.1 Обновить common agent contract, семь reference copies, generated `TOOLS.md` и Lexi runtime documentation; проверить обязательное разделение `${ERL_HOME}`/`${ERL_HOST_HOME}` и запрет user Vault.
- [x] 4.2 Пересобрать embedded setup payload и выполнить `erl-openclaw-agent-setup.zsh --check-reference-skills "$PWD/skills"`; проверить byte-exact PASS и negative drift fixture.
- [x] 4.3 Выполнить clean-room setup без существующей local `skills/` и host contract; проверить создание полного payload и правильного root binding только из tracked source.
- [x] 4.4 Запустить Book ingest dry-run с `--vault "${ERL_HOME}"` и `ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli`; проверить work path под ERL workspace и constructor resolution из host repository без mutation user Vault.

## 5. Existing deployment rollout и final gates

- [x] 5.1 Добавить `ERL-ARCH-010` и `ERL-AGENT-SETUP-012` в legacy traceability и documentation; проверить unique IDs и exact current-machine root table.
- [x] 5.2 Выполнить non-mutating setup dry-run/check текущего Lexi workspace и сохранить проверяемый replacement plan; не применять его без отдельного explicit consent пользователя.
- [x] 5.3 Подключить primary test к `tests/erl-all.zsh`, запустить focused setup/skills/CLI tests и полный non-live suite; проверить, что `/Users/steamtoad/zettelkasten` byte-for-byte не изменён этой задачей.
- [x] 5.4 Выполнить `zsh -n`, `git diff --check`, protected-path audit, `openspec validate fix-lexi-host-root-separation --strict` и `openspec validate --all`; проверить отсутствие syntax, whitespace, boundary и specification errors.
