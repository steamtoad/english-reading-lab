## 1. Contract и baseline

- [ ] 1.1 Перепроверить reproducer/ограничение аудита `A-ASCIIDOC`, `A-CARD-VALIDATION` на current baseline, зафиксировать scope и prerequisite status.
- [ ] 1.2 Согласовать observable data/error/version contract требований `ERL-ASCIIDOC-001`, `ERL-ASCIIDOC-002`, `ERL-ASCIIDOC-003`; обновить CLI/legacy traceability там, где это затронуто, не подменяя canonical baseline активной delta.

## 2. Implementation

- [ ] 2.1 Объединить serialization/parsing rules для metadata, section links и descriptions.
- [ ] 2.2 Сделать projection edits atomic/hash-aware с явными user-owned границами.
- [ ] 2.3 Добавить round-trip fixtures UTF-8/brackets/backslashes/newlines, valid prose, handwritten section, duplicate/ambiguous links.

## 3. Regression и acceptance

- [ ] 3.1 Добавить primary regression `tests/erl-asciidoc-projection-safety.zsh` с positive и negative behavioral scenarios из всех specs этой delta; обеспечить включение обязательных tests в complete suite.
- [ ] 3.2 Проверить compatibility, read-only dry-run, failure inventories и recovery согласно применимому scope; для documentation/evaluation gate использовать воспроизводимые fixture/output comparisons.
- [ ] 3.3 Выполнить `tests/erl-asciidoc-projection-safety.zsh`, applicable complete offline suite, `openspec validate fix-asciidoc-projection-safety --type change --strict --no-interactive`, `openspec validate --all --strict --no-interactive` и `git diff --check`; сохранить evidence и отдельно отметить unavailable external cases.
- [ ] 3.4 Подтвердить все acceptance scenarios и обновить audit traceability status с planned на verified только для реально прошедших требований.

## 4. Completion и archive

- [ ] 4.1 Перечитать актуальный `openspec/specs/`, согласовать accumulated deltas и проверить ID uniqueness до archive.
- [ ] 4.2 После завершения implementation/verification выполнить `.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change fix-asciidoc-projection-safety`; archival и baseline sync выполнять только как завершение реализованного change.
- [ ] 4.3 После архивирования выполнить штатный postcondition check с exact archive path и canonical validation; сохранить полный historical change.
