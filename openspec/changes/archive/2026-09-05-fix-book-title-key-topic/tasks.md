## 1. Primary regression contract

- [x] 1.1 Создать primary test `tests/erl-book-title-key-topic.zsh` для Book `Friday`; проверить exact `:key-topic: Friday` у Book Topic и всех Chapters и отсутствие `:key-topic: English Reading`.
- [x] 1.2 Добавить negative fixtures для conflicting `--key-topic`, missing/mismatched Book key, Chapter key и Memo key; проверить deterministic error с expected/actual values и document UUID.

## 2. Ingest и propagation

- [x] 2.1 Обновить `erl-book-ingest.zsh`: omitted key выводится из canonical title, а explicit mismatched key отклоняется до mutation; проверить dry-run/apply и отсутствие constructors/state writes при conflict.
- [x] 2.2 Материализовать Book Topic и новые/reused Chapters с exact title key в существующей generation transaction; проверить UUID/link preservation, journal coverage и rollback.
- [x] 2.3 Проверить Vocabulary/Occurrence inheritance book-title key через Chapter, включая existing global Vocabulary и новый Occurrence другой книги.

## 3. Validation и migration

- [x] 3.1 Расширить `erl-check` read-only проверкой Book title/key и descendant key consistency; проверить clean и stale fixtures без mutation.
- [x] 3.2 Добавить explicit migration `erl-book-title-key-topic-migrate.zsh` с `--vault`, `--work`, dry-run/apply, conflict detection, byte-exact backups, journal, post-validation и rollback.
- [x] 3.3 Проверить migration книги `Friday`: Topic, 35 Chapters и применимые Memo обновляются одной transaction; повторный apply idempotent, interruption recovery восстанавливает согласованное состояние.

## 4. Contracts и final gates

- [x] 4.1 Обновить CLI contract и legacy traceability для изменённых `ERL-BOOK-012/013`, `ERL-CHAPTER-012/014`, `ERL-ING-010`, `ERL-DOC-005`, `ERL-CHECK-021/027`; проверить отсутствие противоречащего separate thematic-key wording.
- [x] 4.2 Подключить primary test к `tests/erl-all.zsh` и выполнить focused/integration suite; проверить отсутствие mutation пользовательского Vault и protected host core.
- [x] 4.3 Выполнить `zsh -n`, `git diff --check`, protected-path audit, `openspec validate fix-book-title-key-topic --strict` и `openspec validate --all`.
