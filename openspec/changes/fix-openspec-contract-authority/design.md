## Context

Текущий AGENTS.md и canonical OS-ARCHIVE-005 уже назначают openspec/specs нормативным baseline, но openspec/config.yaml всё ещё описывает legacy requirements как текущий source и незавершённый переход. Аудит также выявил разрыв между объёмом текстов и проверенными behaviors.

Аудит: `A-GOVERNANCE`, `A-TRACEABILITY`, `A-CONFIG-DRIFT`; исходный baseline: `OS-ARCHIVE-001`, `OS-ARCHIVE-005`, `ERL-TEST-001`, `ERL-TEST-003`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Привести consumers/settings к уже принятому canonical source of truth. Legacy документ сохраняется как traceability, active deltas как pending plans; archived history не редактируется для получения parity.

### 2. Решение

Матрица rule→behavioral test→evidence различает PASS/FAIL/SKIP/NOT IMPLEMENTED. Audit finding считается закрытым только после его acceptance tests, не после написания proposal.

### 3. Решение

Будущие deltas с пересечением modified requirement обновляются на актуальный baseline перед apply/archive. Этот набор преимущественно additive и распределяет ownership требований по одному change.

### 4. Решение

Нужен static authority/parity gate и behavioral linkage, а не требование идентичных prose строк во всех documents. Удаление старого normative дублирования допускается только с сохранением traceability IDs.

## Dependencies and sequencing

- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Объём спецификаций не является покрытием; generated dashboards должны показывать непроверенное явно.
- Слепая синхронизация архивов в baseline восстановит устаревшее поведение.

## Migration and rollback

Текущие canonical requirements не меняют смысл. Config/readme/legacy authority wording исправляется при реализации этой delta, старые archives остаются historical records.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-openspec-contract-authority.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
