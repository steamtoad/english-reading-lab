## Context

`fix-chapter-memo-chain` определяет независимую linear Memo Chain для каждой Chapter, а persistent generation sequence продолжает order через главы. После завершения Chapter chain её tail не имеет document-level перехода к следующей Chapter Note, хотя next Chapter UUID и adjacency детерминированно доступны из source state.

Все Chapter Notes создаются при Book ingest, поэтому next Chapter target существует до vocabulary ingestion. Handoff можно materialize при завершении Chapter batch без создания новых Vault entities.

## Goals / Non-Goals

**Goals:**

- обеспечить навигацию от tail Memo к следующей Chapter Note и обратно;
- использовать exact source adjacency, а не filesystem или title order;
- сохранить независимость Memo Chains разных Chapters;
- обеспечить idempotency, rollback, recovery и read-only validation.

**Non-Goals:**

- связывать tail Memo напрямую с первой Memo следующей Chapter;
- создавать handoff для terminal Chapter или Chapter без Memo nodes;
- менять `:key-topic:`, Chapter identity или persistent sequence schema;
- вызывать Classic workflow или изменять host core.

## Decisions

### Handoff targets the Chapter Note

Tail Memo получает section `== Reading handoff` с `Следующая глава`; next Chapter Note получает reciprocal section entry `Последнее memo предыдущей главы`. Первая Memo следующей Chapter не получает predecessor из предыдущей chain. Так выполняется требование cross-link с главой, не нарушая `ERL-SEQ-009` о раздельных chains.

### Source state defines adjacency

Next Chapter разрешается только внутри generation source по минимальному большему `source_order` того же `SOURCE_ID`. Title, filename и order обработки ingestion не используются. Отсутствие следующего record означает terminal Chapter.

### Handoff is a batch-finalization operation

Per-Candidate commit ещё не знает, останется ли current Memo tail. Handoff создаётся после всех Candidate receipts и до публикации successful Chapter-level result. Для empty Candidate batch handoff отсутствует.

### Two-document mutation is journaled

До mutation сохраняются hashes/backups tail Memo и next Chapter Note. Затем обе links записываются, выполняется scoped validation и фиксируется batch-finalization result. Failure восстанавливает оба документа; crash оставляет recovery journal. Retry сравнивает ожидаемую reciprocal pair и не дублирует её.

### Existing chains require explicit reconstruction

Legacy migration вычисляет tails из valid Chapter-local chains и next Chapters из source state. Dry-run показывает exact pairs. Conflicting existing `Reading handoff` content блокирует apply; пользовательские sections не перезаписываются молча.

## Risks / Trade-offs

- [Chapter ingestion выполняется не по source order] → existing source-order guard остаётся обязательным; handoff всё равно определяется source state, а не execution time.
- [Tail меняется после re-extraction] → old handoff считается stale и требует transactionally replace/migration после определения нового completed tail.
- [Next Chapter не содержит Vocabulary] → reciprocal Chapter link всё равно valid; она ведёт к последнему Memo предыдущей главы.
- [Crash между двумя document writes] → journal backups обоих targets обеспечивают rollback/recovery.

## Migration Plan

1. Создать primary regression test `tests/erl-chapter-chain-handoff.zsh` для normal, terminal, empty и retry cases.
2. Добавить deterministic next-Chapter resolution по `SOURCE_ID` и `source_order`.
3. Реализовать batch-finalization transaction для tail и next Chapter Note.
4. Расширить recovery и fault-injection fixtures.
5. Расширить `erl-check` согласно `ERL-CHECK-029`.
6. Реализовать explicit legacy handoff migration/rebuild с dry-run/apply/conflict detection.
7. Обновить CLI contract и legacy traceability.

Rollback восстанавливает pre-finalization bytes обоих documents. Memo Chain, Chapter UUID, Candidate receipts и generation sequence не изменяются.
