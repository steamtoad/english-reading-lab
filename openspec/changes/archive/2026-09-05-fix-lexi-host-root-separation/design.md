## Context

См. `proposal.md` — Why. ERL уже поддерживает separate host resolution через `ERL_HOST_HOME` либо `<vault>/.state/erl/host-contract.json`, однако существующий Lexi contract не валидирует semantic role каждого root. На текущей машине descriptor содержит пользовательский Vault как `host_root`, хотя canonical host implementation находится в отдельном development repository.

Изменение зависит от `ERL-AGENT-SETUP-009` активной дельты `add-lexi-vault-binding`: `${ERL_HOME}` сначала становится единственным Lexi Vault, после чего эта дельта закрепляет отдельный host implementation root и запрещённый user-data root.

## Goals / Non-Goals

**Goals:**

- сделать root roles явными, disjoint и проверяемыми до любой mutation;
- исправить текущий stale host contract через setup transaction;
- сохранить portable setup посредством explicit rendered local values;
- блокировать повторное появление пользовательского Vault в skills/payload/config.

**Non-Goals:**

- менять файлы или configuration внутри `/Users/steamtoad/zettelkasten`;
- переносить ошибочно созданный Friday work;
- изменять canonical host object constructors;
- превращать machine-specific paths в скрытый public CLI fallback.

## Decisions

### Three roots have distinct identities

Runtime рассматривает target Vault, host implementation и user Vault как три semantic roles, а не просто существующие directories. После canonicalization roots сравниваются между собой и проверяются по markers:

- target: ERL repository markers, root `notes/`, `.state/erl/`;
- host: executable `.scripts/objects/` contract;
- forbidden user root: explicit local deny value для текущего Lexi profile.

Альтернатива разрешить один checkout одновременно как host и Vault отклонена: она снова делает destination зависимым от места host scripts.

### ERL_HOST_HOME is explicit; descriptor mirrors effective local configuration

Для текущего Lexi profile setup renders `/Users/steamtoad/dev/zettelkasten-cli` как `ERL_HOST_HOME` и согласованный `host_root` descriptor под `${ERL_HOME}/.state/erl/`. Preflight требует, чтобы explicit environment/config и descriptor не противоречили друг другу.

Альтернатива полагаться только на environment отклонена: session/gateway restart может потерять env, после чего stale descriptor снова станет effective. Только descriptor без explicit profile также недостаточен для прозрачного setup dry-run/reporting.

### Machine paths are rendered inputs, not universal constants

Exact paths текущего deployment задаются setup defaults/profile и отражаются в generated local artifacts. Embedded portable logic принимает explicit `--workspace`/host-root input для другой машины и применяет те же role invariants.

Альтернатива встроить абсолютные пути во все tracked skills отклонена: это нарушает clean-room portability. Reference contracts описывают variables и запрет role substitution; exact local paths находятся в rendered `TOOLS.md`/descriptor/state.

### Host-contract repair joins the setup transaction

`.state/erl/host-contract.json` становится local managed artifact либо отдельным transaction participant setup. Dry-run классифицирует stale value как conflict. Replacement сохраняет bytes, journal и candidate validation до atomic publication; completion state публикуется последним.

Прямое редактирование descriptor отклонено, поскольку обходит уже существующий conflict/backup/rollback contract setup.

Primary regression test: `tests/erl-lexi-host-root-separation.zsh`.

## Risks / Trade-offs

- [Environment override расходится с descriptor] → fail closed с выводом обоих paths; не выбирать один молча.
- [Host development repository перемещён] → setup check блокирует mutation до explicit rerender/reapply local profile.
- [Existing setup state считает старый payload complete] → увеличить payload version/hash и требовать reviewed managed replacement.
- [User Vault содержит рабочие object constructors] → explicit deny rule всё равно блокирует его: наличие capability не меняет semantic role.
- [Пересечение трёх активных дельт] → реализовывать в порядке Vault binding → root separation → confirmation/reporting либо одним согласованным rollout, сохраняя отдельные IDs/tests.

## Migration Plan

1. Реализовать `ERL-AGENT-SETUP-009` и убедиться, что `${ERL_HOME}` равен ERL workspace.
2. Расширить setup inputs/rendering и root-role validator; не менять current descriptor на этом шаге.
3. Добавить negative fixtures для stale user-Vault host root, equal/swapped roots, env/descriptor drift и missing markers.
4. Обновить common contracts, семь skill references, local docs и embedded payload; пройти byte-exact synchronization.
5. Запустить setup dry-run текущего workspace и проверить plan замены `/Users/steamtoad/zettelkasten` на `/Users/steamtoad/dev/zettelkasten-cli`.
6. После отдельного reviewed consent выполнить replacement apply с backup/journal и post-check.
7. Запустить ERL Book ingest dry-run и checker с target `${ERL_HOME}`, доказав constructor resolution из `${ERL_HOST_HOME}` без обращения к user Vault.

Rollback восстанавливает exact прежний descriptor и managed files из setup transaction. После rollback Lexi mutation остаётся заблокированной forbidden-root validation, пока пользователь не применит корректный profile. User Vault и host repository не изменяются.
