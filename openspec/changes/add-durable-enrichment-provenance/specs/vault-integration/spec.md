## ADDED Requirements

### Requirement: ERL-ENRICH-003 — Enrichment backfill is explicit and preserves unknowns

Backfill старых карточек MUST поддерживать reviewed dry-run/apply, preserve user edits и неизвестные значения. Отсутствующие estimates/provenance MUST NOT выдумываться или представляться как verified facts; UUID и canonical links MUST сохраняться.

#### Scenario: Legacy card has no CEFR provenance

- **GIVEN** старая карточка не содержит исходного enrichment
- **WHEN** repair готовит backfill
- **THEN** plan SHALL явно показать unknown/missing и требуемый input
- **AND** автоматически сочинённой provenance SHALL не быть
