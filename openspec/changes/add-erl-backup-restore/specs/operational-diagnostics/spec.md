## Purpose

Предоставить оператору read-only инвентаризацию незавершённых операций, фаз и доступных действий восстановления без неявных мутаций или очистки locks.

## ADDED Requirements

### Requirement: ERL-OPS-001 — Pending operations have an actionable read-only inventory

erl-transaction-list MUST read-only перечислять runtime и setup journals с operation/version/phase/scope, blockers и supported recovery action. Unknown journal MUST показываться как unresolved, а не исчезать из inventory; команда MUST NOT снимать locks или менять state.

#### Scenario: Pending Reduce and unknown setup journal coexist

- **GIVEN** Vault содержит оба journal family
- **WHEN** оператор вызывает transaction-list --json
- **THEN** ответ SHALL показать обе операции и соответствующие supported/unknown actions
- **AND** hash inventory target SHALL не измениться
