## Context

`.gitignore` уже содержит `.DS_Store`, а `erl-skills-check.zsh` уже отклоняет такой artifact внутри skills tree. Текущая ошибка вызвана существующим untracked filesystem artifact, поэтому change должен восстановить чистое distribution состояние и закрепить наблюдаемую политику как `ERL-GIT-004`, не подменяя её одноразовой очисткой.

## Goals / Non-Goals

**Goals:**

- удалить только подтверждённый disposable metadata artifact;
- сохранить preventive ignore и negative validation;
- добавить primary regression test `tests/erl-skill-distribution-artifact-hygiene.zsh` для clean и injected-artifact cases.

**Non-Goals:**

- удалять неизвестные hidden files по широкому glob;
- очищать пользовательские directories вне ERL repository;
- менять skill content или installation layout.

## Decisions

### Удаление точно адресовано и recoverable до завершения implementation

Implementation удаляет только `skills/.DS_Store`, предварительно подтверждая path и тип. Альтернатива с recursive hidden-file cleanup отклонена как потенциально destructive: hidden files могут быть частью source contract.

### Ignore и validation выполняют разные функции

Ignore policy предотвращает случайное добавление локального artifact в Git, а distribution checker обнаруживает artifact, физически попавший в собираемое дерево. Сохраняются оба слоя; ослабление checker на основании `.gitignore` отклонено, поскольку packaging может включить ignored files.

### Regression использует изолированный fixture

Primary test создаёт disposable skills fixture с `.DS_Store`, подтверждает diagnostic с exact path, затем проверяет clean fixture и существующие forbidden installation artifacts. Production skills tree в negative test не мутируется.

## Risks / Trade-offs

- [Ignored artifact всё ещё может попасть в filesystem-based package] → distribution validation проверяет физическое дерево независимо от Git tracking.
- [Широкое правило может отклонить legitimate hidden source] → нормативный и initial implementation scope ограничены известными platform/editor metadata artifacts.
- [Удаление может затронуть пользовательские данные] → target ограничен disposable `skills/.DS_Store` внутри ERL repository; Vault и external directories исключены.

## Migration Plan

1. Убедиться, что target является `skills/.DS_Store`, и удалить его recoverable способом.
2. Проверить/сохранить repository ignore policy.
3. Добавить primary fixture regression и legacy traceability `ERL-GIT-004`.
4. Запустить distribution checker и `erl-all`.

Rollback может восстановить artifact из recoverable deletion до завершения work, но artifact не является source data и не должен возвращаться в committed distribution.
