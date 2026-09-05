## ADDED Requirements

### Requirement: ERL-OPS-002 — Retention cannot remove durable or unresolved data

Documented cleanup policy MUST исключать works/notes и unresolved journal/backup из disposable runtime cleanup. Compact committed manifest/result MUST сохраняться. Удаление допустимого staging/cache/completed backup MUST иметь явную область и не разрушать заявленный resume/recovery path.

#### Scenario: Cleanup runs with a pending transaction

- **GIVEN** state содержит cache, works и unresolved backups
- **WHEN** оператор планирует runtime cleanup
- **THEN** plan SHALL исключить works и unresolved artifacts
- **AND** completed audit SHALL сохраниться

#### Scenario: Staging for an incomplete batch would be removed

- **GIVEN** partial receipt требует staging для продолжения
- **WHEN** cleanup выбирает этот input
- **THEN** он SHALL выдать dependency/blocker и не заявлять сохранённый resume
