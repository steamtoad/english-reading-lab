## ADDED Requirements

### Requirement: ERL-BATCH-001 — Empty extraction completes without synthetic documents

Batch apply с candidates=[] MUST сохранить completed receipt и вернуть успешный результат без создания Vocabulary/Occurrence и изменения sequence. Повтор того же EXTRACTION_ID MUST быть идемпотентным.

#### Scenario: A chapter contains no selected lexical items

- **GIVEN** staging содержит валидный пустой batch
- **WHEN** выполняются dry-run, apply и повтор apply
- **THEN** первый apply SHALL завершиться с completed receipt
- **AND** повтор SHALL вернуть ALREADY_INGESTED и changed=false
- **AND** sequence и document count SHALL не увеличиться

### Requirement: ERL-BATCH-003 — Retry plans count only remaining work

Dry-run и result при partial resume MUST различать already-completed и new Candidates, показывать фактический диапазон новых ordinals и counts текущего invocation. Successful resume MUST NOT создавать duplicate documents или менять завершённые receipt entries.

#### Scenario: Second Candidate failed after first commit

- **GIVEN** batch имеет completed Candidate 1 и незавершённый Candidate 2
- **WHEN** пользователь выполняет новый dry-run и apply
- **THEN** план SHALL учитывать Candidate 1 как уже выполненный
- **AND** создан SHALL быть только недостающий документ, а report SHALL отражать новые counts
