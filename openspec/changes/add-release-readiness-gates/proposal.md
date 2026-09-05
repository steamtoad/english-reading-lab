# Критерии контролируемой беты и выпуска

## Why

Зелёный штатный runner не обнаружил audit blockers. Для перехода к бете нужны единый воспроизводимый gate, установка/restore/host evidence и проверенное качество Lexi, а не формальная отметка о количестве требований.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-RELEASE`, `A-CI`, `A-MATURITY-GATES`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-TEST-001`, `OS-ARCHIVE-001`, `OS-ARCHIVE-005`.

## What Changes

- Release gates aggregate complete reproducible evidence (ERL-RELEASE-001).
- Readiness distinguishes verified and unavailable profiles (ERL-RELEASE-002).
- Upgrade and rollback preserve supported data versions (ERL-RELEASE-003).

## Capabilities

### New Capabilities

- `release-readiness`: Определить критерии проверенного выпуска ERL, полноту execution evidence, явные ограничения поддерживаемых профилей и безопасное обновление данных.

### Modified Capabilities

Нет.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/dev/erl-release-check.zsh`, `CI configuration`, `docs/release.md`, `docs/operations.md`, `README.MD`.
- Compatibility/migration: Release tooling не меняет пользовательские данные. Runtime migrations уже реализованы prerequisites; release docs перечисляют version compatibility и восстановление при неудачном upgrade.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Зелёный штатный runner не обнаружил audit blockers — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

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

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-release-readiness-gates.zsh`, acceptance scenarios `ERL-RELEASE-001`, `ERL-RELEASE-002`, `ERL-RELEASE-003`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
