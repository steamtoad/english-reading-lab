## Context

См. `proposal.md`. Текущий `.scripts/erl/dev/erl-delta-test-naming-check.zsh` перечисляет все active change directories и немедленно требует derived test file. Он не читает lifecycle state change, поэтому корректно созданная planning delta становится repository-wide test failure ещё до начала implementation.

OpenSpec task checkbox state уже является применяемым implementation gate: завершённые changes имеют `tasks.md` с отмеченными `[x]` tasks, незавершённые содержат `[ ]`. `add-openclaw-agent-setup` явно находится в состоянии 0/14 и уже содержит Task 1.1, требующую полноценный `tests/erl-openclaw-agent-setup.zsh`.

## Goals / Non-Goals

**Goals:**

- не блокировать `erl-all` из-за отсутствующего теста у planning-only change;
- сохранить жёсткий failure для completed change без primary test;
- сделать lifecycle classification детерминированной и тестируемой на fixtures;
- сохранить прежний algorithm derivation `erl-<behavior-slug>.zsh`.

**Non-Goals:**

- реализовывать OpenClaw agent setup или создавать placeholder setup regression;
- проверять полноту поведения внутри primary test — naming checker проверяет только lifecycle/naming gate;
- автоматически отмечать tasks выполненными или менять OpenSpec artifact status;
- менять runtime ERL, Vault или host contracts.

## Decisions

### 1. Completion определяется task checkboxes

Checker считает change завершённым для naming gate, только если `tasks.md` существует, содержит хотя бы одну parseable checkbox task и не содержит `- [ ]`. Отсутствующий `tasks.md`, отсутствие checkboxes или хотя бы одна unchecked task означают незавершённый change и не создают missing-primary failure.

Это соответствует уже используемому apply workflow и не требует зависимости от форматирования human-readable CLI output `openspec status`. Альтернатива проверять возраст change, наличие specs или implementation files отклонена: эти признаки не выражают completion. Альтернатива пропускать change по имени `add-openclaw-agent-setup` отклонена как special case.

### 2. Незавершённый change пропускается, а не получает placeholder

Checker не создаёт files и не принимает additional test за primary. Когда последняя task change отмечается `[x]`, derived primary должен уже существовать; иначе тот же запуск завершается exit 10 с exact change name и expected filename.

Placeholder `tests/erl-openclaw-agent-setup.zsh`, проверяющий только наличие proposal, отклонён: он удовлетворил бы filename check, но исказил бы смысл regression coverage `ERL-AGENT-SETUP-001..007`.

### 3. Fixture test моделирует lifecycle независимо от текущего repository

Primary regression `tests/erl-delta-test-naming-gate.zsh` создаёт временный minimal layout и запускает checker через его существующий repository-root argument. Fixtures покрывают incomplete 0/N, partial N/M, complete missing, complete primary present и additional-only cases. Они также подтверждают removal ровно одного leading change-kind prefix.

Тест не меняет реальные OpenSpec tasks и не зависит от списка активных changes checkout, поэтому новый planning change не создаёт рекурсивный blocker.

### 4. Legacy traceability уточняется новым ID

`ERL-TEST-001` продолжает определять имя primary test. Новый `ERL-TEST-002` определяет lifecycle gate и добавляется в `.scripts/erl/docs/requirements.md`; он не переопределяет naming algorithm.

## Risks / Trade-offs

- [Checkbox случайно отмечена раньше фактической реализации] → completed change без primary test немедленно блокируется; semantic truthfulness task state остаётся обязанностью implementation workflow.
- [Нестандартный tasks format будет принят за planning] → checker требует canonical `- [ ]`/`- [x]`; fixture фиксирует parseable format, а OpenSpec tasks schema уже использует его.
- [Change без implementation вообще никогда не нуждается в test] → такой change остаётся incomplete либо использует отдельный explicit no-regression contract; автоматического освобождения completed change здесь нет.
- [Additional test маскирует отсутствие primary] → проверяется только exact derived path.

## Migration Plan

1. Добавить `tests/erl-delta-test-naming-gate.zsh` с isolated lifecycle fixtures.
2. Изменить naming checker так, чтобы missing-primary gate применялся только к changes со всеми выполненными tasks.
3. Добавить `ERL-TEST-002` в legacy traceability и подключить regression к `erl-all`.
4. Запустить primary test, checker на текущем repository, `erl-all`, OpenSpec и boundary checks.

Data migration и recovery отсутствуют. Rollback возвращает прежний unconditional checker, но снова блокирует planning-only changes; никакие runtime или пользовательские данные при rollback не затрагиваются.
