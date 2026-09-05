## Purpose

Определить consistent backup и conflict-safe восстановление canonical документов, persistent ERL state и необходимых recovery artifacts между локальными target homes.

## ADDED Requirements

### Requirement: ERL-BACKUP-001 — Backup captures the complete consistent source of truth

Backup MUST включать согласованные notes и works, compact committed audit и необходимые unresolved journals/backups с versioned inventory/hashes. Inclusion policy source/staging MUST быть явной; cache и runtime locks MUST NOT трактоваться как canonical state.

#### Scenario: Git-ignored state is backed up

- **GIVEN** notes/works не tracked в Git, есть pending transaction
- **WHEN** выполняется backup
- **THEN** snapshot SHALL содержать обе canonical части и recovery artifacts
- **AND** Git ignore SHALL не исключать persistent данные из snapshot

#### Scenario: A writer races with backup

- **GIVEN** ingestion пытается изменить Vault во время snapshot
- **WHEN** backup завершается
- **THEN** snapshot SHALL соответствовать единому согласованному состоянию либо operation SHALL вернуть conflict

### Requirement: ERL-BACKUP-002 — Restore validates and preserves the destination

Restore MUST иметь dry-run/apply, проверить inventory/hashes/paths и collisions до записи, отклонять traversal/symlink escape и сохранять pre-existing target data. Успешное завершение MUST требовать erl-check/recovery validation; failure самого restore MUST быть recoverable.

#### Scenario: Snapshot is restored into a different empty root

- **GIVEN** валидный snapshot содержит cards, works и supported pending journal
- **WHEN** restore dry-run/apply выполняются в другом canonical root
- **THEN** UUID/links SHALL сохраниться, пути SHALL быть безопасно rebound
- **AND** recovery и erl-check SHALL подтвердить согласованность

#### Scenario: Archive is corrupt or destination is populated

- **GIVEN** hash не совпал либо destination содержит sentinel
- **WHEN** запускается restore apply без reviewed replacement
- **THEN** операция SHALL отклоняться до overwriting sentinel

#### Scenario: Restore is interrupted

- **GIVEN** часть файлов staged, активация ещё не завершена
- **WHEN** процесс прерывается и восстановление повторяется
- **THEN** partial data SHALL не объявляться active complete Vault
- **AND** повтор SHALL безопасно завершить или откатить restore
