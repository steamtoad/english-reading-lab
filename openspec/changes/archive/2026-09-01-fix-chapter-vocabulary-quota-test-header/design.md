## Context

`erl-skills-check.zsh` детерминированно проверяет строки 2–7 каждого ERL Zsh-файла по `ERL-SHELL-005`. Целевой regression test сейчас начинает executable body сразу после shebang, хотя его quota assertions сами по себе корректны.

## Goals / Non-Goals

**Goals:**

- исправить только структурный header defect;
- сохранить quota assertions и exit behavior byte-semantically эквивалентными;
- обеспечить отдельный primary regression test `tests/erl-chapter-vocabulary-quota-test-header.zsh`.

**Non-Goals:**

- менять `ERL-CAND-010` или extraction semantics;
- ослаблять общий header checker;
- реорганизовывать другие test files.

## Decisions

### Исправляется producer, а не validator

В целевой файл добавляется canonical пятистрочный header между shebang и executable setup. Альтернатива с исключением файла из checker отклонена: она нарушила бы единый `ERL-SHELL-005` contract и скрыла будущие regressions.

### Regression проверяет structure и исходное назначение

Primary test проверяет exact separators, filename, непустые `Тип`/`Назначение`, а затем запускает исходный quota test. Это отделяет structural conformance от содержательных assertions, сохраняя обе гарантии.

## Risks / Trade-offs

- [Механическая правка может случайно изменить quota assertions] → regression запускает исходный test без модификации его body.
- [Проверка только одного файла может дублировать общий audit] → primary test остаётся focused доказательством change, а общий checker обеспечивает repository-wide coverage.

## Migration Plan

1. Добавить canonical header в целевой test.
2. Добавить и запустить primary regression test.
3. Запустить общий header audit и `erl-all`.

Rollback удаляет только добавленный header и primary test; persistent data и пользовательские документы не затрагиваются.
