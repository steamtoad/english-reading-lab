## Context

Текущий Lexi workspace уже содержит полезную конфигурацию и семь skills, но весь набор исключён root `.gitignore`. Из fresh checkout нельзя восстановить точные files, их references и safety posture. При этом часть содержимого зависит от машины и пользователя, а `openclaw-workspace-state.json` содержит runtime completion time.

Setup меняет local workspace infrastructure, а не ERL Vault/state и не global OpenClaw installation. Поэтому требуется отдельная transaction boundary и явный apply contract.

## Goals / Non-Goals

**Goals:**

- хранить весь воспроизводимый Lexi payload в одном tracked executable;
- разворачивать и проверять полный ignored artifact set;
- поддерживать portable profile rendering без repository-local secrets;
- безопасно reconciliate уже существующий workspace.

**Non-Goals:**

- устанавливать OpenClaw binary или model provider credentials;
- изменять `~/.openclaw` configuration, регистрировать agent/channel bindings или запускать daemon;
- переносить session history, memory или runtime credentials;
- изменять Vault documents, `.state/erl/works/` либо host core.

## Decisions

### One tracked self-contained executable owns the payload

Primary executable: `.scripts/erl/dev/erl-openclaw-agent-setup.zsh`. Static files и skill tree хранятся внутри него как deterministic embedded archive/manifest; generated values render через ограниченные named placeholders. Отдельная ignored directory не является build input. Альтернатива с tracked templates отклонена, поскольку пользовательское требование прямо задаёт перенос всей ignored agent infrastructure в script.

Primary regression test, выведенный из change name: `tests/erl-openclaw-agent-setup.zsh`.

### Rendered manifest separates static and local values

Static payload включает Lexi identity, soul, heartbeat policy, runtime documentation, skills и references. `--workspace`, `--user-name` и `--timezone` формируют local fields `TOOLS.md`/`USER.md`. Completion timestamp вычисляется при successful apply. Manifest содержит relative path, mode и SHA-256 rendered bytes; абсолютные paths никогда не используются как archive member names.

### Plan precedes any mutation

Script сначала render'ит payload в private temporary staging directory, проверяет path containment, file modes, duplicate paths, archive safety, skills и hashes, затем строит create/keep/conflict plan. Default invocation является dry-run; mutation требует `--apply`. `--check` валидирует existing workspace без staging commit.

### Replacement is an explicit transaction

При любом conflict default apply прекращается до первой target mutation. Отдельный `--replace-managed --apply` разрешает заменить только paths из expected manifest после backup. Unknown paths, включая дополнительные user skills, не удаляются. Все replacements/creates журналируются; commit использует atomic rename per file, а failure запускает reverse rollback. Completed state записывается последним.

### Setup does not register OpenClaw globally

Script materializes workspace contract и выдаёт post-setup instructions/smoke-test command. Global agent registration и bindings остаются внешней административной операцией, поскольку требуют machine-specific authority и могут затронуть другие agents. Это также предотвращает попадание global credentials/config в payload.

## Risks / Trade-offs

- [Embedded skill payload делает script большим] → deterministic manifest/hash и extraction test контролируют drift; единый artifact соответствует требуемой portability.
- [Local edits конфликтуют с новой payload version] → dry-run показывает exact conflicts; explicit replacement всегда создаёт backup.
- [Archive extraction позволяет path traversal] → разрешены только normalized repository-relative paths из fixed manifest; absolute paths, `..`, symlinks и special files отклоняются.
- [Secrets случайно попадают в payload] → static negative scan и fixture запрещают token/config/session patterns; profile поддерживает только allowlisted values.
- [Failure оставляет частичную инфраструктуру] → prevalidated staging, journal, reverse rollback и completion marker last.

## Migration Plan

1. Создать `tests/erl-openclaw-agent-setup.zsh`, проверяющий fresh dry-run/apply/check, exact artifact set, ignored status и idempotency.
2. Добавить negative fixtures для conflict, replacement backup, injected failure/rollback, unsafe archive path, prohibited artifact и secret-like payload.
3. Реализовать self-contained setup executable и embedded versioned payload текущего Lexi workspace.
4. Подключить existing `erl-skills-check.zsh` к extracted candidate tree и добавить setup payload drift check.
5. Обновить `.scripts/erl/docs/requirements.md`, CLI/developer documentation и `tests/erl-all.zsh`.
6. На существующем workspace сначала выполнить dry-run/check; затем explicit apply или reviewed `--replace-managed --apply`.
7. Выполнить Lexi routing smoke test только после local integrity check; global registration остаётся отдельной ручной процедурой.

Rollback восстанавливает exact backed-up files и удаляет только files, созданные текущей незавершённой transaction. Existing unknown files не затрагиваются. Изменения `.gitignore` и persistent ERL state не требуются.
