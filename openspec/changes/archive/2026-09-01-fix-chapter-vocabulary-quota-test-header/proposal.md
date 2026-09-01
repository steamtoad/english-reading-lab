## Why

`tests/erl-chapter-vocabulary-quota.zsh` нарушает уже действующий `ERL-SHELL-005`: после shebang отсутствует обязательный пятистрочный индивидуальный header. Из-за этого development checker завершает `erl-all` до запуска полного набора тестов.

## What Changes

- Привести header `tests/erl-chapter-vocabulary-quota.zsh` к canonical ERL Zsh format.
- Добавить primary regression coverage, подтверждающее conformance конкретного теста и сохранение его исходного поведения.
- Проверить, что полный header audit больше не выдаёт diagnostics для этого файла.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

Нет. Change исправляет implementation conformance к существующему `ERL-SHELL-005`, не меняя нормативный контракт; поэтому `.openspec.yaml` использует `skip_specs: true`.

## Impact

Изменение затрагивает только ERL-owned test script и regression checks. Совместимость CLI, persistent state и Vault documents не меняется; migration и destructive operations отсутствуют. Host-contract gap отсутствует, host core не затрагивается.
