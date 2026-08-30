# vocabulary-extraction Specification

## Purpose

Определить Chapter-level vocabulary extraction и Candidate staging в English Reading Lab: границу semantic extraction, extraction batch identity, структуру Vocabulary Candidate, source order, retry semantics и защиту от повторного ingestion одного EXTRACTION_ID.

## Requirements

### Requirement: ERL-EXT-001 — Canonical Chapter vocabulary extraction skill

Основным vocabulary extraction skill MUST быть `erl-chapter-vocabulary-extract`.

#### Scenario: Vocabulary extraction is requested for a Chapter

- **WHEN** ERL выполняет semantic vocabulary extraction для Chapter
- **THEN** canonical skill operation SHALL быть `erl-chapter-vocabulary-extract`

### Requirement: ERL-EXT-002 — Extraction is scoped to one Chapter and active generation

Extraction MUST выполняться для одной Chapter внутри конкретной active Book generation.

#### Scenario: Extraction scope is resolved

- **GIVEN** logical work имеет active Book generation
- **AND** Chapter имеет durable canonical UUID
- **WHEN** запускается vocabulary extraction
- **THEN** extraction SHALL быть привязана к одной Chapter
- **AND** SHALL быть привязана к конкретной active Book generation

### Requirement: ERL-EXT-003 — Extraction follows source order

Extraction MUST обрабатывать source content в source order.

#### Scenario: Chapter content contains multiple lexical occurrences

- **WHEN** extraction проходит Chapter source content
- **THEN** occurrences SHALL анализироваться в source order
- **AND** extraction ordering SHALL сохранять порядок исходного текста

### Requirement: ERL-EXT-004 — Extraction policy is generation-specific

Начальная extraction policy MUST быть ориентирована на C1/C2 lexical items.

ERL MUST допускать изменение extraction policy между semantic generations.

#### Scenario: Initial extraction policy is used

- **WHEN** ERL применяет initial extraction policy
- **THEN** policy SHALL ориентироваться на C1/C2 lexical items

#### Scenario: A later generation uses another policy

- **GIVEN** предыдущая generation использовала определённую extraction policy
- **WHEN** создаётся новая semantic generation
- **THEN** новая generation MAY использовать другую extraction policy
- **AND** policy identity SHALL относиться к соответствующей generation

### Requirement: ERL-EXT-005 — Extraction does not create Vault documents

Vocabulary extraction skill MUST NOT создавать Vault documents, использовать canonical object constructors или вызывать `zcreate`.

#### Scenario: Extraction produces lexical results

- **WHEN** `erl-chapter-vocabulary-extract` завершает semantic extraction
- **THEN** результат SHALL оставаться staging data
- **AND** skill SHALL NOT создавать Topic, Note или Memo
- **AND** SHALL NOT вызывать canonical object constructors
- **AND** SHALL NOT вызывать `zcreate`

### Requirement: ERL-EXT-006 — Extraction output is staged

Extraction output MUST храниться в `.state/erl/staging/`.

#### Scenario: Extraction completes successfully

- **WHEN** vocabulary extraction создаёт Candidate output
- **THEN** output SHALL быть записан в ERL staging namespace
- **AND** SHALL NOT считаться persistent Vault document или persistent work-state record

### Requirement: ERL-CAND-001 — Vocabulary Candidate is a staging object

Vocabulary Candidate MUST быть staging object и MUST NOT быть Vault document.

#### Scenario: Candidate is created

- **WHEN** extraction выбирает lexical item
- **THEN** Candidate SHALL существовать как staging data
- **AND** SHALL NOT получать canonical Vault UUID как persistent document identity

### Requirement: ERL-CAND-002 — Extraction batch has explicit identity and scope

Каждый extraction batch MUST содержать как минимум:

- `EXTRACTION_ID`;
- Book generation UUID;
- Chapter UUID;
- processing policy identity или fingerprint;
- source identity.

#### Scenario: Extraction batch is staged

