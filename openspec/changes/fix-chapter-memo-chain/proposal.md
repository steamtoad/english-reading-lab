## Why

Текущий vocabulary ingestion записывает Chapter UUID и reading sequence только в persistent state, но созданные Vocabulary/Occurrence Memo не прикрепляются к Chapter Note через `:key-topic:`, не имеют взаимных Chapter links и не материализуют последовательность слов главы как Memo Chain. Из-за этого одна из основных связей ERL видна state tooling, но отсутствует в canonical Vault documents.

## What Changes

- Обязать каждое созданное Vocabulary или Occurrence Memo содержать `:key-topic:`, точно совпадающий с `:key-topic:` Chapter Note, где lexical encounter возник.
- Добавить reciprocal canonical links Chapter Note↔Vocabulary/Occurrence Memo.
- Материализовать отдельную линейную Memo Chain внутри каждой Chapter в Candidate/source order по семантике `zt-continue`.
- Определить первое Memo главы как head цепочки без predecessor; каждое последующее Memo получает `Предыдущее memo`, а предыдущее — `Следующее memo`.
- Различить persistent generation reading sequence и Chapter-local Vault Memo Chain, сохранив возможность восстановления и взаимной проверки.
- Сделать document creation, Chapter links, chain links, work-state membership и sequence update одной recoverable transaction.
- Добавить read-only validation attachment, key-topic inheritance, reciprocal links и chain integrity.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `vocabulary-ingestion`: добавляется обязательная materialization связей созданного Vocabulary/Occurrence Memo с Chapter Note и наследование `:key-topic:`.
- `reading-sequence`: добавляется Chapter-local Memo Chain как canonical Vault projection ordered sequence.
- `validation`: добавляется read-only проверка Chapter–Memo attachment и Memo Chain.

## Impact

Будущая реализация затронет ERL-owned `erl-vocabulary-ingest`, `erl-chapter-vocabulary-ingest`, `erl-check`, transaction recovery, host-contract fixtures, CLI contract, legacy traceability и tests. Persistent sequence schema и lexical identity не меняются. Дельта зависит от `fix-chapter-topic-binding`: Chapter Note должна уже иметь canonical `:key-topic:` и active Book Topic attachment.

Для существующих Vocabulary/Occurrence documents потребуется отдельная explicit migration с dry-run, conflict detection, journal, rollback и recovery; молчаливая правка пользовательского Vault запрещена. Destructive operations отсутствуют. Host-contract gap отсутствует: canonical Memo, `:key-topic:`, mutual links и Memo Chain labels уже определены host semantics `zt-continue`; ERL не вызывает Classic workflow и не патчит host core.
