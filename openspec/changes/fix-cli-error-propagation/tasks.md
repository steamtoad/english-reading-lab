## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `F03`, `F04`, `A-REPORTING` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-CLI-001`, `ERL-CLI-002`, `ERL-CLI-003`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Проверить error propagation по всем public commands и внедрить общий boundary emitter.
- [ ] 2.2 Добавить schema checks result data, early --json scan и dependency-failure fallback.
- [ ] 2.3 Проверить missing/legacy/inaccessible roots, malformed args, pipeline failure и partial batch reporting.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-cli-error-propagation.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-cli-error-propagation.zsh`, applicable complete offline suite, `openspec validate fix-cli-error-propagation --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change fix-cli-error-propagation`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
