# Стабильное чтение EPUB и поддерживаемых форматов

## Why

Minimal EPUB экспортируется как raw XHTML на macOS; fallback другой ОС отличается. Частично читаемые spine items могут пропускаться. TXT/Markdown/HTML сейчас дают по одной Chapter на файл, что не объяснено пользователю.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F09`, `A-FORMATS`. Приоритет P2; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-CHAPTER-007`, `ERL-EXT-003`, `ERL-SHELL-003`, `ERL-DOC-008`.

## What Changes

- Supported formats produce normalized prose (ERL-FORMAT-001).
- Source resolution never silently drops unreadable chapters (ERL-FORMAT-002).
- Parser compatibility is tested per supported platform (ERL-FORMAT-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: расширить observable guarantees требованиями ERL-FORMAT-003.
- `source-chapters`: расширить observable guarantees требованиями ERL-FORMAT-001, ERL-FORMAT-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/lib/source.zsh`, `.scripts/erl/erl-book-ingest.zsh`, `.scripts/erl/erl-chapter-export.zsh`, `fixtures/`, `README.MD`.
- Compatibility/migration: Existing SOURCE_ID/Chapter locators не переписываются. Изменение normalization, влияющее на semantic extraction, версионируется в processing contract для последующих generations; existing committed memos сохраняются.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Minimal EPUB экспортируется как raw XHTML на macOS; fallback другой ОС отличается — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-source-format-normalization.zsh`, acceptance scenarios `ERL-FORMAT-001`, `ERL-FORMAT-002`, `ERL-FORMAT-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
