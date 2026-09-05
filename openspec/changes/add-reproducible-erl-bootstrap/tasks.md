## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `A-INSTALL`, `A-DOCTOR`, `A-ROOT-CONFIG` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-BOOT-001`, `ERL-BOOT-002`, `ERL-BOOT-003`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Написать complete README/runbook для generic CLI и exact-binding Lexi deployment.
- [ ] 2.2 Добавить read-only erl-doctor и JSON/error contract, изолированный bootstrap example.
- [ ] 2.3 Оформить reproducible payload build/verification и test installation в каталоге с пробелами.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-reproducible-erl-bootstrap.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-reproducible-erl-bootstrap.zsh`, applicable complete offline suite, `openspec validate add-reproducible-erl-bootstrap --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change add-reproducible-erl-bootstrap`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
