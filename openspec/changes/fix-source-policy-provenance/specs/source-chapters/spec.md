## ADDED Requirements

### Requirement: ERL-PROVENANCE-001 — Export binds exact source content and policy

Exporter MUST сверить используемые source bytes с retained fingerprint и полностью проверить immutable policy/hash до выдачи successful content. Изменение source во время проверки/чтения MUST приводить к отказу либо использованию того же проверенного snapshot, без смешения identity и content.

#### Scenario: Source file is replaced after import

- **GIVEN** исходник по source_path заменён другим текстом
- **WHEN** Chapter экспортируется
- **THEN** export SHALL вернуть source conflict и не выдавать новый текст под прежней identity

#### Scenario: Policy hash is stale

- **GIVEN** policy threshold изменён без нового identity
- **WHEN** Chapter экспортируется
- **THEN** export SHALL вернуть validation failure

#### Scenario: Source changes during export

- **GIVEN** источник изменяется после начала проверки
- **WHEN** export читает content
- **THEN** ответ SHALL содержать bytes одного проверенного snapshot либо nonzero conflict

### Requirement: ERL-PROVENANCE-003 — Relocation preserves edition identity only for identical bytes

Source relocation MUST быть explicit dry-run/apply operation с backup/journal и проверкой нового файла против retained fingerprint. Byte-identical relocation MUST сохранять UUID и mappings; другой edition MUST отклоняться с направлением на новую source identity.

#### Scenario: An unchanged source moved to another machine path

- **GIVEN** старый source_path недоступен, новый файл имеет retained SHA-256
- **WHEN** source-rebind применяется к explicit WORK_ID/SOURCE_ID
- **THEN** только source_path SHALL измениться
- **AND** Chapter UUID, SOURCE_ID и ссылки SHALL сохраниться

#### Scenario: Rebind receives a different edition

- **GIVEN** новый файл имеет иной SHA-256
- **WHEN** rebind выполняет dry-run или apply
- **THEN** операция SHALL вернуть conflict до mutation
