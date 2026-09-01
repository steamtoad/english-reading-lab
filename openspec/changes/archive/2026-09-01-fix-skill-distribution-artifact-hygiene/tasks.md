## 1. Regression contract

- [x] 1.1 Создать primary test `tests/erl-skill-distribution-artifact-hygiene.zsh` с isolated clean и `.DS_Store` fixtures; проверить successful clean case и failure с exact artifact path.
- [x] 1.2 Добавить primary fixtures для ранее запрещённых `.openclaw/source-origin.json` и `.openclaw-install-backups`; проверить, что fix не ослабляет existing distribution boundary.

## 2. Repository hygiene

- [x] 2.1 Read-only подтвердить exact target `skills/.DS_Store`, затем удалить только этот disposable artifact recoverable способом; проверить отсутствие файла и неизменность остальных skills.
- [x] 2.2 Проверить, что `.gitignore` покрывает `.DS_Store` независимо от nesting; при необходимости уточнить scoped ignore rule и проверить `git check-ignore skills/.DS_Store` на temporary path.
- [x] 2.3 Сохранить или усилить physical-tree validation в `erl-skills-check.zsh`; проверить primary negative fixtures и diagnostic с exact path.

## 3. Traceability and integration

- [x] 3.1 Добавить `ERL-GIT-004` в legacy requirements traceability и обновить engineering-safety references, если они распространяются вместе со skills; проверить поиск exact requirement ID.
- [x] 3.2 Запустить primary test, `erl-skills-check.zsh`, `tests/erl-skills-check.zsh` и `erl-all`; проверить отсутствие distribution-artifact blocker.
- [x] 3.3 Выполнить `zsh -n` для изменённых scripts/tests, `git diff --check`, protected-path audit и `openspec validate fix-skill-distribution-artifact-hygiene --strict`; проверить отсутствие syntax, whitespace, boundary и OpenSpec errors.
