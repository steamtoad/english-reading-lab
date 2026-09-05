## Context

Оба теста вручную создают canonical Vault documents и persistent work state. После введения title-derived key contract такие документы считаются положительными fixture только при согласованности всей materialized projection: Book Topic, Chapter Notes и принадлежащие текущим Chapters Vocabulary/Occurrence Memo должны использовать title соответствующей книги.

Ошибки возникают не в проверяемых repair/handoff operations, а в precondition и postcondition validation этих fixture. Нормативный runtime-контракт уже задан change `fix-book-title-key-topic`; дополнительный engineering-safety contract фиксирует обязанность поддерживать положительные integration fixtures согласованными с canonical baseline.

## Goals / Non-Goals

**Goals:**

- восстановить валидные положительные preconditions обоих интеграционных тестов;
- сохранить проверки card-content repair и Chapter-chain handoff без ослабления `erl-check`;
- зафиксировать оба случая одним canonical primary regression gate.

**Non-Goals:**

- менять `erl-check`, repair или handoff production implementation;
- возвращать поддержку отдельного umbrella `:key-topic:`;
- менять человекочитаемый body field `Reading topic:: Reading`, поскольку он не является header `:key-topic:` и остаётся частью card-content fixture;
- мигрировать реальные Vault documents или persistent state.

## Decisions

### Исправить полную положительную projection каждого fixture

В `erl-human-readable-card-content.zsh` Book Topic, Chapter, Vocabulary и Occurrence получают `:key-topic: A Human Book`. В `erl-chapter-chain-handoff.zsh` Book Topic, все Chapters и все Memo получают `:key-topic: Handoff Book`.

Частичное изменение только документа, на котором проявился exit code, отклонено: оно оставило бы fixture внутренне несогласованным и лишь переместило бы ошибку на следующую validation stage.

### Не ослаблять assertions и checker

Существующие проверки repair result, readable body и handoff links сохраняются. `erl-check` продолжает выполняться как финальный read-only oracle. Альтернатива пропустить checker или разрешить test-only legacy key отклонена, потому что она скрыла бы нарушение действующего runtime-контракта.

### Primary regression агрегирует два исходных сценария

Canonical primary test для change — `tests/erl-book-title-key-topic-integration-fixtures.zsh`. Он запускает оба исправленных интеграционных теста и требует их успешного завершения; исходные test files остаются самостоятельными focused gates и продолжают входить в `tests/erl-all.zsh`.

Дублирование их fixture в primary test отклонено: оно создало бы третью копию данных, способную снова устареть независимо.

## Risks / Trade-offs

- [Обновлён только один из descendant documents] → Проверить отсутствие `:key-topic: Reading` во всех положительных AsciiDoc fixture и выполнить финальный `erl-check`.
- [При замене key случайно меняется `Reading topic:: Reading`] → Менять только header attributes и сохранить существующие card-content assertions.
- [Primary wrapper скрывает exit code вложенного теста] → Использовать fail-fast invocation и выполнить также оба focused tests напрямую при verification.
- [Полный suite обнаруживает другие незавершённые локальные изменения] → Отдельно зафиксировать результаты primary/focused tests и отличать несвязанные failures полного suite от этих двух регрессий.

## Migration Plan

1. Обновить title-derived `:key-topic:` во всей projection каждого fixture.
2. Запустить каждый focused test отдельно и подтвердить устранение exit codes 60 и 1.
3. Добавить и запустить canonical primary regression test.
4. Выполнить `tests/erl-all.zsh` и OpenSpec validation.

Data migration и recovery не применимы: тесты создают временные Vault fixture и удаляют их после выполнения. Rollback состоит в возврате только test-source изменений; production data не затрагиваются.
