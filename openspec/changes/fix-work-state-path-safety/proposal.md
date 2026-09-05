# Безопасные пути и владение артефактами rollback

## Why

Аудит воспроизвёл удаление заранее существовавшего файла вне Vault: --work-slug принимал traversal, а rollback удалял весь work_dir. Контроль должен распространяться также на paths из journals и результаты constructors.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `F01`, `A-PATHS`. Приоритет P1; уровень рекомендаций 1. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-BOOK-004`, `ERL-STATE-013`, `ERL-GIT-002`, `ERL-SHELL-002`.

## What Changes

- Mutation targets remain within their canonical roots (ERL-PATH-001).
- New work slugs are safe locators (ERL-PATH-002).
- Rollback removes only owned artifacts (ERL-PATH-003).

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: расширить observable guarantees требованиями ERL-PATH-001, ERL-PATH-003.
- `work-generation`: расширить observable guarantees требованиями ERL-PATH-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-book-ingest.zsh`, `.scripts/erl/erl-work-rename.zsh`, `.scripts/erl/erl-transaction-recover.zsh`, `.scripts/erl/lib/common.zsh`.
- Compatibility/migration: State layout и UUID не меняются. Legacy journal с непроверяемым путём блокируется с диагностикой, исходные файлы сохраняются; конверсия выполняется отдельной explicit recovery procedure.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Аудит воспроизвёл удаление заранее существовавшего файла вне Vault: --work-slug принимал traversal, а rollback удалял весь work_dir — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

Нет обязательных prerequisites внутри этого набора.

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-work-state-path-safety.zsh`, acceptance scenarios `ERL-PATH-001`, `ERL-PATH-002`, `ERL-PATH-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
