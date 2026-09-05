## MODIFIED Requirements

### Requirement: ERL-CHAPTER-012 — Chapter Note inherits canonical book-title key-topic

Каждая Chapter Note, прикреплённая к active Book Topic generation, MUST содержать host-defined `:key-topic:` с точным значением canonical title книги. Оно MUST одновременно совпадать с visible title и `:key-topic:` active Book Topic.

Значение MUST NOT быть `WORK_ID`, Book Topic UUID, Chapter UUID или иным ERL-local foreign key.

#### Scenario: Chapter Note is attached during Book ingest

- **GIVEN** canonical title и `:key-topic:` Book Topic равны `Friday`
- **WHEN** ERL создаёт Chapter Note для active Book generation
- **THEN** Chapter Note SHALL получить `:key-topic: Friday`
- **AND** значение SHALL храниться как header attribute
- **AND** ERL SHALL NOT выводить его из UUID или persistent state identifier

#### Scenario: Chapter Note has an umbrella thematic key

- **GIVEN** Chapter Note зарегистрирована для active Book `Friday`
- **WHEN** её `:key-topic:` равно `English Reading`, отсутствует или отличается от canonical title
- **THEN** Chapter Note SHALL считаться неверно прикреплённой
- **AND** ingest/validation SHALL NOT считать Book–Chapter materialization успешно завершённой

#### Scenario: Chapter Note key-topic differs from active Book Topic

- **GIVEN** Chapter Note зарегистрирована для active Book generation
- **WHEN** её `:key-topic:` отсутствует или отличается от `:key-topic:` Book Topic
- **THEN** Chapter Note SHALL считаться неприкреплённой или неверно прикреплённой
- **AND** ingest SHALL NOT считать Book–Chapter materialization успешно завершённой

### Requirement: ERL-CHAPTER-014 — Durable Chapter is rebound to active Book title and Topic

Durable Chapter Note MUST иметь одну current attachment к active Book Topic generation соответствующего logical work.

При создании новой active generation ERL MUST transactionally заменить прежнюю active Book Topic link и MUST установить Chapter `:key-topic:` в exact canonical title новой active Book Topic. Historical membership MUST оставаться в persistent audit/state, а не представляться второй active attachment.

#### Scenario: Existing source Chapter enters a new generation

- **GIVEN** durable Chapter Note была прикреплена к предыдущей Book Topic generation
- **WHEN** ERL создаёт новую active generation того же logical work
- **THEN** Chapter UUID SHALL остаться прежним
- **AND** current Book link SHALL указывать на новую active Book Topic
- **AND** Chapter `:key-topic:` SHALL точно совпадать с canonical title и key новой Book Topic
- **AND** Chapter Note SHALL NOT сохранять вторую active Book Topic attachment
