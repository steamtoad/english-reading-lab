## ADDED Requirements

### Requirement: ERL-ENRICH-002 — Occurrence retains its own sense and uncertainty

Если lexical identity уже имеет active Vocabulary, accepted encounter-specific sense/context и uncertainty MUST сохраняться в Occurrence без silent overwrite canonical Vocabulary. Candidate confidence и CEFR confidence MUST оставаться различимыми.

#### Scenario: Same lexical identity appears in a different sense

- **GIVEN** Vocabulary уже существует, новый Candidate имеет иной contextual sense
- **WHEN** ingestion создаёт Occurrence
- **THEN** новый sense/context/provenance SHALL читаться из Occurrence
- **AND** исходная Vocabulary SHALL не перезаписываться
