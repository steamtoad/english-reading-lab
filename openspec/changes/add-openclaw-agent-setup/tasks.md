## 1. Регрессионный контракт

- [ ] 1.1 Создать primary test `tests/erl-openclaw-agent-setup.zsh` для fresh dry-run, apply, check и повторного apply; проверить exact managed artifact set, hashes, ignored status и неизменные mtimes при idempotent run.
- [ ] 1.2 Добавить negative fixtures для existing-file conflict, explicit replacement backup, injected mid-commit failure, unsafe archive path, duplicate path, prohibited distribution artifact и secret-like payload; проверить отказ до mutation либо exact rollback.

## 2. Self-contained payload

- [ ] 2.1 Добавить tracked executable `.scripts/erl/dev/erl-openclaw-agent-setup.zsh` с embedded versioned payload всех root agent files, `.scripts/erl/docs/lexi-agent.md` и полного дерева семи runtime skills; проверить extraction в empty fixture без доступа к ignored source files.
- [ ] 2.2 Добавить deterministic manifest с normalized relative paths, modes и SHA-256 rendered bytes; проверить rejection absolute paths, `..`, symlinks, special files и duplicate entries.
- [ ] 2.3 Реализовать allowlisted rendering `--workspace`, `--user-name` и `--timezone`, а также generation completion timestamp/state; проверить portable `TOOLS.md`/`USER.md` и отсутствие secrets/global OpenClaw config в payload.

## 3. Planning и validation modes

- [ ] 3.1 Реализовать default non-mutating dry-run с create/keep/conflict plan, target root и payload version/hash; проверить byte-for-byte неизменность target fixture.
- [ ] 3.2 Реализовать non-mutating `--check` для manifest/hashes, exact seven-skill set, references, Git ignore и Lexi safety/tool policy; проверить clean success и конкретные drift diagnostics.
- [ ] 3.3 Подключить extracted candidate tree к `.scripts/erl/dev/erl-skills-check.zsh` и добавить payload drift/static secret scan; проверить existing skill checker и новые negative fixtures.

## 4. Apply и recovery

- [ ] 4.1 Реализовать explicit `--apply` из prevalidated private staging с atomic file publication и completion marker last; проверить fresh setup и отсутствие partial completed state.
- [ ] 4.2 Реализовать conflict preflight и `--replace-managed --apply` только для manifest paths с backups/journal; проверить сохранение unknown skills/files и local edit без replace consent.
- [ ] 4.3 Реализовать reverse rollback и recovery-required diagnostic для interrupted replacement; проверить exact pre-apply bytes и удаление только files текущей незавершённой transaction.

## 5. Контракты и итоговая проверка

- [ ] 5.1 Обновить `.scripts/erl/docs/requirements.md`, CLI/developer documentation и setup usage для `ERL-AGENT-SETUP-001..007`; проверить traceability всех IDs и явное исключение global registration/credentials.
- [ ] 5.2 Подключить primary test к `tests/erl-all.zsh` и запустить setup, skills-check и agent-routing static suites; проверить успешное завершение всех non-live tests.
- [ ] 5.3 Выполнить `zsh -n` для setup/изменённых Zsh files, `git diff --check`, protected-path review и `openspec validate --all`; проверить отсутствие syntax, whitespace, repository-boundary и OpenSpec errors.