- **WHEN** ERL сохраняет completed extraction batch
- **THEN** batch SHALL содержать `EXTRACTION_ID`
- **AND** SHALL содержать Book generation UUID
- **AND** SHALL содержать Chapter UUID
- **AND** SHALL содержать processing policy identity или fingerprint
- **AND** SHALL содержать source identity

### Requirement: ERL-CAND-003 — Candidate has deterministic lexical fields

Каждый Candidate MUST содержать как минимум:

- candidate ordinal;
- surface form;
- lemma;
- POS;
- lexical type;
- estimated CEFR;
- confidence;
- first relevant occurrence;
- context.

#### Scenario: Candidate is staged

- **WHEN** extraction сохраняет Vocabulary Candidate
- **THEN** Candidate SHALL содержать все обязательные lexical и ordering fields
- **AND** downstream ingestion SHALL иметь возможность прочитать их без повторной semantic extraction

### Requirement: ERL-CAND-004 — Candidate represents first relevant occurrence

Default extraction policy MUST представлять один выбранный lexical item одним Candidate на его первом relevant occurrence внутри текущей Chapter.

#### Scenario: Lexical item first becomes relevant

- **WHEN** extraction впервые встречает relevant occurrence выбранного lexical item в текущей Chapter
- **THEN** Candidate SHALL ссылаться на это первое relevant occurrence
- **AND** context SHALL соответствовать этой встрече

### Requirement: ERL-CAND-005 — Repeated lexical occurrences do not create duplicate Candidates by default

Default extraction policy MUST NOT создавать дополнительные Candidates для последующих occurrences того же lexical item в той же Chapter.

#### Scenario: Lexical item occurs again in the same Chapter

- **GIVEN** Candidate для lexical item уже создан на его первом relevant occurrence
- **WHEN** тот же lexical item встречается позже в текущей Chapter
- **THEN** новый Candidate SHALL NOT создаваться только из-за повторной встречи

### Requirement: ERL-CAND-006 — Candidate ordinal is extraction order, not reading sequence

Candidate ordinal MUST отражать source/extraction order и MUST NOT использоваться как persistent reading sequence ordinal.

#### Scenario: Candidate receives an ordinal

- **WHEN** Candidate создаётся во время extraction
- **THEN** ordinal SHALL отражать его положение в extraction/source order
- **AND** ordinal SHALL NOT определять persistent reading sequence position

### Requirement: ERL-CAND-007 — Repeated extraction is recognized as retry or re-extraction

Повторный extraction того же `Book generation UUID × Chapter UUID` MUST распознаваться как retry или re-extraction существующего processing scope.

#### Scenario: Extraction is repeated for the same scope

- **GIVEN** extraction ранее выполнялся для данной Book generation и Chapter
- **WHEN** extraction запускается повторно для той же пары
- **THEN** ERL SHALL распознать operation как retry/re-extraction
- **AND** SHALL NOT трактовать её как независимую новую Chapter identity

### Requirement: ERL-CAND-008 — EXTRACTION_ID cannot be ingested twice

Один `EXTRACTION_ID` MUST NOT быть ingested более одного раза.

Persistent work state MUST хранить достаточный ingestion receipt для обнаружения повторной ingestion.

#### Scenario: Completed extraction is ingested again

- **GIVEN** `EXTRACTION_ID` уже имеет completed ingestion receipt
- **WHEN** ingestion повторно получает тот же `EXTRACTION_ID`
- **THEN** ERL SHALL обнаружить повторную ingestion
- **AND** SHALL NOT молча создать второй набор persistent documents

### Requirement: ERL-CAND-009 — Material policy changes require a new semantic generation

После ingestion материальное изменение card, extraction или lexical policy MUST создавать новую semantic generation через Reduce вместо молчаливого переписывания существующей generation.

#### Scenario: Processing policy changes materially after ingestion

- **GIVEN** generation уже содержит ingested Vocabulary или Occurrence data
- **WHEN** card, extraction или lexical policy материально изменяется
- **THEN** существующая generation SHALL NOT переписываться молча
- **AND** изменение SHALL выполняться через новую semantic generation после применимого Reduce lifecycle
