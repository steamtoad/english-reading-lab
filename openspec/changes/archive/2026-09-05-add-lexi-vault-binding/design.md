## Context

Lexi уже разрешает repository root как `ERL_HOME`, а public ERL CLI требует explicit `--vault` либо отдельное target-home resolution. Эти две identity ранее не были связаны нормативно, поэтому semantic orchestration могло выбрать другой доступный Zettelkasten checkout. Одновременно ERL repository не содержит production host core и должен разрешать canonical object constructors через отдельный host contract.

Изменение пересекает семь ignored runtime skills, общий derived contract, tracked setup payload и validation tooling. Оно не изменяет public CLI semantics и не переносит существующие Vault data.

## Goals / Non-Goals

**Goals:**

- сделать target Vault Lexi детерминированным после resolution `ERL_HOME`;
- сохранить separation target Vault и host implementation root;
- обнаруживать drift правила во всех семи skills и embedded payload;
- подтвердить реальным dry-run, что work state планируется внутри ERL workspace.

**Non-Goals:**

- запрещать пользователю public CLI запускать ERL с другим explicit `--vault`;
- копировать или переносить документы/state из прежнего пользовательского Vault;
- встраивать machine-specific host path в versioned skill payload;
- изменять host object constructors либо Classic Zettelkasten.

## Decisions

### ERL_HOME is the single Lexi target-home identity

После repository resolution skill использует то же absolute значение для executable prefix и `--vault`. Это исключает второй независимый inference step и делает план проверяемым по command arguments и `work_state_path`.

Альтернатива с отдельным `LEXI_VAULT` отклонена: она сохраняет два расходящихся источника identity. Поддержка arbitrary `--vault` остаётся на уровне прямого public CLI, но не Lexi orchestration.

### One common contract is copied into every skill

Normative operational wording хранится в source agent contract и byte-exact reference copies каждого skill. Static checker проверяет обязательную строку для каждого skill, а setup synchronization гарантирует совпадение embedded payload с reference tree.

Только `TOOLS.md` недостаточен: это local context, но не обязательная procedure каждого skill. Дублировать различающуюся формулировку вручную в семи `SKILL.md` также не требуется, поскольку каждый skill обязан загрузить common reference до выполнения.

### Target Vault and host root remain separate

`--vault "${ERL_HOME}"` определяет место `notes/` и `.state/erl/`. Canonical object constructor разрешается через `${ERL_HOME}/.state/erl/host-contract.json` либо `ERL_HOST_HOME`; resolved host root не передаётся как Vault.

Repository-local production fallback отклонён архитектурной boundary. Machine-specific host descriptor остаётся ignored local configuration и не входит в portable embedded payload.

### Functional proof uses non-mutating invocation

Primary regression проверяет generated `TOOLS.md`, все seven reference contracts, static checker и embedded payload. Focused integration запускает Book ingest `--dry-run --json` с ERL workspace как Vault и требует, чтобы `work_state_path` находился под `${ERL_HOME}/.state/erl/works/`.

Primary regression test, выведенный из change name: `tests/erl-lexi-vault-binding.zsh`.

## Risks / Trade-offs

- [В старом Vault уже есть созданный work] → изменение не переносит и не удаляет data; пользователь отдельно выбирает migration/re-ingest strategy.
- [ERL workspace не имеет host constructors] → explicit local host contract разрешает отдельный host root, не меняя target Vault.
- [Reference skills обновлены без payload refresh] → byte-exact setup synchronization и archive preflight блокируют completion.
- [Локальный `TOOLS.md` расходится с новым payload] → setup dry-run показывает conflict; reviewed `--replace-managed --apply` создаёт backup и journal.
- [Functional test случайно создаёт documents] → integration использует только `--dry-run`, сравнивает pre/post filesystem state и не выполняет L2 apply.

## Migration Plan

1. Обновить source agent contract и синхронизировать семь reference copies.
2. Расширить static checker и primary regression для exact Vault binding.
3. Обновить generated `TOOLS.md`, Lexi runtime documentation и embedded setup payload.
4. Добавить `/notes/` в local/generated ignore contract и подготовить ignored target-home directories/configuration без изменения `works/`.
5. Выполнить setup dry-run, затем reviewed replacement apply для существующего workspace.
6. Запустить Book ingest dry-run и `erl-check` с `--vault "${ERL_HOME}"`, затем полный non-live suite и optional live routing.

Rollback восстанавливает agent files из setup journal/backup и предыдущую payload version. Созданные пользователем Vault documents или work state не затрагиваются автоматически; host core не изменяется.
