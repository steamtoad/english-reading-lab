## 1. Primary regression contract

- [x] 1.1 Создать primary test `tests/erl-lexi-vault-confirmation-reporting.zsh`, проверяющий `ERL-AGENT-SETUP-010..011`; запустить test и получить PASS.
- [x] 1.2 Добавить positive fixtures с exact `Vault: ${ERL_HOME}`, отдельным confirmation, повторной проверкой path и same-Vault `erl-check`; проверить deterministic PASS.
- [x] 1.3 Добавить negative fixtures для отсутствующего Vault в plan, apply до confirmation, changed/symlinked Vault после confirmation, checker другого Vault и success report без path; проверить fail-closed diagnostics.

## 2. Confirmation и Vault identity

- [x] 2.1 Обновить общий agent contract и L2/L3 authorization policy: включить canonical Vault в pending plan и требовать отдельное явное подтверждение; проверить все семь reference copies static checker-ом.
- [x] 2.2 Реализовать pre-apply revalidation `${ERL_HOME}`, target markers, canonical path и plan binding в каждом mutating Lexi workflow; проверить, что drift invalidates confirmation и не вызывает `--apply`.
- [x] 2.3 Проверить Book ingest routing на плане с `Vault: /Users/steamtoad/pub/english-reading-lab`: до confirmation mutation отсутствует, после confirmation invocation содержит exact `--vault "${ERL_HOME}"`.

## 3. Post-mutation validation и reporting

- [x] 3.1 Обновить mutating skills так, чтобы после apply они запускали `${ERL_HOME}/.scripts/erl/erl-check.zsh --vault "${ERL_HOME}"` с widest changed scope; проверить Book ingest invocation с `--work "${WORK_ID}" --json`.
- [x] 3.2 Добавить обязательные поля фактического Vault, validation scope и checker result в итоговый Lexi report; проверить запрет success report при missing/failed/cross-Vault check.
- [x] 3.3 Проверить failure handoff после committed apply и неуспешного post-check: diagnostics сохраняют Vault/IDs, а mutation не повторяется автоматически.

## 4. Setup payload и существующий workspace

- [x] 4.1 Синхронизировать source contract, семь skill reference trees, Lexi runtime documentation и generated `TOOLS.md`; проверить exact wording и отсутствие пользовательского Zettelkasten path как target Vault.
- [x] 4.2 Обновить self-contained setup payload и выполнить `erl-openclaw-agent-setup.zsh --check-reference-skills "$PWD/skills"`; проверить byte-exact PASS.
- [x] 4.3 Проверить clean-room materialization и reviewed `--replace-managed --apply` fixture с backup/journal, затем setup `--check`; убедиться, что active runtime получает новый payload без изменения global OpenClaw config.

## 5. Requirements и финальные проверки

- [x] 5.1 Добавить `ERL-AGENT-SETUP-010..011` в legacy traceability и user/developer documentation; проверить unique exact ID occurrences и примеры с `${ERL_HOME}`.
- [x] 5.2 Подключить primary test к `tests/erl-all.zsh`, запустить focused skill/setup tests и полный non-live ERL suite; проверить отсутствие mutation пользовательского Vault.
- [x] 5.3 Выполнить optional live-routing test в изолированном fixture Vault, подтвердить plan и проверить, что apply/check/report используют один `${ERL_HOME}`; не использовать production user Vault.
- [x] 5.4 Выполнить `zsh -n`, `git diff --check`, protected-path audit, `openspec validate add-lexi-vault-confirmation-reporting --strict` и `openspec validate --all`; проверить отсутствие syntax, whitespace, boundary и specification errors.
