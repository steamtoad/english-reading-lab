## ADDED Requirements

### Requirement: ERL-CHECK-027 — Chapter–Book Topic binding is complete and reciprocal

`erl-check` MUST read-only проверять для каждой Chapter Note active generation:

- точное совпадение Chapter `:key-topic:` и Book Topic `:key-topic:`;
- ровно одну canonical Chapter→active Book Topic link;
- ровно одну reciprocal Book Topic→Chapter link;
- отсутствие duplicate links;
- source-order Topic→Chapter links;
- отсутствие второй active Book Topic attachment Chapter Note.

#### Scenario: Complete Chapter–Topic binding is validated

- **GIVEN** Chapter зарегистрирована для active Book generation
- **WHEN** ERL выполняет validation
- **THEN** Chapter `:key-topic:` SHALL совпадать с Book Topic `:key-topic:`
- **AND** Chapter→Topic и Topic→Chapter links SHALL существовать и быть взаимными
- **AND** каждая сторона SHALL содержать ровно одну applicable link

#### Scenario: Chapter–Topic binding is incomplete or conflicting

- **GIVEN** Chapter относится к active Book generation
- **WHEN** отсутствует `:key-topic:`, key values различаются, одна сторона link отсутствует, link дублируется, Topic links нарушают source order или Chapter указывает на две active Book Topics
- **THEN** `erl-check` SHALL вернуть validation error с причиной нарушения
- **AND** SHALL указать Book Topic UUID и Chapter UUID
- **AND** SHALL NOT изменять Topic, Chapter Note или persistent work state

