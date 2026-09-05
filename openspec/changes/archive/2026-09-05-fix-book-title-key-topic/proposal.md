## Why

Сейчас ERL допускает независимый thematic `:key-topic:` для Book Topic и наследует его во все Chapter Notes. Поэтому книга `Friday` может создать Chapter с `:key-topic: English Reading`: документ связан с правильной Book Topic по UUID, но визуальная тематическая принадлежность не идентифицирует книгу и смешивает Chapters разных книг под общей темой.

## What Changes

- Сделать canonical title logical work единственным допустимым значением `:key-topic:` Book Topic.
- Обязать все Chapter Notes active generation иметь тот же exact book-title key.
- Сохранить наследование этого значения создаваемыми Vocabulary и Occurrence Memo.
- Отклонять до mutation явный `--key-topic`, если он не совпадает с canonical title книги.
- Расширить `erl-check` диагностикой Book/Chapter/Memo key, не совпадающего с canonical title.
- Добавить явную транзакционную миграцию существующих active works с прежнего thematic key на book-title key.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `work-generation`: Book Topic `:key-topic:` становится exact canonical title книги.
- `source-chapters`: Chapter key наследует book-title key active Book Topic.
- `vocabulary-ingestion`: новые Vocabulary/Occurrence сохраняют book-title grouping своей Chapter.
- `validation`: checker проверяет title-derived key во всей materialized цепочке.
- `vault-integration`: использование title книги как host key-topic определяется как canonical grouping, а не ERL foreign key.

## Impact

Будущая реализация затронет `erl-book-ingest`, Chapter/Topic binding и migration tooling, vocabulary ingestion validation, `erl-check`, CLI contract, legacy traceability и regression tests. Схемы UUID, `WORK_ID`, reciprocal links и source identity не меняются.

Для уже созданной книги `Friday` значение `English Reading` не должно исправляться прямым редактированием Vault. Требуется explicit dry-run/apply migration с journal, rollback и post-validation. Host core и пользовательский Vault вне explicit `--vault` не изменяются.
