## ADDED Requirements

### Requirement: ERL-ENRICH-001 — Useful enrichment survives staging cleanup

После успешной ingestion смысловые поля accepted enrichment и происхождение оценок, необходимые пользователю, MUST сохраняться в readable canonical Memo content либо определённом persistent contract. Очистка staging/cache MUST NOT удалять единственную копию sense/usage/relations/confidence/provenance; ephemeral orchestration data MAY удаляться.

#### Scenario: Rich Candidate is ingested and staging removed

- **GIVEN** accepted Candidate содержит sense_gloss, labels, collocations и CEFR provenance
- **WHEN** ingestion committed, затем staging/cache удалены
- **THEN** сохранённая карточка SHALL содержать эти meaning-bearing данные
- **AND** erl-check SHALL оставаться successful без staging
