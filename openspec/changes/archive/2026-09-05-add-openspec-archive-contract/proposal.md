## Why

ERL не имеет явного нормативного precondition contract для архивирования OpenSpec changes. Без него незавершённый или не синхронизированный change может быть перемещён в archive, а historical delta ошибочно принят за текущий source of truth.

## What Changes

- Разрешить archival только после завершения implementation, verification и specification validation.
- Требовать синхронизации всех applicable deltas в canonical `openspec/specs/` до завершения archival.
- Сохранять полный Change в `openspec/changes/archive/`.
- Зафиксировать historical-only статус archived delta specifications.
- Подтвердить `openspec/specs/` единственным source of truth текущих требований.

## Capabilities

### New Capabilities

- `openspec-governance`: lifecycle и source-of-truth contract архивирования OpenSpec changes.

### Modified Capabilities

Нет.

## Impact

- Затронуты OpenSpec workflow, development skills, archive validation и regression coverage.
- Runtime ERL, host core и пользовательские данные не изменяются.
- Existing archived changes не становятся current requirements и сохраняются как historical records.
