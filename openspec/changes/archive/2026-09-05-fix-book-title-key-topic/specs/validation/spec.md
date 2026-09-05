## MODIFIED Requirements

### Requirement: ERL-CHECK-021 — Book Topic follows host Topic presentation and title-key contract

`erl-check` MUST read-only проверять, что Book Topic удовлетворяет canonical host Topic presentation contract и что её `:key-topic:` точно совпадает с canonical visible title logical work.

#### Scenario: Book Topic presentation is validated

- **GIVEN** ERL document имеет Book Topic role
- **WHEN** ERL выполняет validation
- **THEN** Topic SHALL существовать в canonical Vault namespace
- **AND** Topic SHALL содержать host-compatible `:key-topic:`
- **AND** `:key-topic:` SHALL NOT использоваться как `WORK_ID`
- **AND** видимый title Topic SHALL идентифицировать книгу по canonical title logical work
- **AND** Topic SHALL удовлетворять canonical host Topic presentation contract

#### Scenario: Registered generation has no valid Book Topic

- **GIVEN** work manifest или generation state содержит Book generation UUID
- **WHEN** соответствующий document отсутствует, имеет type не `topic` или его title не представляет книгу
- **THEN** `erl-check` SHALL вернуть validation error для этой generation
- **AND** diagnostic SHALL различать missing Topic, wrong canonical type и wrong Book presentation
- **AND** `erl-check` SHALL NOT создавать или переписывать Topic автоматически

#### Scenario: Book Topic key differs from title

- **GIVEN** Book Topic имеет title `Friday` и `:key-topic: English Reading`
- **WHEN** выполняется validation
- **THEN** checker SHALL вернуть deterministic validation error
- **AND** error SHALL содержать Book Topic UUID, expected `Friday` и actual `English Reading`
- **AND** checker SHALL NOT изменять документ или state

### Requirement: ERL-CHECK-027 — Chapter–Book Topic binding includes canonical book-title key

`erl-check` MUST read-only проверять для каждой Chapter Note active generation:

- exact equality canonical Book title, Book Topic `:key-topic:` и Chapter `:key-topic:`;
- ровно одну canonical Chapter→active Book Topic link;
- ровно одну reciprocal Book Topic→Chapter link;
- отсутствие duplicate links и второй active attachment;
- source-order Topic→Chapter links.

#### Scenario: Complete Chapter–Topic binding is validated

- **GIVEN** active Book Topic title/key равны `Friday`
- **WHEN** ERL проверяет зарегистрированную Chapter
- **THEN** Chapter `:key-topic:` SHALL быть `Friday`
- **AND** reciprocal Chapter/Topic links SHALL быть полными и уникальными

#### Scenario: Chapter retains the old umbrella key

- **GIVEN** Chapter относится к active Book `Friday`
- **WHEN** Chapter `:key-topic:` равно `English Reading`
- **THEN** checker SHALL вернуть validation error
- **AND** error SHALL указать Book Topic UUID, Chapter UUID, expected и actual key
- **AND** checker SHALL NOT изменять Vault documents или persistent state

#### Scenario: Chapter–Topic binding is incomplete or conflicting

- **GIVEN** Chapter относится к active Book generation
- **WHEN** отсутствует `:key-topic:`, key values различаются, одна сторона link отсутствует, link дублируется, Topic links нарушают source order или Chapter указывает на две active Book Topics
- **THEN** `erl-check` SHALL вернуть validation error с причиной нарушения
- **AND** SHALL указать Book Topic UUID и Chapter UUID
- **AND** SHALL NOT изменять Topic, Chapter Note или persistent work state
