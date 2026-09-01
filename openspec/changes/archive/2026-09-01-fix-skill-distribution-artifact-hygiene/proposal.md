## Why

`skills/.DS_Store` является macOS metadata artifact и запрещён существующим ERL distribution checker, но сейчас присутствует в skills tree и блокирует `erl-all`. Baseline также не фиксирует наблюдаемое правило repository hygiene нормативно, из-за чего защита зависит только от implementation check.

## What Changes

- Удалить `.DS_Store` из ERL skills distribution recoverable способом при implementation change.
- Обязать ERL repository и skill distribution быть свободными от platform/editor metadata artifacts.
- Сохранить preventive ignore policy и regression check, чтобы artifact не возвращался незаметно.
- Не ослаблять существующую проверку других запрещённых skill installation artifacts.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: добавить normative repository/distribution hygiene contract для platform-generated artifacts.

## Impact

Изменение затрагивает ERL-owned repository hygiene, `.gitignore`, development checks и regression tests. Public CLI, runtime behavior, persistent state и Vault documents не меняются. Data migration и destructive user-data operations отсутствуют; удаляется только disposable `.DS_Store`. Host-contract gap отсутствует, host core не затрагивается.
