## Why

ERL сейчас разрешает runtime path через искусственный каталог `vault/` и тем самым записывает canonical documents и state в `vault/notes/` и `vault/.state/erl/`. Это расходится с canonical Zettelkasten layout, где `notes/` и `.state/` являются непосредственными дочерними каталогами target Zettelkasten home.

## What Changes

- Ввести однозначное понятие target Zettelkasten home, отдельное от ERL source root и host implementation root.
- Требовать размещения Topic, Note и Memo в `<ZETTELKASTEN_HOME>/notes/` через canonical host object constructors.
- Требовать размещения ERL state в `<ZETTELKASTEN_HOME>/.state/erl/`.
- Запретить production runtime создавать или использовать дополнительный промежуточный каталог `vault/`.
- **BREAKING**: legacy layout `<root>/vault/{notes,.state/erl}` перестаёт быть допустимым production layout и требует explicit migration.
- Сохранить существующий CLI spelling `--vault` как compatibility input, но определить его значение как сам target Zettelkasten home, а не его родитель.
- Зафиксировать обязательное имя primary regression test, производное от имени delta-spec: `fix-target-home-layout` → `erl-target-home-layout.zsh`.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `architecture-boundary`: разделить ERL source root, host implementation root и target Zettelkasten home.
- `vault-integration`: определить canonical document namespace как `<ZETTELKASTEN_HOME>/notes/` и запретить промежуточный `vault/`.
- `persistent-state`: привязать единый `.state/erl/` к target Zettelkasten home.
- `validation`: проверять canonical home layout и диагностировать legacy nested layout.
- `source-content-safety`: определить staging и works paths относительно target Zettelkasten home.
- `engineering-safety`: потребовать deterministic связь имени OpenSpec change и primary regression test.

## Impact

- Затронуты path resolution и все ERL commands, которые читают или изменяют documents, works, staging, transactions, cache и locks.
- Потребуются изменения CLI contract, fixtures, skills Lexi и regression tests.
- ERL change validation будет требовать `tests/erl-<behavior-slug>.zsh`, где leading change-kind prefix заменён project prefix `erl-`.
- Существующие данные в nested `vault/` нельзя переносить неявно: потребуется отдельная dry-run/apply migration с collision checks, journal, rollback и recovery.
- Host core не изменяется. ERL продолжает разрешать canonical constructors через host contract; отсутствие нужной host capability остаётся explicit contract gap.
