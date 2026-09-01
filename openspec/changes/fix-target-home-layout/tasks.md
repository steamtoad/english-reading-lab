## 1. Path contract

- [x] 1.1 Добавить общий target-home resolver, отделённый от host-contract resolver, и проверить unit fixtures для трёх независимых roots.
- [x] 1.2 Перевести document/state path helpers на `<ZETTELKASTEN_HOME>/{notes,.state/erl}` и проверить отсутствие production fallback к nested `vault/`.
- [x] 1.3 Обновить CLI contract: определить `--vault` как compatibility spelling target home и проверить статическую contract fixture.

## 2. Validation and migration

- [x] 2.1 Добавить в `erl-check` canonical layout validation и `HOME_LAYOUT_MIGRATION_REQUIRED`; проверить canonical, legacy и mixed-layout fixtures.
- [x] 2.2 Реализовать migration dry-run с inventory, hashes и collision classification; проверить, что dry-run не изменяет filesystem.
- [x] 2.3 Реализовать explicit apply с journal до первой mutation; проверить успешную migration documents и всех state classes.
- [x] 2.4 Реализовать recovery и hash-protected rollback; проверить injected failures и защиту неожиданных пользовательских изменений.

## 3. ERL operations

- [x] 3.1 Перевести book ingest и canonical Topic/Note creation на target home; проверить создание только в root `notes/` через host constructors.
- [x] 3.2 Перевести vocabulary/occurrence ingestion и extraction staging на target home; проверить document, receipt, staging и idempotency scenarios.
- [x] 3.3 Перевести Reduce, reconciliation, rename, state migration и transaction recovery; проверить closure, rollback/recovery и отсутствие nested paths.
- [x] 3.4 Перевести read-only export/check helpers; проверить разрешение UUID только из root `notes/`.

## 4. Tests and agent contracts

- [x] 4.1 Обновить test host fixtures так, чтобы runtime home имел root `notes/` и `.state/`, и проверить repository boundary test.
- [x] 4.2 Добавить static regression test, запрещающий production references к `$target_home/vault/notes` и `$target_home/vault/.state`; проверить intentional migration fixtures allowlist.
- [x] 4.3 Обновить 7 skills Lexi и shared agent contracts, затем проверить `erl-skills-check.zsh` и routing tests.
- [x] 4.4 Синхронизировать legacy requirement traceability без изменения stable IDs и проверить соответствие OpenSpec baseline.
- [x] 4.5 Переименовать primary regression test в `erl-target-home-layout.zsh` и добавить проверку deterministic delta-spec/test naming в полном suite.

## 5. Verification

- [x] 5.1 Выполнить focused layout/migration/transaction tests и проверить все failure diagnostics.
- [x] 5.2 Выполнить `openspec validate --all`, `tests/erl-all.zsh` и `git diff --check`; подтвердить отсутствие изменений host repository и user Vault.
