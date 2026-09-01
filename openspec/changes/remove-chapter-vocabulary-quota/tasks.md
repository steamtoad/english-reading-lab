## 1. Contract

- [x] 1.1 Добавить `ERL-CAND-010` в OpenSpec delta и legacy traceability; проверить `openspec validate remove-chapter-vocabulary-quota --strict`
- [x] 1.2 Обновить `erl-chapter-vocabulary-extract` через Skill Workshop, запретив Chapter-level Candidate quota и сохранив per-identity deduplication

## 2. Verification

- [x] 2.1 Создать primary regression test `tests/erl-chapter-vocabulary-quota.zsh` и проверить его успешное выполнение
- [x] 2.2 Запустить `openspec validate --all`, `git diff --check` и protected-path audit
