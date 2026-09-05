## ADDED Requirements

### Requirement: ERL-SCHEMA-001 — Policy validation conforms to its published schema

Policy acceptance MUST совпадать с published extraction-policy schema по required/extra fields, types, enum, array uniqueness и enrichment structure, а также проверять canonical hash. Invalid policy MUST отклоняться до mutation.

#### Scenario: Well-hashed invalid policy is rejected

- **GIVEN** policy имеет threshold BOGUS, numeric lexical_types и отсутствующие required fields, но верный hash
- **WHEN** book-ingest или exporter/checker проверяет policy
- **THEN** validation SHALL завершиться explicit failure, а не OK

#### Scenario: Independent schema fixtures agree

- **GIVEN** набор содержит valid policy и по одному нарушению каждого schema constraint
- **WHEN** runtime и независимый contract test проверяют набор
- **THEN** accepted/rejected sets SHALL совпадать

### Requirement: ERL-SCHEMA-002 — Candidate and state validation cover the declared contract

Public input boundaries и erl-check MUST проверять опубликованные version/type/required/reference/receipt constraints для своего scope. Unknown schema versions MUST не приниматься как текущие; read-only inspection MAY давать migration diagnostic, но mutation MUST блокироваться без supported migration.

#### Scenario: Malformed persistent receipt is found

- **GIVEN** receipt содержит duplicate candidate ordinal, missing document или неподдержанную version
- **WHEN** erl-check проверяет owning generation
- **THEN** checker SHALL выдать diagnostic с path и rule identifier

#### Scenario: Valid state is independent of staging

- **GIVEN** canonical generation и receipts полностью валидны, staging/cache удалены
- **WHEN** erl-check проверяет state
- **THEN** проверка SHALL пройти без восстановления истины из staging

### Requirement: ERL-SCHEMA-003 — Vault and ERL identifiers retain their distinct versions

Canonical document identifiers MUST соответствовать host UUID v1; WORK_ID/SOURCE_ID/EXTRACTION_ID/TXID MUST быть lowercase UUID v4. Нарушение версии MUST диагностироваться без автоматического переименования или исправления ссылок.

#### Scenario: Constructor returns a version-four document identifier

- **GIVEN** host double создаёт документ с UUID v4
- **WHEN** ingest проверяет constructor result
- **THEN** mutation SHALL не быть признана успешной
- **AND** исправление SHALL не выполнять silent rename существующих документов
