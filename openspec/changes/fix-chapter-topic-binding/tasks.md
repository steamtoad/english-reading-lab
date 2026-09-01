## 1. Regression Contract

- [ ] 1.1 Создать primary regression test `tests/erl-chapter-topic-binding.zsh` для exact `:key-topic:`, Chapter→Topic link, Topic→Chapter links, uniqueness и source order; verification: test падает на текущем ingest и проходит после исправления
- [ ] 1.2 Добавить negative fixtures для missing/mismatched `:key-topic:`, односторонней link, duplicate link, неверного source order и двух active Topic attachments; verification: focused checker test получает отдельный `ERL-CHECK-027` diagnostic для каждого нарушения

## 2. Initial Binding

- [ ] 2.1 Расширить ERL host-contract test fixture, чтобы он принимал canonical Note с host-defined `:key-topic:` без изменения production host core; verification: fixture создаёт canonical Note и сохраняет точное key value
- [ ] 2.2 Обновить `erl-book-ingest.zsh`, чтобы новые Chapter Notes получали header `:key-topic:` из созданной Book Topic и секцию `Book` с одной canonical Topic link; verification: `tests/erl-chapter-topic-binding.zsh`
- [ ] 2.3 Добавить в Book Topic секцию `Chapters` с одной canonical link на каждую Chapter Note в source order; verification: focused test проверяет точный ordered UUID list и отсутствие duplicates

## 3. Rebind And Transaction Safety

- [ ] 3.1 Реализовать rebind reused durable Chapter Notes к новой active Book Topic без изменения Chapter UUID; verification: regeneration fixture сохраняет Chapter UUID, заменяет current Topic link и синхронизирует `:key-topic:`
- [ ] 3.2 Расширить ingest transaction journal backups на изменяемые Book Topic и existing Chapter Notes до первой mutation; verification: journal fixture содержит paths и pre-hashes всех изменяемых documents
- [ ] 3.3 Добавить fault-injection tests для ошибок header/link/Topic update и recovery; verification: rollback byte-for-byte восстанавливает previous Chapter documents/state и не оставляет partial generation

## 4. Validation And Migration

- [ ] 4.1 Расширить `erl-check.zsh` read-only проверкой `ERL-CHECK-027`; verification: positive и negative fixtures проходят, а hashes documents/state до и после checker совпадают
- [ ] 4.2 Спроектировать и реализовать отдельную explicit migration legacy Chapter–Topic bindings с `--dry-run`/`--apply`, conflict detection, journal, rollback и recovery; verification: dry-run mutation-free, repeat apply idempotent, conflicts не перезаписывают пользовательские sections
- [ ] 4.3 Обновить CLI contract и legacy traceability для `ERL-CHAPTER-012..015` и `ERL-CHECK-027`; verification: все IDs находятся contract checks, `:key-topic:` описан только в host thematic semantics, `:erl-*:` не добавлены

## 5. Verification

- [ ] 5.1 Запустить `tests/erl-chapter-topic-binding.zsh`, `tests/erl-cli.zsh`, `tests/erl-check.zsh` и migration/recovery tests; verification: все focused workflows завершаются успешно
- [ ] 5.2 Запустить `zsh -n` для изменённых scripts/tests, `git diff --check`, protected-path audit и `openspec validate --all`; verification: проверки проходят, host core и пользовательский Vault не изменены
