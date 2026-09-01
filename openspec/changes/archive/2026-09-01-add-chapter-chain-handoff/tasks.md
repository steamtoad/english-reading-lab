## 1. Регрессионный контракт

- [x] 1.1 Создать primary test `tests/erl-chapter-chain-handoff.zsh` для normal, terminal, empty и idempotent retry cases и проверить, что он воспроизводит gap до реализации.
- [x] 1.2 Добавить negative fixtures для отсутствующей reciprocal link, duplicate link, неверного `SOURCE_ID`/source-order adjacency, stale non-tail link и handoff terminal Chapter; проверить ожидаемые ошибки `ERL-CHECK-029`.

## 2. Материализация handoff

- [x] 2.1 Реализовать deterministic resolution непосредственно следующей Chapter по `SOURCE_ID` и `source_order`; проверить cases adjacent, terminal и foreign source в primary test.
- [x] 2.2 Добавить tail Memo section `Reading handoff` с link `Следующая глава` и reciprocal Chapter Note link `Последнее memo предыдущей главы`; проверить exact targets, labels и отсутствие duplicate links.
- [x] 2.3 Сохранить Chapter-local Memo Chains раздельными и не создавать handoff для terminal Chapter или Chapter без Memo Chain; проверить отсутствие cross-Chapter Memo predecessor и synthetic links.

## 3. Транзакция и recovery

- [x] 3.1 Включить backups/hashes tail Memo и next Chapter Note в batch-finalization journal до mutation; проверить journal fixture и восстановление исходных bytes.
- [x] 3.2 Сделать обе document updates и completed Chapter result одной recoverable semantic operation; проверить fault injection после первой записи, rollback и `RECOVERY_REQUIRED` path.
- [x] 3.3 Реализовать idempotent retry и transactional replacement stale handoff при смене tail; проверить отсутствие duplicates и one-sided committed state.

## 4. Validation и migration

- [x] 4.1 Расширить `erl-check` read-only проверкой `ERL-CHECK-029`; проверить reciprocity, uniqueness, current tail, same-source adjacency и terminal/empty exceptions без изменения Vault/state.
- [x] 4.2 Добавить explicit migration/rebuild существующих completed chains с dry-run, apply, conflict detection, journal, rollback и recovery; проверить, что конфликтующий пользовательский `Reading handoff` не перезаписывается.
- [x] 4.3 Обновить CLI contract и legacy requirements traceability для `ERL-CHAPTER-016`, `ERL-SEQ-012`, `ERL-SEQ-013` и `ERL-CHECK-029`; проверить наличие всех ID и описанных exit/recovery semantics.

## 5. Итоговая проверка

- [x] 5.1 Запустить primary test и существующие релевантные chapter-chain, CLI, validation и recovery suites; проверить успешное завершение всех тестов.
- [x] 5.2 Выполнить `zsh -n` для изменённых Zsh scripts, `git diff --check`, protected-path review и `openspec validate --all`; проверить отсутствие syntax, whitespace, boundary и OpenSpec errors.
