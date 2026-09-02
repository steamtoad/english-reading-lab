## Context

См. `proposal.md` — Why. Текущий authorization policy требует L2/L3 confirmation, но не делает Vault identity обязательной частью показываемого и повторно проверяемого плана. Семь skills используют общий derived agent contract, который также входит в self-contained setup payload и должен совпадать с reference skill tree.

Изменение дополняет активную дельту `add-lexi-vault-binding`: та определяет выбор `${ERL_HOME}` как Vault, а эта дельта определяет proof перед mutation и после неё. Public CLI уже принимает explicit `--vault`; новый option или state schema не требуются.

## Goals / Non-Goals

**Goals:**

- связать L2/L3 consent с canonical Vault identity и конкретным dry-run plan;
- закрыть time-of-check/time-of-use окно между подтверждением и `--apply`;
- доказать postcondition в том же Vault и сделать path видимым в success report;
- распространить одинаковое правило через все reference skills и setup payload.

**Non-Goals:**

- менять L0/L1 authorization semantics;
- добавлять interactive confirmation внутрь public ERL CLI;
- автоматически переносить или удалять ранее созданные документы другого Vault;
- изменять host core, global OpenClaw config или session lifecycle.

## Decisions

### Vault identity is part of the confirmed plan

Lexi сохраняет для pending confirmation canonical absolute Vault path вместе с plan fingerprint и semantic scope. Пользователю показывается отдельная строка `Vault: <absolute-path>`; подразумеваемого workspace/cwd недостаточно.

Альтернатива показывать только command отклонена: длинная invocation легко скрывает ошибочный path и не задаёт стабильный user-facing confirmation field.

### Revalidation fails closed

После confirmation Lexi заново разрешает `${ERL_HOME}`, canonicalizes path, проверяет repository/target-home markers и сравнивает path с pending plan до запуска `--apply`. Любое отличие invalidates consent и требует нового dry-run.

Альтернатива автоматически заменить `--vault` актуальным `${ERL_HOME}` отклонена: тогда применяется не тот plan, который видел пользователь.

### Post-check reuses the applied identity and widest changed scope

Apply result определяет scope проверки. Для Book ingest используется `--work "${WORK_ID}"`; для generation-oriented workflows — generation или более широкий поддерживаемый scope. Во всех случаях executable и `--vault` выводятся из одного повторно проверенного `${ERL_HOME}`.

Успех состоит из apply и successful post-check. Если checker отсутствует, использует другой Vault или возвращает failure, mutation не повторяется автоматически, а отчёт остаётся validation failure.

### Contract is distributed through the existing setup mechanism

Source agent contract и authorization policy синхронизируются во всех семи skills, после чего embedded setup payload пересобирается и byte-exact сверяется. Existing managed workspace обновляется только через `--replace-managed --apply` с backup/journal.

Отдельное изменение global OpenClaw skill registry отклонено как выходящее за ERL boundary; Lexi должна использовать materialized workspace-local payload.

Primary regression test: `tests/erl-lexi-vault-confirmation-reporting.zsh`.

## Risks / Trade-offs

- [Path меняется через symlink между plan и apply] → canonicalize и повторно проверить identity непосредственно перед mutation; fail closed.
- [Текстовое подтверждение относится к старому plan] → хранить только один pending plan и invalidation при любом новом dry-run или Vault drift.
- [Apply успешен, post-check неуспешен] → не повторять mutation; показать фактический Vault, IDs и checker diagnostics для безопасного recovery.
- [Одна reference copy или embedded payload остаётся старой] → static all-seven check и byte-exact payload/reference gate.
- [Дельта пересекается с `add-lexi-vault-binding`] → реализовывать после либо совместно с `ERL-AGENT-SETUP-009`, сохраняя разные requirement IDs и primary tests.

## Migration Plan

1. Реализовать либо подтвердить `ERL-AGENT-SETUP-009` как prerequisite выбора Vault.
2. Обновить общий agent/authorization contract и reference copies семи skills.
3. Добавить static и behavioral fixtures для confirmation, drift rejection, same-Vault post-check и final report.
4. Пересобрать embedded setup payload и пройти byte-exact reference comparison.
5. Выполнить reviewed setup replacement существующего Lexi workspace с backup/journal.
6. Выполнить non-mutating/live-routing test до реального L2 apply.

Rollback восстанавливает предыдущий managed payload через setup backup/journal. Vault documents и persistent work state автоматически не изменяются; неуспешный post-check переводит workflow в diagnostic/recovery handoff, а не запускает rollback уже committed domain mutation без отдельного контракта.
