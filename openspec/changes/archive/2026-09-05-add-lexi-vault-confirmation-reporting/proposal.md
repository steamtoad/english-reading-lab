## Why

Даже при правильном выборе `${ERL_HOME}` Lexi может выполнить mutation с устаревшим или подменённым Vault, если фактический path не включён в подтверждаемый plan и не проверяется повторно перед `--apply`. Успешный `erl-check` другого Vault затем создаёт ложный отчёт об успешной материализации в ожидаемом workspace.

## What Changes

- Обязать Lexi показывать absolute фактический Vault в L2/L3 plan до запроса отдельного явного подтверждения.
- Связать подтверждение с неизменным plan, включая Vault identity, и повторно проверить Vault непосредственно перед `--apply`.
- Запретить mutation при изменении, повторном разрешении в другой path или невозможности подтвердить тот же Vault после пользовательского согласия.
- После mutation запускать canonical `erl-check.zsh` с тем же exact `--vault "${ERL_HOME}"` и соответствующим `WORK_ID` либо наиболее широким изменённым scope.
- Обязать итоговый отчёт показывать фактический Vault и результат проверки именно этого Vault.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `agent-environment-setup`: runtime-контракт Lexi получает подтверждаемую Vault identity, pre-apply revalidation и обязательное post-check/reporting того же Vault.

## Impact

Изменение затрагивает общий agent contract, authorization policy, семь reference skills, embedded OpenClaw setup payload, Lexi runtime documentation и regression tests. Public ERL CLI не меняется; требования относятся к orchestration Lexi.

Существующие Vault documents и work state не мигрируют и не удаляются. Host-contract semantics и host core не изменяются. Existing materialized Lexi workspace потребуется обновить через штатный conflict-safe setup replacement workflow.
