## 1. Регрессионный контракт

- [x] 1.1 Создать primary test `tests/erl-human-readable-card-content.zsh` с positive fixtures Book, Chapter, Vocabulary и Occurrence; проверить valid UTF-8 AsciiDoc, non-empty title/body и role-relevant content.
- [x] 1.2 Добавить negative fixtures для malformed AsciiDoc/UTF-8, empty title/body/value, raw JSON/YAML и HTML/XML вместо content, control characters, unresolved placeholders и нечитабельных link labels; проверить ожидаемые diagnostics `ERL-CHECK-030`.

## 2. Человекочитаемое создание карточек

- [x] 2.1 Дополнить Book creation readable body, идентифицирующим книгу и содержащим descriptive/navigation information; проверить Book fixture и сохранение canonical Topic presentation contract.
- [x] 2.2 Дополнить Chapter creation readable book/chapter context и labelled technical values; проверить Chapter fixture и отсутствие ERL-specific attributes.
- [x] 2.3 Нормализовать Vocabulary body как читаемые labelled lexical identity, meaning и available context; проверить совместимость с `ERL-VOC-003` и escaping source values.
- [x] 2.4 Нормализовать Occurrence body с readable Vocabulary link label и non-empty Context; проверить совместимость с `ERL-OCC-004` и escaping source values.

## 3. Validation

- [x] 3.1 Реализовать deterministic common checks UTF-8, supported AsciiDoc syntax, non-empty title/body/required values и machine-oriented artifacts; проверить positive/negative primary fixtures без subjective text scoring.
- [x] 3.2 Интегрировать `ERL-CHECK-030` в read-only `erl-check` для всех registered card roles; проверить document UUID, recorded role и exact violated condition в diagnostic и неизменность Vault/state.

## 4. Legacy audit и repair

- [x] 4.1 Добавить read-only audit/dry-run существующих ERL cards с exact findings и proposed changes; проверить, что dry-run не изменяет bytes документов или state.
- [x] 4.2 Реализовать explicit repair с backups, journal, conflict detection и rollback без перезаписи пользовательских sections; проверить apply, ambiguous conflict и fault-injection recovery fixtures.
- [x] 4.3 Обновить CLI contract и legacy requirements traceability для `ERL-DOC-008` и `ERL-CHECK-030`; проверить наличие обоих IDs, audit/apply и recovery semantics.

## 5. Итоговая проверка

- [x] 5.1 Запустить primary test и существующие Book ingest, Chapter ingest, Vocabulary/Occurrence ingest, validation и transaction recovery suites; проверить успешное завершение всех релевантных тестов.
- [x] 5.2 Выполнить `zsh -n` для изменённых Zsh scripts, `git diff --check`, protected-path review и `openspec validate --all`; проверить отсутствие syntax, whitespace, repository-boundary и OpenSpec errors.
