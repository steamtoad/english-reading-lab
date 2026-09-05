## 1. Согласование fixture

- [x] 1.1 В `tests/erl-human-readable-card-content.zsh` заменить header `:key-topic: Reading` у Book Topic, Chapter, Vocabulary и Occurrence на `:key-topic: A Human Book`, сохранить `Reading topic:: Reading` в body и проверить успешное завершение теста без exit code 60.
- [x] 1.2 В `tests/erl-chapter-chain-handoff.zsh` заменить header `:key-topic: Reading` у Book Topic, всех Chapters и Memo на `:key-topic: Handoff Book` и проверить успешное завершение теста и финального `erl-check` без exit code 1.

## 2. Regression gates

- [x] 2.1 Создать canonical primary test `tests/erl-book-title-key-topic-integration-fixtures.zsh`, который fail-fast запускает оба focused tests, подключить его к `tests/erl-all.zsh` и проверить самостоятельный успешный запуск primary test.
- [x] 2.2 Выполнить оба focused tests напрямую и `tests/erl-all.zsh`; проверить, что обновление не ослабило card-content, handoff или read-only validation assertions и не изменило production implementation.

## 3. Final validation

- [x] 3.1 Выполнить `zsh -n` для трёх затронутых test files, `git diff --check`, `openspec validate fix-book-title-key-topic-integration-fixtures --strict` и `openspec validate --all`; проверить отсутствие изменений host core и пользовательского Vault.
- [x] 3.2 Зафиксировать `ERL-TEST-003` в `engineering-safety` и legacy traceability; проверить, что requirement требует актуальных положительных integration fixtures без изменения runtime contract.
