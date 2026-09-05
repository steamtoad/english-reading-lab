## ADDED Requirements

### Requirement: ERL-FORMAT-001 — Supported formats produce normalized prose

Для поддерживаемых EPUB/XHTML/HTML exporter MUST выдавать нормализованный читаемый текст, сохраняя Unicode, смысловые границы абзацев и порядок, без XML declaration, HTML tags и script/style content. TXT/Markdown single-file Chapter semantics MUST быть явно документированы.

#### Scenario: Minimal two-chapter EPUB is exported

- **GIVEN** fixture содержит XML declaration, XHTML namespace и два spine items
- **WHEN** книга импортируется и главы экспортируются
- **THEN** две Chapters SHALL следовать spine order
- **AND** content SHALL совпасть с expected prose без raw markup

#### Scenario: Entities and non-ASCII content are present

- **GIVEN** fixture содержит ampersand entity, nonbreaking space и Unicode
- **WHEN** parser извлекает текст
- **THEN** result SHALL соответствовать единому опубликованному normalization contract

### Requirement: ERL-FORMAT-002 — Source resolution never silently drops unreadable chapters

EPUB resolution MUST корректно обрабатывать поддерживаемые namespaces/relative href/fragments/nonlinear items и MUST явно отклонять неподдержанные или missing chapters. Source content MUST NOT подтягиваться из сети; invalid input MUST NOT оставлять partial Book generation.

#### Scenario: Spine references a missing manifest item

- **GIVEN** EPUB содержит broken или отсутствующий chapter member
- **WHEN** book-ingest выполняет apply
- **THEN** операция SHALL вернуть диагностический failure с locator
- **AND** partial Book/source/generation SHALL не оставаться

#### Scenario: URI or archive member escapes local content

- **GIVEN** EPUB href указывает external URI или unsafe path
- **WHEN** parser разрешает content
- **THEN** сетевого обращения и external filesystem read SHALL не происходить
- **AND** неподдержанный locator SHALL быть явно диагностирован
