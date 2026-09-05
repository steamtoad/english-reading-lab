## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `A-RELEASE`, `A-CI`, `A-MATURITY-GATES` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-RELEASE-001`, `ERL-RELEASE-002`, `ERL-RELEASE-003`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Добавить local release-check и CI lanes с explicit source/config evidence и отдельным SKIP.
- [ ] 2.2 Описать beta/production criteria, documented upgrade/rollback и version compatibility.
- [ ] 2.3 Выполнить complete safety/host/restore/quality/performance evidence collection; публикацию релиза оставить отдельным действием.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-release-readiness-gates.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-release-readiness-gates.zsh`, applicable complete offline suite, `openspec validate add-release-readiness-gates --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change add-release-readiness-gates`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
