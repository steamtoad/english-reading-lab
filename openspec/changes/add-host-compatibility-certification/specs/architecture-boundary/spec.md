## ADDED Requirements

### Requirement: ERL-HOST-001 — Host compatibility is an explicit observable contract

ERL MUST публиковать consumed host ABI и проверять его в explicit disposable target: argument/environment contract, stdout/exit, canonical metadata, UUID v1 и placement. Несовместимый host MUST диагностироваться до production mutation; test double MUST NOT считаться production certification.

#### Scenario: Real configured host is certified in a scratch target

- **GIVEN** оператор указал внешний host и disposable target
- **WHEN** запускается compatibility suite
- **THEN** все constructors SHALL создать valid canonical documents в scratch notes
- **AND** host source и пользовательский Vault SHALL сохранить hash inventory

#### Scenario: Host stdout or metadata violates the ABI

- **GIVEN** constructor возвращает extra stdout, wrong UUID version или missing required attribute
- **WHEN** compatibility check выполняется
- **THEN** profile SHALL быть incompatible, а не поддержанным
