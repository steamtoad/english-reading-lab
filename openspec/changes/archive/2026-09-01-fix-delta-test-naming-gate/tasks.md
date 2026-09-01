## 1. Lifecycle regression contract

- [x] 1.1 Создать primary test `tests/erl-delta-test-naming-gate.zsh` с isolated minimal repository fixtures; проверить, что incomplete 0/N и partial N/M changes без primary test не завершают naming validation ошибкой.
- [x] 1.2 Добавить completed missing-primary и additional-only fixtures; проверить exit 10 и diagnostic с exact change name/expected `tests/erl-<behavior-slug>.zsh`.
- [x] 1.3 Добавить completed-with-primary fixtures для `fix-`, `add-` и change name без известного prefix; проверить сохранение deterministic `ERL-TEST-001` derivation.

## 2. Lifecycle-aware naming checker

- [x] 2.1 Изменить `.scripts/erl/dev/erl-delta-test-naming-check.zsh`, чтобы он классифицировал change как completed только при существующем `tasks.md`, наличии parseable checkbox и отсутствии `- [ ]`; проверить primary lifecycle fixtures.
- [x] 2.2 Сохранить exact primary path check для completed changes и исключение `archive/`; проверить существующие completed ERL changes и negative fixture без подмены additional test.
- [x] 2.3 Проверить текущий repository с incomplete `add-openclaw-agent-setup` и отсутствующим `tests/erl-openclaw-agent-setup.zsh`; naming checker не должен выдавать setup missing-primary diagnostic, tasks исходной change должны остаться 0/14, а независимый completed-change failure должен быть сообщён отдельно.

## 3. Traceability и integration

- [x] 3.1 Добавить `ERL-TEST-002` в `.scripts/erl/docs/requirements.md` рядом с `ERL-TEST-001`; проверить exact ID и lifecycle semantics без изменения naming algorithm.
- [x] 3.2 Подключить `tests/erl-delta-test-naming-gate.zsh` к `tests/erl-all.zsh`; проверить, что suite проходит прежний setup-test blocker и продолжает обнаруживать completed change без primary test.
- [x] 3.3 Запустить primary test, repository naming checker, `zsh -n`, `git diff --check`, protected-path audit, `openspec validate fix-delta-test-naming-gate --strict` и `openspec validate --all`; проверить отсутствие новых failures и изменений host core/Vault.
