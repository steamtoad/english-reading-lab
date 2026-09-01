## 1. Regression Contract

- [ ] 1.1 Создать primary regression test `tests/erl-chapter-memo-chain.zsh` для Vocabulary acquisition, Occurrence, exact `:key-topic:`, reciprocal Chapter links, single-node head и multi-node chain; verification: test падает на текущем ingestion и проходит после исправления
- [ ] 1.2 Добавить negative fixtures для mismatched key, one-way Chapter link, duplicate link, missing/multiple head, non-reciprocal predecessor/successor, branch, cycle и cross-Chapter edge; verification: focused checker tests получают `ERL-CHECK-028` с конкретной причиной

## 2. Chapter Attachment

- [ ] 2.1 Расширить ERL host-contract Memo fixture для host-defined `:key-topic:` extra attribute, не меняя production host core; verification: fixture сохраняет exact Chapter key и canonical Memo metadata
- [ ] 2.2 Обновить `erl-vocabulary-ingest.zsh`, чтобы новая Vocabulary или Occurrence наследовала Chapter `:key-topic:` и получала section `Chapter` с canonical Chapter link; verification: primary regression test покрывает обе роли
- [ ] 2.3 Обновить Chapter Note section `Vocabulary` reciprocal link на current Memo в Candidate/source order с idempotent duplicate prevention; verification: retry не меняет link count или order

## 3. Memo Chain

- [ ] 3.1 Разрешать Chapter-local predecessor как последний committed sequence node с тем же `chapter_uuid`; verification: первая Memo каждой Chapter не получает predecessor из предыдущей Chapter
- [ ] 3.2 Материализовать Continue-style reciprocal links `Предыдущее memo`/`Следующее memo` и linear tail update; verification: single-node, two-node и mixed Vocabulary/Occurrence fixtures имеют ожидаемую topology
- [ ] 3.3 Сохранить generation reading ordinals непрерывными между Chapters при отдельных Chapter-local chains; verification: state sequence продолжает `ERL-SEQ-005`, document chain начинается заново на Chapter boundary

## 4. Transaction And Recovery

- [ ] 4.1 Расширить per-Candidate journal backups на Chapter Note и predecessor Memo до первой mutation; verification: transaction fixture содержит paths, pre-hashes и backups обоих existing documents
- [ ] 4.2 Включить Memo creation, key inheritance, attachment, chain, membership, sequence и receipt в один recoverable commit; verification: fault injection после каждого phase восстанавливает pre-operation document bytes и state
- [ ] 4.3 Проверить resumable Chapter batch после interruption; verification: completed Candidates не дублируются, а первый incomplete Candidate продолжает chain от последнего committed tail

## 5. Validation And Migration

- [ ] 5.1 Расширить `erl-check.zsh` read-only проверкой `ERL-CHECK-028`; verification: positive/negative fixtures проходят, hashes Vault/state до и после checker совпадают
- [ ] 5.2 Реализовать отдельную explicit migration legacy Chapter–Memo attachments и chains из persistent sequence с `--dry-run`/`--apply`, conflict detection, journal, rollback и recovery; verification: dry-run mutation-free, apply idempotent, user-owned conflicting sections не перезаписываются
- [ ] 5.3 Обновить CLI contract и legacy traceability для `ERL-ING-010..012`, `ERL-SEQ-009..011` и `ERL-CHECK-028`; verification: contract checks находят все IDs, `:key-topic:` сохраняет host semantics и `:erl-*:` не добавлены

## 6. Verification

- [ ] 6.1 Запустить `tests/erl-chapter-memo-chain.zsh`, `tests/erl-cli.zsh`, `tests/erl-check.zsh` и transaction/migration recovery tests; verification: все focused workflows завершаются успешно
- [ ] 6.2 Запустить `zsh -n` для изменённых scripts/tests, `git diff --check`, protected-path audit и `openspec validate --all`; verification: проверки проходят, host core и пользовательский Vault не изменены
