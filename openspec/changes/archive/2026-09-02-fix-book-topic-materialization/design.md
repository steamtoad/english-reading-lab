## Context

Baseline уже требует `Book = Topic` (`ERL-BOOK-006`, `ERL-DOC-001`) и связывает generation identity с Topic UUID (`ERL-BOOK-007`). Текущий ingest вызывает canonical Topic constructor, но передаёт presentation, построенную из thematic `key-topic`; title logical work сохраняется отдельно. Тесты проверяют type и host presentation, но не проверяют, что Topic узнаваемо представляет саму книгу.

## Goals / Non-Goals

**Goals:**

- сделать Book Topic обязательным материальным artifact каждой successful generation;
- разделить presentation книги и thematic classification;
- запретить state-only success и обеспечить rollback при частичной materialization;
- обнаруживать уже существующий gap read-only проверкой.

**Non-Goals:**

- менять canonical Topic constructor или host metadata contract;
- добавлять `:erl-*:` attributes либо использовать `:key-topic:` как ERL foreign key;
- автоматически исправлять пользовательские Vault documents;
- менять `WORK_ID`, Book Topic UUID или Chapter identity.

## Decisions

### Book title and thematic key remain separate

Canonical title logical work становится основой visible Book Topic title, тогда как `--key-topic` продолжает заполнять thematic `:key-topic:`. Это сохраняет host semantics и делает Topic узнаваемой как книга. Альтернатива хранить название книги только в body отвергнута: она оставляет Topic list и title-based navigation тематическими, а не книжными.

### Generation success requires a validated Topic artifact

Ingest может сообщить success и опубликовать active generation только после проверки созданного `notes/<generation_uuid>.adoc`: файл существует, имеет canonical type `topic`, UUID совпадает с state, presentation соответствует logical work title и thematic key. Альтернатива доверять только успешному exit code constructor отвергнута: она не защищает от wrong target root или несовместимой presentation.

### Existing gaps are diagnosed, not silently repaired

`erl-check` получает отдельные diagnostics для missing document, wrong type и wrong Book presentation. Исправление существующих generations потребует отдельной explicit migration с dry-run и apply. Это сохраняет read-only contract checker и не перезаписывает пользовательские документы без разрешения.

### Ingest remains one recoverable transaction

Book Topic создаётся до state publication, но считается provisional artifact transaction. Ошибка на любом следующем шаге удаляет только artifacts этой transaction или восстанавливает backups. Existing work state и пользовательские документы вне transaction не затрагиваются.

## Risks / Trade-offs

- [Изменение title может отличаться от ранее созданных Topic] → применять новую presentation к новым generations; legacy generations только диагностировать до explicit migration.
- [Canonical work title может содержать неудобную для Topic presentation строку] → использовать тот же host constructor и его escaping/normalization contract, не вводя ERL-local formatter.
- [Проверка title может дать false positive после ручного редактирования] → сравнивать с canonical presentation, вычисленной из persistent logical-work title и host contract; diagnostic остаётся read-only.
- [Failure после создания Topic оставит partial artifact при crash] → transaction journal хранит created artifact до state mutation, а recovery обрабатывает незавершённый ingest.

## Migration Plan

1. Добавить primary regression test `tests/erl-book-topic-materialization.zsh` с Book title, отличным от thematic key.
2. Исправить ingest presentation и post-creation validation; расширить transaction recovery fixtures.
3. Расширить `erl-check` read-only diagnostics для retained/active generation.
4. Обновить CLI contract и legacy traceability.
5. Выполнить read-only audit существующих works. Legacy gaps не исправлять автоматически; при их наличии оформить отдельную explicit migration.

Rollback implementation возвращает прежнее построение presentation и validation rules для новых ingest, не изменяя уже созданные Vault documents или persistent identities.
