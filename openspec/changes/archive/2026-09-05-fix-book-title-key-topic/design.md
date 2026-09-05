## Context

Book Topic уже имеет canonical visible title, а Chapters связаны с ней reciprocal UUID links. Но действующий `ERL-BOOK-012/013` трактует `:key-topic:` как отдельную пользовательскую классификацию. В результате `Friday` и Chapters этой книги могут получить общий key `English Reading`, хотя требуемая группировка должна называться `Friday`.

Изменение распространяется дальше Chapter: Vocabulary первого приобретения и Occurrence наследуют Chapter key. Поэтому исправление только показанного Chapter создаст нарушение Chapter–Memo contract и не является допустимой миграцией.

## Goals / Non-Goals

**Goals:**

- обеспечить exact equality `Book title == Book Topic key-topic == Chapter key-topic`;
- сохранить эту книгу-специфичную группировку у новых Vocabulary/Occurrence;
- предотвращать новый drift до первой Vault mutation;
- безопасно исправлять существующий active work одной recoverable operation;
- диагностировать stale key read-only.

**Non-Goals:**

- использовать `WORK_ID`, UUID или source locator как `:key-topic:`;
- переименовывать title книги, Chapter UUID или reciprocal links;
- автоматически переносить документы между Vault;
- молча исправлять существующие документы во время `erl-check`.

## Decisions

### Exact canonical title is the key

Значение `:key-topic:` равно canonical title logical work byte-for-byte после уже существующей CLI validation title. Для примера `Friday` canonical key — `Friday`. Дополнительная нормализация, slugification и общий umbrella key `English Reading` не применяются.

Название книги остаётся человекочитаемой host grouping value, а не ERL foreign key. Relationships по-прежнему восстанавливаются через work state и canonical UUID links, не через `:key-topic:`.

### A conflicting explicit key fails before mutation

Пока public CLI поддерживает `--key-topic`, omitted value может выводиться из `--title`, а явное значение разрешено только при exact equality title. Несовпадающее значение завершается deterministic usage/validation error до constructors, journal и state writes. Молчаливое игнорирование аргумента отклонено как вводящее пользователя в заблуждение.

### Descendants inherit one book-title grouping

Chapter получает key из validated Book Topic, а Vocabulary/Occurrence — из Chapter. Это сохраняет действующее направление наследования и не добавляет новый metadata field. Existing global Vocabulary сохраняет key книги первого приобретения; последующий Occurrence получает key текущей книги.

### Migration covers the complete active projection

Explicit migration принимает `--vault` и `--work`, строит dry-run plan для active Book Topic, всех registered Chapters и всех attached Vocabulary/Occurrence документов, key которых должен следовать изменяемой Chapter. Apply повторно проверяет preconditions и выполняет byte-exact backups, journal, atomic replacement, post-validation и rollback при ошибке.

Неизвестный пользовательский контент и документы с неоднозначной принадлежностью дают conflict вместо overwrite. Deprecated historical generations автоматически не переписываются.

### Checker remains read-only

`erl-check` сравнивает Book Topic title/key, Chapter key и применимые Memo keys. Ошибка сообщает work/generation/document UUID, expected canonical title и actual value, но ничего не изменяет.

Primary regression test, выведенный из change name: `tests/erl-book-title-key-topic.zsh`.

## Risks / Trade-offs

- [Две книги имеют одинаковый title] → key-topic является host grouping, не identity; UUID/work state продолжают различать works.
- [Существующая global Vocabulary приобретена в другой книге] → её key не перепривязывается; новый Occurrence наследует текущую Chapter.
- [Partial migration разрывает Chapter–Memo equality] → complete projection transaction и post-validation обязательны.
- [Пользователь ожидает umbrella topic] → отдельный `English Reading` больше не допустим как Book/Chapter key; umbrella navigation должна выражаться другими canonical links/content.
- [Title изменён после ingest] → checker фиксирует drift; rename/migration выполняется explicit workflow, а не read-only validation.

## Migration Plan

1. Добавить primary regression и negative fixtures для `Friday`/`English Reading`.
2. Сделать Book Topic key детерминированным от canonical title и добавить pre-mutation CLI conflict check.
3. Обновить Chapter и Memo propagation, transaction validation и rollback fixtures.
4. Добавить read-only checker rule и explicit migration dry-run/apply/recovery.
5. Обновить CLI contract и legacy traceability.
6. Выполнить focused, migration, integration и OpenSpec gates.

Rollback реализации возвращает прежний код. Rollback конкретной миграции восстанавливает byte-exact documents из journal backups и не публикует новый committed state.
