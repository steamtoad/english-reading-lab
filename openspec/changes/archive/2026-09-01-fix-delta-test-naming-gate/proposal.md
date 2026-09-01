## Why

`erl-delta-test-naming-check.zsh` требует primary regression test от каждого active OpenSpec change, включая planning-only `add-openclaw-agent-setup` с 0/14 implementation tasks. Из-за этого `erl-all` блокируется до реализации setup либо провоцирует добавление фиктивного теста, который не доказывает заявленное поведение.

## What Changes

- Разделить planning-only и implementation-bearing changes в regression-test naming gate.
- Требовать `tests/erl-<behavior-slug>.zsh` до признания change реализованным/готовым, но не блокировать repository suite только из-за незавершённого planning-only change.
- Сохранить deterministic derivation имени primary test и запрет подмены additional focused tests.
- Добавить fixture coverage для planning-only, partially implemented, completed и missing-primary states.
- Не создавать placeholder `tests/erl-openclaw-agent-setup.zsh`: полноценный test остаётся обязательной частью реализации `add-openclaw-agent-setup`.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `engineering-safety`: добавить lifecycle-aware contract для primary regression-test gate, дополняющий `ERL-TEST-001`.

## Impact

- Затрагиваются только ERL development checker `.scripts/erl/dev/erl-delta-test-naming-check.zsh`, его tests, legacy traceability и `tests/erl-all.zsh` integration.
- Новый стабильный contract: `ERL-TEST-002`; существующий `ERL-TEST-001` и naming algorithm сохраняются.
- `add-openclaw-agent-setup` остаётся незавершённым и не получает ложного implementation status; его Task 1.1 по-прежнему должна создать `tests/erl-openclaw-agent-setup.zsh` при реализации.
- Public CLI, runtime ERL behavior, persistent state и Vault documents не меняются.
- Migration, recovery и destructive operations отсутствуют.
- Host-contract impact отсутствует; host core и пользовательский Vault не затрагиваются.
