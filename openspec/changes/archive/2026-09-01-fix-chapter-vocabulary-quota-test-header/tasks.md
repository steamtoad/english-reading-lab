## 1. Focused regression contract

- [x] 1.1 Создать primary test `tests/erl-chapter-vocabulary-quota-test-header.zsh`, проверяющий exact пятистрочный header целевого файла и воспроизводящий текущий `ERL-SHELL-005` failure до исправления.
- [x] 1.2 В primary test запускать `tests/erl-chapter-vocabulary-quota.zsh` и проверить, что исходные `ERL-CAND-010` assertions и successful exit сохраняются.

## 2. Header conformance

- [x] 2.1 Добавить после shebang в `tests/erl-chapter-vocabulary-quota.zsh` opening/closing separators, полное имя файла и непустые индивидуальные поля `Тип`/`Назначение`; проверить primary test.
- [x] 2.2 Убедиться, что executable body quota test не изменён содержательно; проверить focused diff и прямой запуск исходного test.

## 3. Integration verification

- [x] 3.1 Запустить `erl-skills-check.zsh`, `tests/erl-skills-check.zsh` и primary test; проверить отсутствие header diagnostics для целевого файла.
- [x] 3.2 Запустить `zsh -n` для изменённых scripts, `git diff --check`, protected-path audit, `openspec validate fix-chapter-vocabulary-quota-test-header --strict` и `erl-all`; проверить, что header blocker устранён и remaining failures, если есть, не относятся к этой change.
