## Why

Дельта `fix-chapter-memo-chain` материализует отдельную Memo Chain внутри каждой Chapter, но не задаёт навигационный переход от её последнего Memo к следующей Chapter Note. В результате цепочка заканчивается тупиком, хотя source order книги уже известен ERL.

## What Changes

- Обязать tail Memo завершённой Chapter Memo Chain иметь canonical link `Следующая глава` на следующую Chapter Note в source order.
- Обязать следующую Chapter Note иметь reciprocal canonical link `Последнее memo предыдущей главы` на tail Memo предыдущей Chapter.
- Не создавать handoff для последней Chapter source и для Chapter без Memo Chain.
- Создавать handoff только после завершения Chapter-level ingestion, когда final tail определён.
- Включить обе стороны handoff и batch completion в recoverable transaction.
- Добавить read-only validation уникальности, взаимности, source-order adjacency и отсутствия stale handoff.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `source-chapters`: добавляется reciprocal navigation между tail Memo текущей Chapter и следующей Chapter Note.
- `reading-sequence`: добавляется межглавный handoff после завершённой Chapter-local Memo Chain без слияния самих chains.
- `validation`: добавляется read-only проверка Chapter chain handoff.

## Impact

Будущая реализация затронет ERL-owned `erl-chapter-vocabulary-ingest`, `erl-check`, transaction recovery, CLI contract, legacy traceability и tests. Persistent work-state schema, Chapter UUID и Memo identity не меняются. Change зависит от `fix-chapter-topic-binding` и `fix-chapter-memo-chain`.

Для существующих completed Chapter chains потребуется explicit migration/rebuild с dry-run, conflict detection, journal, rollback и recovery. Пользовательский Vault не изменяется автоматически. Destructive operations отсутствуют. Host-contract gap отсутствует: используются canonical links в существующих Note и Memo; host core не меняется.
