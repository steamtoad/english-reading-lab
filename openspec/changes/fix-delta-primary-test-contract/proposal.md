## Why

Naming validation блокирует завершённую дельту `remove-chapter-vocabulary-quota`, хотя её primary regression test уже существует как `tests/erl-chapter-vocabulary-quota.zsh`: action prefix `remove-` отсутствует в deterministic naming rule. Одновременно формулировка `ERL-TEST-001` допускает ошибочное прочтение, будто primary test обязателен только для changes, где coverage решили добавить отдельно.

## What Changes

- Добавить `remove-` в исчерпывающий список распознаваемых change-kind prefixes, чтобы `remove-chapter-vocabulary-quota` однозначно разрешался в `erl-chapter-vocabulary-quota.zsh`.
- Потребовать primary regression test для каждого ERL OpenSpec change, а не только для change с необязательной regression coverage.
- Зафиксировать lifecycle gate: planning change может временно не иметь test, но implementation tasks нельзя считать завершёнными и change нельзя архивировать без canonical primary test.
- Требовать от naming diagnostic показывать change name и exact expected test path.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: уточняется обязательность primary regression test, полный prefix mapping и lifecycle validation для каждого ERL OpenSpec change.

## Impact

Затронуты `ERL-TEST-001`, `ERL-TEST-002`, legacy traceability, OpenSpec/task authoring guidance, naming checker и его regression fixtures. CLI runtime, persistent state, host contract и пользовательский Vault не изменяются; migration и destructive operations не требуются.
