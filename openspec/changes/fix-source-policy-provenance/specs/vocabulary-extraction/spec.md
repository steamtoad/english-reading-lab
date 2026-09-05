## ADDED Requirements

### Requirement: ERL-PROVENANCE-002 — Export supplies the complete staging source identity

Successful export MUST содержать source_identity с canonical source_id/source_fingerprint, generation, Chapter и полный validated policy. Extraction client MUST иметь достаточно данных для schema-valid staging без чтения works напрямую или угадывания fingerprint.

#### Scenario: Export feeds staging end to end

- **GIVEN** клиент знает только generation и Chapter
- **WHEN** он экспортирует главу и формирует Candidates
- **THEN** staging SHALL принять identity из export при неизменном state
- **AND** клиент SHALL не читать private state для недостающего fingerprint
