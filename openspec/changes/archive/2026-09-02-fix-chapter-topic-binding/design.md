## Context

Chapter Notes создаются canonical Note constructor и регистрируются в source state, но текущий ingest дописывает только секцию `Source`. Book Topic не содержит перечня Chapters, Chapter Note не содержит link на Topic и не имеет `:key-topic:`. Host contract уже определяет `:key-topic:` как машинный ключ тематической группировки и связи документов; canonical internal link format также существует.

Chapter identity долговечна между semantic generations, тогда как active Book Topic UUID может меняться. Поэтому binding должен различать current active Vault attachment и historical ERL generation membership.

## Goals / Non-Goals

**Goals:**

- материализовать структуру Book→Chapters непосредственно в canonical Vault documents;
- обеспечить точный host-compatible `:key-topic:` на Chapter Notes;
- обеспечить взаимность и уникальность links;
- сохранить durable Chapter UUID при rebind;
- сделать initial binding, rebind и rollback recoverable.

**Non-Goals:**

- использовать `:key-topic:` как ERL-local identity или UUID relation;
- добавлять `:erl-*:` attributes;
- менять Chapter source identity или work-state schema;
- автоматически мигрировать существующий пользовательский Vault в рамках реализации ingest;
- изменять host core или Classic Zettelkasten workflow.

## Decisions

### Canonical structural sections

Chapter Note получает секцию `== Book` с одной canonical link на active Book Topic. Book Topic получает секцию `== Chapters` с canonical links в source order. Эти sections дают deterministic parsing и не требуют plugin-specific metadata.

Альтернатива полагаться только на global backlink search отвергнута: пользователь требует физическую двустороннюю связь, а отсутствие одной стороны должно детерминированно выявляться.

### key-topic is copied exactly from Topic

ERL читает непустой header `:key-topic:` созданной Book Topic и вставляет ту же строку в header Chapter Note. Значение не вычисляется из title, UUID или state. Это соответствует host semantics тематического attachment.

### One current attachment for durable Chapter

Chapter Note содержит одну current link на active Book Topic. При новой generation link и `:key-topic:` заменяются transactionally; historical membership остаётся в ERL state/audit. Topic старой generation не считается active reciprocal owner после rebind.

Альтернатива хранить несколько Topic links в Chapter отвергнута: один header `:key-topic:` не может однозначно представлять несколько active thematic attachments, а processing scope всегда использует одну active generation.

### ERL-local augmentation after canonical construction

Canonical Note и Topic по-прежнему создаются только host object constructors. ERL затем выполняет bounded augmentation разрешённых host attributes и body sections внутри ingest transaction. Host core не требует изменения: Note с `:key-topic:` и canonical links поддерживается существующей host model.

### Existing documents require explicit migration

`erl-check` только диагностирует legacy gaps. Отдельная migration должна иметь dry-run, exact plan, conflict detection для уже существующих `Book`/`Chapters` sections и `:key-topic:`, journal backups, post-validation и rollback. Неизвестный пользовательский контент не перезаписывается молча.

## Risks / Trade-offs

- [Chapter Note уже содержит пользовательскую секцию `Book`] → migration и ingest rebind блокируются с conflict diagnostic, пока ownership не разрешён явно.
- [Новая generation использует другой `:key-topic:`] → rebind обновляет current Chapter attachment transactionally; historical relation остаётся в audit/state.
- [Crash между изменением Chapter и Topic] → journal сохраняет hashes/backups всех изменяемых documents до первой mutation, recovery завершает rollback или commit.
- [Большая книга создаёт крупный список links в Topic] → links остаются линейными по Chapter count и записываются deterministic source order; whole-book text в Topic не копируется.

## Migration Plan

1. Реализовать primary regression test `tests/erl-chapter-topic-binding.zsh` для initial ingest, exact key equality, reciprocal links и source order.
2. Расширить ingest journal backup coverage на Book Topic и reused Chapter Notes до mutation.
3. Добавить deterministic `Book`/`Chapters` augmentation и post-ingest validation.
4. Расширить `erl-check` согласно `ERL-CHECK-027`.
5. Добавить отдельную explicit migration для legacy works с dry-run/apply/recovery до массового исправления существующего Vault.
6. Обновить CLI contract, legacy traceability и host-contract fixtures.

Rollback новой реализации восстанавливает предыдущие document bytes и state из transaction journal; Chapter UUID и source records не меняются.
