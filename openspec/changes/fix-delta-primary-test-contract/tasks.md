## 1. Primary Regression Contract

- [ ] 1.1 Создать canonical primary regression test `tests/erl-delta-primary-test-contract.zsh`, проверяющий полный prefix mapping, lifecycle gate и exact diagnostics; verification: test падает при отсутствии `remove-` mapping и проходит после реализации
- [ ] 1.2 Добавить fixtures для `fix-`, `add-`, `change-`, `update-`, `migrate-`, `refactor-`, `implement-`, `remove-` и change без известного prefix; verification: для каждого имени вычисляется один exact `tests/erl-<behavior-slug>.zsh`

## 2. Naming Gate Fix

- [ ] 2.1 Обновить `erl-delta-test-naming-check.zsh`, добавив удаление ровно одного leading `remove-` наряду с остальными normative prefixes; verification: completed `remove-chapter-vocabulary-quota` принимается при наличии `tests/erl-chapter-vocabulary-quota.zsh`
- [ ] 2.2 Сохранить lifecycle-aware поведение: planning changes с незавершёнными implementation tasks не блокируют suite, а completed changes без canonical primary test блокируют completion/archive с change name и exact path; verification: positive и negative naming fixtures
- [ ] 2.3 Проверить, что дополнительный или ошибочно названный `erl-remove-chapter-vocabulary-quota.zsh` не требуется и не заменяет canonical derivation; verification: fixture проходит только с `erl-chapter-vocabulary-quota.zsh`

## 3. Explicit Rule And Traceability

- [ ] 3.1 Синхронизировать legacy `ERL-TEST-001/002` с OpenSpec: primary regression test обязателен для каждой ERL-дельты к завершению implementation и archive; verification: contract search находит обязательность, полный prefix set и archive gate
- [ ] 3.2 Обновить ERL agent/change authoring guidance и validation checklist, потребовав явную task на создание или обновление derived primary test и её запуск; verification: static contract fixture обнаруживает отсутствие правила или несовпадающий prefix set
- [ ] 3.3 Сохранить planning-only исключение и запретить трактовать его как освобождение от test; verification: незавершённая fixture проходит naming gate, та же fixture со всеми `[x]` без test завершается failure

## 4. Verification

- [ ] 4.1 Запустить `tests/erl-delta-primary-test-contract.zsh`, `tests/erl-delta-test-naming-gate.zsh` и `tests/erl-chapter-vocabulary-quota.zsh`; verification: все три test завершаются успешно
- [ ] 4.2 Запустить `.scripts/erl/dev/erl-delta-test-naming-check.zsh` и `tests/erl-all.zsh`; verification: прежний blocker для `remove-chapter-vocabulary-quota` отсутствует и suite не требует `erl-remove-chapter-vocabulary-quota.zsh`
- [ ] 4.3 Запустить `zsh -n` для изменённых scripts/tests, `openspec validate --all`, `git diff --check` и protected-path audit; verification: проверки проходят, host core и пользовательский Vault не изменены
