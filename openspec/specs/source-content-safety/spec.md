# source-content-safety Specification

## Purpose

Определить границы хранения и публикации исходных книг и производных данных English Reading Lab, чтобы пользовательские source materials и потенциально защищённые copyright excerpts не попадали в публичный plugin repository.

## Requirements

### Requirement: ERL-SOURCE-001 — Source books are user-provided local artifacts

Source books MUST рассматриваться как локально предоставленные пользователем artifacts и MUST NOT требоваться как часть публичного ERL plugin repository.

#### Scenario: ERL processes a user-provided book

- **GIVEN** пользователь предоставляет source book для обработки ERL
- **WHEN** ERL использует этот source artifact
- **THEN** source book SHALL оставаться пользовательским локальным input
- **AND** публичный ERL plugin repository SHALL быть работоспособен без включения этого source artifact

### Requirement: ERL-SOURCE-002 — Source books directory excluded from public Git history

Каталог `books/` MUST быть исключён из публичного Git history ERL repository.

#### Scenario: Repository files are prepared for commit

- **GIVEN** source books находятся в `books/`
- **WHEN** пользователь или automation подготавливает изменения ERL repository к commit
- **THEN** содержимое `books/` SHALL NOT включаться в публичный Git history

### Requirement: ERL-SOURCE-003 — Copyrighted book copies are not committed

ERL repository MUST NOT содержать committed copies copyrighted source books в форматах EPUB, PDF, MOBI, AZW, AZW3, TXT или эквивалентных source formats.

#### Scenario: Copyrighted source artifact exists locally

- **GIVEN** пользовательский copyrighted source artifact существует в локальном ERL workspace
- **WHEN** repository changes подготавливаются к публикации
- **THEN** копия source artifact SHALL NOT быть добавлена в публичный Git repository

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
