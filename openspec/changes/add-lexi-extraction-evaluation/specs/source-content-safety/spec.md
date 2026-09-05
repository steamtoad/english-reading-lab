## ADDED Requirements

### Requirement: ERL-EVAL-005 — Evaluation artifacts respect source and logging boundaries

Public evaluation artifacts MUST содержать только synthetic/redistributable inputs и разрешённые outputs; secrets и private book text MUST исключаться. Live deployment evidence MUST явно фиксировать применимые provider logging/retention settings и сохранять неизвестное как unknown вместо обещания отсутствия внешнего хранения.

#### Scenario: A private source is used in a local live run

- **GIVEN** оператор использует непубликуемую книгу
- **WHEN** harness сохраняет summary для release
- **THEN** public artifact SHALL содержать только разрешённые metadata/metrics
- **AND** полный текст и credentials SHALL не публиковаться
