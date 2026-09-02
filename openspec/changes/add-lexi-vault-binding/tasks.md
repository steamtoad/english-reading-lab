## 1. Primary regression contract

- [x] 1.1 Создать primary test `tests/erl-lexi-vault-binding.zsh`, проверяющий exact `--vault "${ERL_HOME}"` contract во всех семи Lexi skills, common reference и generated `TOOLS.md`; запустить test и получить PASS.
- [x] 1.2 Добавить negative fixtures с missing binding, пользовательским Zettelkasten path, parent/nested Vault и host-root substitution; проверить deterministic failure с именем drifted skill/path.

## 2. Skill и setup contracts

- [x] 2.1 Обновить source `erl-agent-contract-v1.md` и byte-exact reference copies всех семи skills; проверить `erl-skills-check.zsh` и reference hash consistency.
- [x] 2.2 Расширить skill packaging checker обязательной Vault-binding проверкой для каждого supported skill; проверить clean и negative fixtures.
- [x] 2.3 Обновить `TOOLS.md` rendering, Lexi runtime documentation и embedded setup payload; проверить payload/reference synchronization и clean-room materialization без исходной `skills/`.

## 3. Target-home и host separation

- [x] 3.1 Зафиксировать ignored root `notes/` как document area Lexi workspace и отдельное разрешение host root через target-home host contract либо `ERL_HOST_HOME`; проверить, что host root не подставляется в `--vault` и protected host core не изменён.
- [x] 3.2 Выполнить setup dry-run/check и reviewed replacement fixture для существующего workspace; проверить backup, journal, idempotency и новый payload hash.

## 4. Functional verification

- [x] 4.1 Запустить Book ingest `--dry-run --json` с `--vault "${ERL_HOME}"`; проверить expected Chapter count, отсутствие mutation и `work_state_path` под `${ERL_HOME}/.state/erl/works/`.
- [x] 4.2 Запустить `erl-check.zsh --vault "${ERL_HOME}" --json`, setup/skills tests и optional live routing; проверить ноль validation errors и корректный routing семи skills.

## 5. Requirements и final gates

- [x] 5.1 Добавить `ERL-AGENT-SETUP-009` в legacy traceability и обновить user/developer documentation; проверить exact ID occurrence и явное разделение target Vault/host root.
- [x] 5.2 Подключить primary test к `tests/erl-all.zsh` и запустить полный non-live suite; проверить PASS без mutation пользовательского Vault.
- [x] 5.3 Выполнить `zsh -n`, `git diff --check`, protected-path audit, `openspec validate add-lexi-vault-binding --strict` и `openspec validate --all`; проверить отсутствие syntax, whitespace, boundary и specification errors.
