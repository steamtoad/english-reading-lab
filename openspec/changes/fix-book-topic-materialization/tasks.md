## 1. Regression Contract

- [ ] 1.1 Создать primary regression test `tests/erl-book-topic-materialization.zsh`, который использует разные Book title и thematic key и проверяет, что созданный `notes/<generation_uuid>.adoc` является canonical Topic книги; verification: test должен падать на текущей реализации и проходить после исправления
- [ ] 1.2 Добавить negative fixtures для missing Topic, wrong canonical type и thematic-only presentation; verification: `erl-check` возвращает разные validation diagnostics без mutation

## 2. Book Topic Materialization

- [ ] 2.1 Изменить ERL-owned `erl-book-ingest.zsh`, чтобы visible Topic title основывался на canonical logical-work title, а `:key-topic:` сохранял переданный thematic key; verification: `tests/erl-book-topic-materialization.zsh`
- [ ] 2.2 Добавить post-construction validation существования, UUID, canonical type и Book presentation до публикации generation state; verification: fault fixture не возвращает successful `generation_uuid` и не оставляет active/retained generation
- [ ] 2.3 Включить Topic validation failure и последующие state failures в ingest transaction rollback/recovery; verification: fault-injection tests подтверждают отсутствие partial Topic/state и сохранность предыдущего work state

## 3. Validation And Compatibility

- [ ] 3.1 Расширить `erl-check.zsh` read-only validation согласно `ERL-CHECK-021`; verification: missing, wrong-type и wrong-presentation fixtures диагностируются, а hashes Vault/state до и после проверки совпадают
- [ ] 3.2 Обновить CLI contract и legacy traceability для `ERL-BOOK-006`, `ERL-BOOK-007`, `ERL-BOOK-013`, нового `ERL-BOOK-014` и `ERL-CHECK-021`; verification: contract search показывает все IDs и не вводит `:erl-*:` metadata
- [ ] 3.3 Выполнить read-only audit существующих works и зафиксировать найденные legacy gaps без автоматического исправления; verification: audit report различает valid и invalid Book generations и не изменяет target Zettelkasten home

## 4. Verification

- [ ] 4.1 Запустить focused tests `tests/erl-book-topic-materialization.zsh`, `tests/erl-cli.zsh` и `tests/erl-check.zsh`; verification: все завершаются успешно
- [ ] 4.2 Запустить `zsh -n` для изменённых scripts/tests, `git diff --check`, protected-path audit и `openspec validate --all`; verification: проверки проходят, host core и пользовательский Vault не изменены
