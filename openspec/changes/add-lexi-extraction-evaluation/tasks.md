## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `A-SEMANTIC-EVAL`, `A-KNOWN-WORDS`, `A-SEGMENTATION`, `A-MODEL-DATA-BOUNDARY` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-EVAL-001`, `ERL-EVAL-002`, `ERL-EVAL-003`, `ERL-EVAL-004`, `ERL-EVAL-005`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Создать corpus/annotations, offline metric evaluator и его deterministic primary tests.
- [ ] 2.2 Реализовать/document segment merge, versioned acceptance policy и opt-in controlled live harness.
- [ ] 2.3 Уточнить user-facing known-word claims, выполнить baseline затем frozen acceptance runs и сохранить safe evidence.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-lexi-extraction-evaluation.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-lexi-extraction-evaluation.zsh`, applicable complete offline suite, `openspec validate add-lexi-extraction-evaluation --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change add-lexi-extraction-evaluation`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
