# Backup, восстановление Vault и операционная диагностика

## Why

Источником истины являются notes плюс works, оба могут быть Git-ignored. Наличие journals не равно проверенному восстановлению после потери каталога. Оператору нужен read-only список pending операций, а cleanup не должен удалять persistent или unresolved данные.

Источник: [аудит 2026-09-05](../../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc), пункты `A-BACKUP`, `A-RETENTION`, `A-OPERATIONS`, `A-TRANSACTION-LIST`. Приоритет P2; уровень рекомендаций 3. Текущий normative baseline — `openspec/specs/`; legacy scope для traceability: `ERL-STATE-003`, `ERL-STATE-006`, `ERL-STATE-008`, `ERL-STATE-010`, `ERL-CHECK-018`.

## What Changes

- Backup captures the complete consistent source of truth (ERL-BACKUP-001).
- Restore validates and preserves the destination (ERL-BACKUP-002).
- Pending operations have an actionable read-only inventory (ERL-OPS-001).
- Retention cannot remove durable or unresolved data (ERL-OPS-002).

## Capabilities

### New Capabilities

- `backup-restore`: Определить consistent backup и conflict-safe восстановление canonical документов, persistent ERL state и необходимых recovery artifacts между локальными target homes.
- `operational-diagnostics`: Предоставить оператору read-only инвентаризацию незавершённых операций, фаз и доступных действий восстановления без неявных мутаций или очистки locks.

### Modified Capabilities

- `persistent-state`: расширить observable guarantees требованиями ERL-OPS-002.

## Impact

- Затрагиваемые компоненты: `.scripts/erl/erl-state-backup.zsh`, `.scripts/erl/erl-state-restore.zsh`, `.scripts/erl/erl-transaction-list.zsh`, `.scripts/erl/erl-transaction-recover.zsh`, `docs/operations.md`, `tests/`.
- Compatibility/migration: Snapshot format versioned. Existing deployments получают документированную backup policy без изменения Git tracking. Restore не переименовывает UUID, не применяет пользовательские host bindings автоматически и не мигрирует чужой Vault без отдельного запроса.
- Host boundary: изменения только в ERL; production host core и пользовательский Vault не изменяются в рамках implementation этой delta. Contract gaps оформляются отдельно.
- Польза сейчас: Источником истины являются notes плюс works, оба могут быть Git-ignored — устранение описанного разрыва.
- Совместимость с workflow: local files, zsh, AsciiDoc, canonical UUID/links и явные dry-run/apply сохраняются.
- Польза для будущей архитектуры: проверяемый contract для этой области без нового хранилища или platform migration.

## Dependencies

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cross-operation-mutation-serialization](../fix-cross-operation-mutation-serialization/proposal.md)
- [fix-transaction-recovery-coverage](../fix-transaction-recovery-coverage/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)
- [add-reproducible-erl-bootstrap](../add-reproducible-erl-bootstrap/proposal.md)

## Completion

Дельта сейчас является планом. Закрытие требует implementation, primary regression `tests/erl-erl-backup-restore.zsh`, acceptance scenarios `ERL-BACKUP-001`, `ERL-BACKUP-002`, `ERL-OPS-001`, `ERL-OPS-002`, полного applicable gate и evidence. Сама validation спецификаций не означает исправление недостатков.
