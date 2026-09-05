## 1. Archive contract

- [x] 1.1 Добавить `OS-ARCHIVE-001..005` в canonical OpenSpec governance после implementation approval и проверить stable-ID uniqueness.
- [x] 1.2 Синхронизировать legacy traceability с canonical requirements и проверить ID parity.

## 2. Enforcement

- [x] 2.1 Добавить archive readiness checker для completed tasks, implementation evidence и successful verification.
- [x] 2.2 Добавить проверку синхронизации applicable deltas в `openspec/specs/` до финального перемещения Change.
- [x] 2.3 Проверять сохранность proposal, design, tasks и всех delta specs в `openspec/changes/archive/`.

## 3. Verification

- [x] 3.1 Добавить primary regression test `tests/erl-openspec-archive-contract.zsh` с positive и negative archive fixtures.
- [x] 3.2 Выполнить `openspec validate --all`, полный ERL suite и `git diff --check`.
