## ADDED Requirements

### Requirement: ERL-ASCIIDOC-003 — Header and content validation honor the supported host grammar

Metadata parser MUST отличать поддерживаемый host header от body и не трактовать body literals как deprecation/identity attributes. Content validation MUST иметь positive corpus допустимого prose и negative corpus malformed cards; совпадение с marker-like текстом само по себе MUST NOT заменять проверку структуры.

#### Scenario: Body contains an attribute-looking quotation

- **GIVEN** валидная карточка цитирует :deprecated: в body
- **WHEN** erl-check определяет active status
- **THEN** карточка SHALL оставаться active по настоящему header

#### Scenario: Supported header includes a blank line after title

- **GIVEN** host compatibility contract разрешает такой header
- **WHEN** parser читает metadata
- **THEN** обязательные attributes SHALL распознаваться без ложного отсутствия
