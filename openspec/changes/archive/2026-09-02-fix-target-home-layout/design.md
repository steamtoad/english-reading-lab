## Context

См. `proposal.md` — Why. Сейчас один аргумент `vault` одновременно обозначает runtime destination и используется для поиска host descriptor; все document/state paths строятся как `$vault/notes` и `$vault/.state/erl`. Требуется сохранить host contract boundary и изменить только ERL-owned implementation.

## Goals / Non-Goals

**Goals:**

- разделить ERL source root, host implementation root и target Zettelkasten home;
- сделать `notes/` и `.state/` непосредственными дочерними каталогами target home;
- обеспечить безопасную explicit migration legacy nested layout;
- сохранить canonical Topic/Note/Memo constructors и существующие identity/state semantics.

**Non-Goals:**

- изменение host core или его object constructors;
- перенос книг или изменение ERL domain model;
- неявная миграция пользовательских данных;
- переименование публичных CLI flags в рамках этой feature.

## Decisions

### 1. Три независимых корня

Использовать три понятия: `ERL_HOME` для исходников plugin, `ERL_HOST_HOME` для host implementation contract и `<ZETTELKASTEN_HOME>` для production data. Не выводить один корень из другого.

Альтернатива — считать host source repository одновременно runtime home — отклонена: это смешивает production code и user data и нарушает `ERL-ARCH-009`.

### 2. `--vault` временно означает target Zettelkasten home

Сохранить существующий spelling CLI для совместимости, но resolver обязан трактовать значение как каталог, непосредственно содержащий `notes/` и `.state/`. В документации и внутренних именах использовать `zettelkasten_home`/`target_home`, чтобы не сохранять двусмысленность.

Альтернатива — немедленно заменить flag на `--home` — отклонена как лишний CLI breaking change. Отдельная rename/deprecation feature может быть предложена позднее.

### 3. Один path resolver

Все commands должны получать canonical document и state roots через общий ERL-local resolver. Resolver валидирует target home и не выполняет nested fallback. Host implementation продолжает разрешаться отдельным host-contract resolver.

### 4. Legacy layout мигрируется отдельной operation

Добавить ERL-local migration с dry-run и explicit apply. План включает source/target paths, hashes и collision classification. Apply создаёт journal до первой mutation; каждая операция записывается так, чтобы recovery мог продолжить или rollback мог вернуть только неизменённые migration artifacts.

Использование `cp`/`mv` без journal отклонено из-за риска частичной migration и перезаписи пользовательских данных.

### 5. Fixtures моделируют target home, но не production fallback

Test host doubles остаются в `fixtures/host-contract`, а runtime fixture home создаётся отдельно с `notes/` и `.state/` в корне. Production resolver не знает fixture paths.

### 6. Primary regression test выводится из имени change

Для каждого ERL OpenSpec change вычислять behavioral slug удалением одного leading change-kind prefix из множества `fix-`, `add-`, `change-`, `update-`, `migrate-`, `refactor-`, `implement-`. Primary regression test MUST называться `tests/erl-<behavior-slug>.zsh`.

Для `fix-target-home-layout` canonical test — `tests/erl-target-home-layout.zsh`. Дополнительные focused tests разрешены, но не заменяют primary regression test.

Альтернатива — хранить произвольное имя теста только в `tasks.md` — отклонена: такая связь не проверяется автоматически и теряется после archive change.

## Risks / Trade-offs

- **[Existing automation passes parent of `vault/`]** → diagnostic показывает новое значение argument и запрещает mutation до исправления invocation.
- **[Legacy и canonical paths существуют одновременно]** → migration dry-run классифицирует collision и запрещает apply.
- **[Host constructor имеет собственное понимание destination]** → проверить contract до mutation; при несовместимости зафиксировать `HOST_CONTRACT_UNAVAILABLE`, не патчить host.
- **[Cross-filesystem move не atomic]** → staged copy, hash verification, journaled switch и recoverable cleanup.
- **[Change name содержит неизвестный action prefix]** → считать полное имя behavioral slug и только добавить project prefix; не угадывать новые глаголы молча.

## Migration Plan

1. Выпустить read-only detection и новый target-home resolver.
2. Добавить migration dry-run и collision tests.
3. Добавить journaled apply/recovery/rollback.
4. Перевести mutation commands на canonical resolver.
5. Обновить CLI contract и skills Lexi.
6. Для каждого legacy home выполнить dry-run, разрешить collisions и только затем explicit apply.

Rollback использует journal и pre-mutation hashes. Неожиданно изменённый target не перезаписывается; operation останавливается с conflict diagnostic.
