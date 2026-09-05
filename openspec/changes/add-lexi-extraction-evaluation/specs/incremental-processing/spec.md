## ADDED Requirements

### Requirement: ERL-EVAL-002 — Segmented extraction preserves whole-chapter semantics

Если Chapter превышает model context budget, processing MUST использовать временные segments с детерминированными offsets/order и merge. Результат MUST быть единым Chapter-scoped batch без duplicate lexical identities, с first relevant occurrence и без Candidate quota; segment entities MUST NOT становиться Vault objects.

#### Scenario: Repeated item crosses segment overlap

- **GIVEN** lexical item встречается в overlap и позже в следующем segment
- **WHEN** segment outputs объединяются
- **THEN** в final batch SHALL быть одна Candidate на первое relevant occurrence
- **AND** source order SHALL сохраняться и permanent segment Notes SHALL не создаваться

#### Scenario: The last segment fails

- **GIVEN** ранние segments готовы, последний не завершён
- **WHEN** orchestrator формирует итог главы
- **THEN** полная Chapter completion SHALL не заявляться
- **AND** safe resume SHALL сохранять source/policy identity
