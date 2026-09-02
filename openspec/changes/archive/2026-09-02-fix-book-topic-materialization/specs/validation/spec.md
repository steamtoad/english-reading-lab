## MODIFIED Requirements

### Requirement: ERL-CHECK-021 — Book Topic follows host Topic presentation contract

Каждый retained или active Book generation UUID MUST разрешаться в существующую canonical Topic, чья видимая presentation идентифицирует конкретную книгу из logical work state.

Book Topic MUST содержать host-compatible `:key-topic:`, не используемый как `WORK_ID`, и MUST удовлетворять canonical host Topic presentation contract. Topic, представленная только thematic key вместо title книги, MUST диагностироваться как неверная Book Topic presentation.

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
