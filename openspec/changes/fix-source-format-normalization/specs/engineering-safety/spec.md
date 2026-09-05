## ADDED Requirements

### Requirement: ERL-FORMAT-003 — Parser compatibility is tested per supported platform

Каждая заявленная поддерживаемая ОС MUST проходить один и тот же source fixture corpus с ожидаемым текстом и порядком. Отсутствующий converter MUST давать explicit diagnostic, а не незаметный regex fallback с другой семантикой.

#### Scenario: macOS and Linux shared contract is certified

- **GIVEN** одинаковый fixture corpus запускается в заявленных средах
- **WHEN** сравниваются outputs parser
- **THEN** text и Chapter order SHALL совпасть по normalized contract
- **AND** непроверенная среда SHALL не маркироваться supported
