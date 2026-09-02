## Context

См. `proposal.md` — Why. Текущий naming checker удаляет только семь action prefixes и поэтому выводит для `remove-chapter-vocabulary-quota` ошибочный путь `erl-remove-chapter-vocabulary-quota.zsh`, хотя design/tasks этой дельты и существующий test используют `erl-chapter-vocabulary-quota.zsh`. Gate намеренно пропускает planning changes с незавершёнными tasks, но блокирует completed changes.

## Goals / Non-Goals

**Goals:**

- определить единый prefix mapping для authoring contract, checker и fixtures;
- устранить текущий false-negative без создания дублирующего test wrapper;
- сделать primary test обязательным для каждой дельты к моменту завершения implementation и archive;
- сохранить planning-only workflow, в котором test может появиться после proposal/specs/design.

**Non-Goals:**

- требовать runnable test до создания `tasks.md` или до начала implementation;
- переименовывать существующие корректно названные tests;
- менять OpenSpec CLI, runtime ERL, host contract или Vault data;
- автоматически генерировать содержимое regression tests.

## Decisions

### 1. `remove-` является распознаваемым change-kind prefix

Prefix mapping расширяется значением `remove-`. Для `remove-chapter-vocabulary-quota` canonical filename становится существующий `erl-chapter-vocabulary-quota.zsh`.

Альтернатива — добавить новый `erl-remove-chapter-vocabulary-quota.zsh` — отклонена: она закрепила бы расхождение с design/tasks change и создала бы дублирующий wrapper вместо исправления общего правила.

### 2. Обязательность определяется lifecycle, а не наличием добровольной coverage

Каждый ERL change получает primary test task. Naming gate продолжает пропускать change, пока существует хотя бы одна незавершённая implementation task, но блокирует completed change и archive без canonical file.

Альтернатива — требовать test сразу после `openspec new change` — отклонена: planning-only changes ещё не имеют реализуемого поведения и не должны блокировать общий suite до implementation phase.

### 3. Один derivation contract используется во всех проверках

Checker, regression fixtures, OpenSpec design/tasks guidance и legacy traceability должны перечислять одинаковый набор prefixes и одинаковый алгоритм удаления ровно одного leading prefix.

Альтернатива — хранить произвольное test name в `tasks.md` — отклонена: свободный текст не обеспечивает детерминированную repository validation.

### 4. Новая дельта проверяет собственное правило

Primary regression test этой дельты — `tests/erl-delta-primary-test-contract.zsh`. Он проверяет как mapping `remove-`, так и обязательность canonical test для completed change.

## Risks / Trade-offs

- **[Существуют другие action prefixes вне списка]** → неизвестный prefix сохраняется как часть behavioral slug; новые prefixes добавляются только явным contract change.
- **[Planning change остаётся без test слишком долго]** → это допустимо только пока implementation tasks не завершены; completion/archive gate остаётся блокирующим.
- **[Checker и документация снова расходятся]** → primary regression fixture проверяет полный normative prefix set и exact expected paths.

## Migration Plan

1. Синхронизировать `ERL-TEST-001/002` и legacy traceability.
2. Добавить `remove-` в naming checker и contract fixtures.
3. Добавить primary regression test `erl-delta-primary-test-contract.zsh`.
4. Подтвердить, что существующий `erl-chapter-vocabulary-quota.zsh` разблокирует completed `remove-chapter-vocabulary-quota` без дублирующего файла.
5. Запустить naming gate, полный ERL suite и OpenSpec validation.

Persistent migration и recovery не требуются. Rollback состоит в возврате contract/checker изменений; Vault и state не затрагиваются.
