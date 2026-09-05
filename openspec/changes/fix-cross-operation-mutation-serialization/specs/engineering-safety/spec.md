## ADDED Requirements

### Requirement: ERL-CONCURRENCY-001 — Overlapping ERL writers are serializable

ERL writers, затрагивающие один target home и общие state/documents/root bindings, MUST давать результат, эквивалентный последовательному выполнению, либо явный conflict до mutation. Разные extraction и разные имена commands MUST NOT обходить эту гарантию.

#### Scenario: Concurrent extraction batches share a generation

- **GIVEN** два extraction одной generation добавляют nodes
- **WHEN** оба writers запускаются через управляемый barrier
- **THEN** результат SHALL иметь уникальные последовательные ordinals, полные receipts и согласованные links
- **AND** ни одна committed запись SHALL не потеряться

#### Scenario: Global lexical identity races across works

- **GIVEN** две works одновременно впервые ingest одинаковую lexical identity
- **WHEN** обе операции достигают dedup/commit
- **THEN** active canonical Vocabulary SHALL быть ровно одна либо один writer SHALL получить retryable conflict

#### Scenario: Reduce races with ingest or recovery

- **GIVEN** Reduce и ingest/recover затрагивают общий closure
- **WHEN** обе операции запускаются одновременно
- **THEN** они SHALL сериализоваться либо конфликтовать до пересекающейся записи

### Requirement: ERL-CONCURRENCY-002 — Mutation preconditions are revalidated under protection

Writer MUST заново проверить authoritative state, ownership, idempotency, source order и расчёт sequence непосредственно после получения защиты. Изменение подтверждённого Reduce plan MUST отклонять старый fingerprint; missing/pending transaction MUST NOT игнорироваться.

#### Scenario: State changes after dry-run

- **GIVEN** dry-run был построен до чужого commit
- **WHEN** apply получает защиту на изменённом state
- **THEN** устаревшие ordinals и dedup results SHALL не использоваться
- **AND** Reduce с прежним fingerprint SHALL быть отклонён

### Requirement: ERL-CONCURRENCY-003 — Mass mutation preserves local worktree changes

Каждая mass mutation MUST явно применить опубликованную Git/worktree policy к своему mutation set. Dirty targets MUST отклоняться до записи согласно policy; non-Git Vault MAY использоваться с теми же hash/conflict safeguards. Несвязанные пользовательские файлы MUST сохраняться.

#### Scenario: Dirty migration target is present

- **GIVEN** Git Vault содержит незакоммиченную правку target карточки
- **WHEN** запускается apply миграции или repair
- **THEN** операция SHALL вернуть blocked diagnostic с dirty target до mutation

#### Scenario: Non-Git target is supported

- **GIVEN** Vault не находится в Git, его state валиден
- **WHEN** выполняется обычная mutation
- **THEN** preflight SHALL явно сообщить not-applicable Git policy
- **AND** операция SHALL сохранять hash-based защиту внешних изменений
