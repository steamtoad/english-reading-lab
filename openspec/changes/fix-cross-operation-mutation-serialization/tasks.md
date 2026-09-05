## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `F02`, `A-CONCURRENCY`, `A-GIT-PREFLIGHT` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-CONCURRENCY-001`, `ERL-CONCURRENCY-002`, `ERL-CONCURRENCY-003`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Ввести shared mutation context/serialization protocol и перевести все overlapping writers.
- [ ] 2.2 Повторять authoritative reads и plans после lock, включая receipts и global Vocabulary lookup.
- [ ] 2.3 Обобщить mass-mutation preflight, добавить contention fixtures ingest/ingest, ingest/Reduce, rename/recover и non-Git case.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-cross-operation-mutation-serialization.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-cross-operation-mutation-serialization.zsh`, applicable complete offline suite, `openspec validate fix-cross-operation-mutation-serialization --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change fix-cross-operation-mutation-serialization`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
