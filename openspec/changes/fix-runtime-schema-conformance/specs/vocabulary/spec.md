## ADDED Requirements

### Requirement: ERL-IDENTITY-001 — Lexical normalization is explicit and collision-safe

Canonical lexical tuple normalization MUST быть документирована и одинакова для staging/lookup/check: surrounding whitespace удаляется, внутренние whitespace схлопываются, case normalization и lexical_type rules фиксируются. Разные tuple MUST NOT совпадать из-за delimiter encoding. Изменение существующего key MUST требовать versioned migration с collision preview.

#### Scenario: Whitespace variants deduplicate

- **GIVEN** две candidates отличаются только допустимыми case/whitespace вариантами одной lemma/POS/type
- **WHEN** active lookup сравнивает их
- **THEN** они SHALL разрешаться в одну canonical identity

#### Scenario: Legacy key would merge records

- **GIVEN** новая normalization обнаруживает две старые active Vocabulary под одним tuple
- **WHEN** запускается validation или migration dry-run
- **THEN** система SHALL показать collision и исходные UUID
- **AND** никакого automatic merge или rename SHALL не происходить
