## Context

ERL уже хранит ordered Vocabulary/Occurrence nodes в generation `sequence` с `chapter_uuid`, но documents не отражают эти отношения. Vocabulary/Occurrence создаются canonical Memo constructor, после чего ERL дописывает lexical или occurrence sections; `:key-topic:`, Chapter links и Memo Chain отсутствуют.

Host `zt-continue` задаёт подходящую link semantics: новый Memo наследует `:key-topic:`, получает `Предыдущее memo`, а predecessor — `Следующее memo`. ERL не должен вызывать interactive Classic workflow, но может материализовать ту же canonical structure детерминированно.

Change зависит от `fix-chapter-topic-binding`, поскольку Chapter Note должна иметь валидный `:key-topic:` и active Book Topic attachment до vocabulary ingestion.

## Goals / Non-Goals

**Goals:**

- прикрепить каждый новый Vocabulary/Occurrence Memo к Chapter Note в Vault;
- наследовать Chapter `:key-topic:` без ERL-specific attributes;
- создать одну линейную Continue-style chain на Chapter;
- согласовать document graph с persistent reading sequence;
- обеспечить idempotency, rollback и recovery при multi-document mutation.

**Non-Goals:**

- делать Vocabulary book-local или создавать duplicate Vocabulary;
- соединять Memo Chain между разными Chapters;
- заменять persistent reading sequence links в documents;
- вызывать interactive `zt-continue` или source `.scripts/zettelkasten/`;
- менять host core, lexical identity или generation sequence schema.

## Decisions

### Attachment follows the encounter node

Новая Vocabulary прикрепляется к Chapter первого приобретения. При повторной встрече global Vocabulary не меняется; создаваемая Occurrence прикрепляется к текущей Chapter. Это сохраняет `ERL-VOC-007/008` и делает каждый reading-sequence node представителем конкретного encounter.

### Chapter Note is the reciprocal index

Каждый Memo получает секцию `== Chapter` с одной Chapter link. Chapter Note получает deterministic секцию `== Vocabulary` со ссылками на все nodes главы в Candidate/source order. Название `Vocabulary` охватывает обе роли sequence node; role остаётся в state и structural Memo contract.

### Chain is per Chapter, sequence is per generation

Generation sequence продолжает ordinals через границы Chapters согласно `ERL-SEQ-005`. Document Memo Chain фильтрует sequence по `chapter_uuid` и начинается заново в каждой Chapter. Это устраняет противоречие между глобальным reading order и требованием «первое Memo в главе начинает цепочку».

### Linear subset of zt-continue semantics

ERL использует точные labels `Предыдущее memo` и `Следующее memo`. Branch links `Ветка: ...` не допускаются, поскольку Candidate order детерминирован и Chapter chain должна иметь один tail.

### One Candidate commit mutates all affected artifacts atomically

До первой mutation journal сохраняет generation state, Chapter Note и predecessor Memo hashes/backups. Затем создаётся current Memo, обновляются current/predecessor/Chapter links, sequence, membership и receipt, после чего выполняется scoped validation. Failure восстанавливает все pre-operation bytes. Chapter batch остаётся resumable по completed receipts.

### Existing documents require explicit migration

Legacy migration строит expected chains из generation sequence, группируя nodes по Chapter и сохраняя order. Dry-run показывает все header/link mutations и conflicts. Existing user-owned `Chapter`, `Vocabulary` или chain sections, которые не совпадают с expected graph, блокируют apply до explicit resolution.

## Risks / Trade-offs

- [Один Vocabulary используется в нескольких книгах] → Vocabulary остаётся прикреплённой только к acquisition Chapter; остальные encounters получают свои Occurrence Memo.
- [Ручное редактирование chain создаёт branch] → `erl-check` диагностирует конфликт; ingestion не перезаписывает неизвестную topology молча.
- [Crash после изменения predecessor] → predecessor и Chapter backups создаются до mutation, recovery восстанавливает их вместе с state.
- [Chapter содержит много words] → Chapter `Vocabulary` section растёт линейно; она хранит только links, не карточки или source text.
- [Active sequence содержит legacy nodes без links] → checker сообщает migration-required diagnostics, а обычный ingest не смешивает silent repair с новым Candidate commit.

## Migration Plan

1. Создать primary regression test `tests/erl-chapter-memo-chain.zsh` для Vocabulary, Occurrence, attachment, single-node и multi-node chains.
2. Реализовать exact Chapter key inheritance и canonical attachment sections.
3. Расширить per-Candidate transaction journal на predecessor Memo и Chapter Note.
4. Материализовать linear chain по Chapter-filtered sequence и добавить scoped post-validation.
5. Расширить `erl-check` согласно `ERL-CHECK-028`.
6. Реализовать отдельную explicit legacy migration с dry-run/apply/conflict detection/recovery.
7. Обновить CLI contract, legacy traceability и host fixtures.

Rollback новой реализации восстанавливает document bytes и generation state из transaction journal. Existing Vocabulary identity, Chapter UUID и completed receipts предыдущих Candidates не меняются.
