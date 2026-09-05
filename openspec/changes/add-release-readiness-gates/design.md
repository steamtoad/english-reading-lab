## Context

Зелёный штатный runner не обнаружил audit blockers. Для перехода к бете нужны единый воспроизводимый gate, установка/restore/host evidence и проверенное качество Lexi, а не формальная отметка о количестве требований.

Аудит: `A-RELEASE`, `A-CI`, `A-MATURITY-GATES`; исходный baseline: `ERL-TEST-001`, `OS-ARCHIVE-001`, `OS-ARCHIVE-005`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Offline release-check объединяет complete suite, strict OpenSpec validation, diff hygiene, payload parity и audit-specific regression tests; выводит structured evidence manifest с commit/config hashes.

### 2. Решение

CI использует disposable targets и explicit host fixtures. Real-host certification, controlled live eval, restore drill и benchmark имеют отдельные evidence lanes и статус NOT VERIFIED если недоступны.

### 3. Решение

Документировать release/upgrade sequence: backup, validate supported source/journal schema, staged installation, explicit migrations, post-check и rollback version strategy. Нельзя silent downgrade state.

### 4. Решение

Beta readiness требует закрытия safety regressions и restore/host demonstration; production claim дополнительно требует passing declared platform/quality/scale profiles. Отчёт перечисляет точные неподтверждённые profiles.

### 5. Решение

Эта delta реализуется последней и не является поручением публиковать release, включать внешние CI secrets или менять global infrastructure.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-mutation-lock-ownership](../fix-mutation-lock-ownership/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)
- [fix-empty-chapter-ingestion](../fix-empty-chapter-ingestion/proposal.md)
- [fix-source-format-normalization](../fix-source-format-normalization/proposal.md)
- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)
- [fix-asciidoc-projection-safety](../fix-asciidoc-projection-safety/proposal.md)
- [add-reproducible-erl-bootstrap](../add-reproducible-erl-bootstrap/proposal.md)
- [add-host-compatibility-certification](../add-host-compatibility-certification/proposal.md)
- [add-durable-enrichment-provenance](../add-durable-enrichment-provenance/proposal.md)
- [add-lexi-extraction-evaluation](../add-lexi-extraction-evaluation/proposal.md)
- [add-erl-backup-restore](../add-erl-backup-restore/proposal.md)
- [add-erl-performance-baseline](../add-erl-performance-baseline/proposal.md)
- [fix-openspec-contract-authority](../fix-openspec-contract-authority/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- CI PASS на test double не равен production host proof.
- Протокол должен сохранять failed/skipped evidence, а не агрегировать всё в boolean passed.

## Migration and rollback

Release tooling не меняет пользовательские данные. Runtime migrations уже реализованы prerequisites; release docs перечисляют version compatibility и восстановление при неудачном upgrade.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-release-readiness-gates.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
