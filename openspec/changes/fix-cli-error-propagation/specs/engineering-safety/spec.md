## ADDED Requirements

### Requirement: ERL-CLI-001 — Prerequisite failures stop the public command

Ошибка root resolver, обязательного tools/IO или JSON pipeline MUST прервать зависимую работу и вернуть ненулевой exit установленного класса. Текст ошибки MUST NOT использоваться как path, UUID, JSON data или успешный plan.

#### Scenario: Missing Vault produces one failure

- **GIVEN** указан несуществующий --vault и валидный explicit host
- **WHEN** book-ingest выполняет dry-run или apply
- **THEN** ответ SHALL быть NOT_FOUND с exit 20
- **AND** work_state_path и side effects SHALL отсутствовать

#### Scenario: Serializer or dependency fails

- **GIVEN** test double jq/shasum завершается ошибкой либо команда отсутствует
- **WHEN** runtime строит результат или fingerprint
- **THEN** команда SHALL вернуть ненулевой exit и error diagnostic
- **AND** OK с пустым data SHALL не возвращаться

### Requirement: ERL-CLI-002 — JSON output is deterministic on every exit path

При наличии --json public CLI MUST выдавать в stdout ровно один JSON envelope независимо от порядка options, включая usage errors. Successful envelope MUST иметь все обязательные поля data своего command. stderr MAY содержать диагностику, но MUST NOT быть единственным признаком failure.

#### Scenario: JSON option follows a bad option

- **GIVEN** arguments содержат неизвестный option до --json
- **WHEN** CLI обрабатывает usage error
- **THEN** stdout SHALL содержать один parseable envelope и exit 2

#### Scenario: Required success fields are missing

- **GIVEN** внутренний helper не вернул обязательное data
- **WHEN** команда готовит status ok
- **THEN** команда SHALL отклонить такой результат как failure

### Requirement: ERL-CLI-003 — Partial mutations are reported accurately

При failure после частичных commit ответ MUST содержать scope, committed subset, recovery/resume action и truthful changed. Если rollback вернул прежние domain bytes, changed SHALL быть false; диагностический journal сам по себе MUST NOT выдавать незавершённую domain mutation за успешную.

#### Scenario: Batch stops after its first committed Candidate

- **GIVEN** первый Candidate committed, второй завершился ошибкой
- **WHEN** batch возвращает результат
- **THEN** ответ SHALL быть nonzero с changed=true и первым receipt
- **AND** повтор SHALL быть направлен на safe resume без дублирования

#### Scenario: Rollback completed without domain changes

- **GIVEN** операция откатила все собственные изменения
- **WHEN** CLI сообщает failure
- **THEN** ответ SHALL иметь changed=false и указание завершённого rollback
