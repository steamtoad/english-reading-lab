## MODIFIED Requirements

### Requirement: ERL-SOURCE-004 — Target-home staging copyright excerpts are not public by default

`<ZETTELKASTEN_HOME>/.state/erl/staging/` MAY содержать context excerpts из source materials и MUST NOT публиковаться по умолчанию.

#### Scenario: Extraction writes source context to staging

- **GIVEN** extraction сохраняет context excerpt из source material
- **WHEN** staging artifacts создаются в `<ZETTELKASTEN_HOME>/.state/erl/staging/`
- **THEN** эти artifacts SHALL рассматриваться как local non-public data
- **AND** они SHALL NOT публиковаться по умолчанию
- **AND** ERL repository SHALL NOT использоваться как staging destination

### Requirement: ERL-SOURCE-005 — Target-home persistent work state excludes full copyrighted text

`<ZETTELKASTEN_HOME>/.state/erl/works/` MUST хранить ERL identities, mappings, hashes, UUID relationships, sequence/lifecycle data и policy metadata, но MUST NOT использоваться для хранения полных копий защищённого исходного текста.

#### Scenario: Persistent work state is written

- **WHEN** ERL записывает persistent data в `<ZETTELKASTEN_HOME>/.state/erl/works/`
- **THEN** state MAY содержать identities, mappings, hashes, UUID relationships, sequence/lifecycle data и policy metadata
- **BUT** state SHALL NOT содержать полную копию copyrighted source text
- **AND** ERL repository SHALL NOT использоваться как persistent work-state destination
