## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `A-BACKUP`, `A-RETENTION`, `A-OPERATIONS`, `A-TRANSACTION-LIST` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-BACKUP-001`, `ERL-BACKUP-002`, `ERL-OPS-001`, `ERL-OPS-002`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Реализовать/document versioned snapshot/restore format и local CLI c dry-run/apply.
- [ ] 2.2 Добавить read-only transaction inventory и runbook для errors/pending/stale locks/source relocation.
- [ ] 2.3 Провести backup→new-root restore→recovery→check drill, corruption/collision/disk-failure tests и retention assertions.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-erl-backup-restore.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-erl-backup-restore.zsh`, applicable complete offline suite, `openspec validate add-erl-backup-restore --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change add-erl-backup-restore`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
