## ADDED Requirements

### Requirement: ERL-EXPORT-001 — Chapter export is independent of process argument limits

Exporter MUST передавать полное поддерживаемое содержимое главы без зависимости от argv limit и без усечения. Успешный response MUST содержать обязательные scope/policy/content fields; ошибка чтения или serialization MUST быть nonzero.

#### Scenario: Chapter exceeds ARG_MAX

- **GIVEN** UTF-8 TXT содержит минимум 2 210 000 bytes и больше текущего ARG_MAX
- **WHEN** пользователь импортирует и экспортирует Chapter
- **THEN** полученный content SHALL совпасть с ожидаемым text content
- **AND** status OK с data={} SHALL быть невозможен

#### Scenario: Unicode and trailing line endings survive

- **GIVEN** источник содержит Cyrillic labels, non-ASCII English context и завершающий LF
- **WHEN** export формирует JSON
- **THEN** content SHALL сохранить текст согласно опубликованным normalization rules без случайного shell trimming
