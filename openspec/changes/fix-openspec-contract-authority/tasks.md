## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `A-GOVERNANCE`, `A-TRACEABILITY`, `A-CONFIG-DRIFT` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-GOVERNANCE-001`, `ERL-GOVERNANCE-002`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Согласовать authority config/AGENTS/legacy consumers с действующим OS-ARCHIVE-005.
- [ ] 2.2 Добавить traceability rule→test→result manifest и gate на missing/stale evidence.
- [ ] 2.3 Проверить conflict fixture и planned-versus-fixed reporting, не переписывая archived history.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-openspec-contract-authority.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-openspec-contract-authority.zsh`, applicable complete offline suite, `openspec validate fix-openspec-contract-authority --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change fix-openspec-contract-authority`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
