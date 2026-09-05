## ADDED Requirements

### Requirement: ERL-EXPORT-002 — Export failures and temporary artifacts are bounded

Exporter MUST явно диагностировать превышение объявленного resource limit или failure временного/выходного stream. Временный full-text artifact MUST NOT попадать в works, committed logs или public distribution и MUST очищаться после штатного завершения и handled failure.

#### Scenario: Temporary IO fails

- **GIVEN** временный output недоступен либо serialization failure инъецирован
- **WHEN** export запускается
- **THEN** команда SHALL вернуть IO_ERROR или соответствующий nonzero
- **AND** ни успешного envelope, ни persistent full text SHALL не остаться
