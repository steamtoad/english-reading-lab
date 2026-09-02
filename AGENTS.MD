# AGENTS.md

# English Reading Lab — Agent Instructions

Этот repository содержит English Reading Lab (ERL) plugin, его skills, scripts, tests, fixtures и документацию.

Нормативный baseline требований: `openspec/specs/*/spec.md`.

`.scripts/erl/docs/requirements.md` сохраняется как legacy traceability source.
При расхождении implementation сверяется с OpenSpec; изменение baseline
выполняется через OpenSpec workflow и `openspec validate --all`.

OpenSpec archive допускается только после successful preflight:

```text
.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change CHANGE_NAME
```

После `openspec archive` обязательно выполнить postcondition check с exact
archive path. Current requirements всегда читаются только из `openspec/specs/`;
active и archived deltas служат change planning/history и не заменяют baseline.

Локальная ignored Lexi infrastructure разворачивается и проверяется только через
`.scripts/erl/dev/erl-openclaw-agent-setup.zsh`. Default invocation является
dry-run; mutation требует `--apply`, а managed replacement — отдельного
`--replace-managed`. Setup не даёт полномочий изменять global OpenClaw config,
credentials, agent registration или external bindings.
Перед completion/archive change `add-openclaw-agent-setup` выполнить byte-exact
сверку embedded payload с текущими reference skills через
`erl-openclaw-agent-setup.zsh --check-reference-skills "$PWD/skills"`.

Главная архитектурная граница:

```text
Zettelkasten Vault = storage/object contracts
Classic Zettelkasten = host workflow
English Reading Lab = отдельный plugin/domain workflow
```

ERL адаптируется к Vault. ERL-specific semantics не должны протекать в canonical AsciiDoc metadata или core implementation.

Lexi local runtime использует разделённые roots:

```text
ERL_HOME=/Users/steamtoad/pub/english-reading-lab
ERL_HOST_HOME=/Users/steamtoad/dev/zettelkasten-cli
forbidden user Vault=/Users/steamtoad/zettelkasten
```

Пользовательский Vault не является ни Lexi target, ни ERL host implementation.
Каждый из семи Lexi runtime skills передаёт каждому ERL CLI invocation exact
`--vault "${ERL_HOME}"`; это правило применяется также к dry-run и post-check.

---

## 1. Repository write boundary

Implementation agent, включая Marta, изменяет только ERL repository.

Допустимые области:

```text
.scripts/erl/
skills/
templates/
tests/
fixtures/
docs/
.scripts/erl/docs/requirements.md
README.MD
AGENTS.MD
ERL-local state/schema tooling
```

Не изменять host repository в рамках обычной ERL task:

```text
.scripts/lib/
.scripts/objects/
.scripts/zettelkasten/
zcreate
zt-check
user Vault documents
```

Если host API недостаточен, оформить contract gap. Не патчить core автоматически.

---

## 2. Dependency rules

Runtime ERL implementation может использовать:

```text
erl/     -> objects/
erl/     -> lib/
objects/ -> lib/
```

Не source implementation:

```text
erl/          -> zettelkasten/
zettelkasten/ -> erl/
objects/      -> erl/
lib/          -> erl/
```

`zcreate` не является plugin object API.

Classic commands, включая `zt-reduce`, могут использоваться пользователем как поддерживаемые host workflows над ERL documents. Это не делает `.scripts/zettelkasten/` ERL dependency.

---

## 3. Layer responsibilities

```text
Skill
    semantic decision / orchestration

.scripts/erl/
    deterministic ERL domain operation

Host .scripts/objects/
    canonical Topic/Note/Memo construction

Host .scripts/lib/
    domain-neutral primitive
```

Host contract разрешается через target host/Vault и не хранится как production
implementation в ERL repository. Repository-local host fallback запрещён;
test doubles допустимы только под явно test-scoped `fixtures/`.

Не дублировать canonical object construction внутри ERL.

---

## 4. Canonical Vault documents

ERL создаёт только стандартные Vault objects:

```text
Book        = Topic
Chapter     = Note
Vocabulary  = Memo
Occurrence  = Memo
```

Каждый persistent document:

* является AsciiDoc;
* хранится как `UUID.adoc`;
* использует UUID как identity/filename/link target;
* использует canonical links `link:UUID.adoc[Description]`;
* использует только host-defined attributes.

### Strict rule: no ERL AsciiDoc attributes

Не создавать:

```text
:erl-kind:
:erl-work-id:
:erl-book:
:erl-chapter:
:erl-sequence:
:erl-...:
```

Не использовать `:key-topic:` как скрытый ERL foreign key.

ERL role определяется через persistent work state + canonical `:type:` + structural body contract.

---

## 5. ERL state layout

ERL state namespace:

```text
.state/
└── erl/
    ├── works/              # PERSISTENT domain state
    │   └── <work-slug>/
    │       ├── work.json
    │       ├── sources/
    │       └── generations/
    ├── staging/            # intermediate model output
    ├── transactions/       # Reduce/recovery journal
    ├── cache/              # rebuildable
    └── locks/              # runtime
```

Критическое правило:

```text
Vault documents + .state/erl/works/
= ERL source of truth
```

`.state/erl/works/` не disposable. Не выполнять `rm -rf .state` как обычную очистку.

Очищаемые runtime области должны быть адресованы явно (`cache/`, допустимый staging, завершённые transaction artifacts и т.п.).

`<work-slug>` — human-readable path locator, не identity.

Persistent Work State Contract v1 использует UTF-8 JSON. `WORK_ID`, `SOURCE_ID`,
`EXTRACTION_ID` и `TXID` — ERL-local lowercase UUID v4; Vault document UUID
по-прежнему создаётся host constructor как UUID v1.

---

## 6. Work and Book generation

Logical work имеет stable opaque `WORK_ID`, который существует только в `.state/erl/works/`.

```text
WORK_ID
    -> sources
    -> durable Chapter UUID mappings
    -> Book Topic generation UUIDs
```

Book — canonical Topic.

```text
Book Topic UUID = semantic generation identity
```

Для одного WORK_ID — не более одной active generation.

Новая semantic policy создаёт новый Book Topic UUID после Reduce.

Не записывать WORK_ID в Topic attributes.

---

## 7. Chapter identity

Chapter — canonical Note и durable source entity.

Chapter UUID сохраняется между Book generations.

Source state хранит:

```text
WORK_ID
SOURCE_ID
source fingerprint
CHAPTER_LOCATOR
source order
Chapter UUID
```

Resolution key:

```text
WORK_ID × SOURCE_ID × CHAPTER_LOCATOR
```

Для EPUB первая версия:

```text
fingerprint = SHA-256 source EPUB
preferred locator = canonical package-relative content href
```

Обычный `erl-book-reduce` не deprecated'ит durable Chapter Note.

---

## 8. Incremental processing

Default processing unit — Chapter.

```text
processing scope
= active Book Topic UUID × Chapter UUID
```

Нормальный workflow:

```text
Chapter 1 -> extract -> ingest
Chapter 2 -> extract -> ingest
Chapter 3 -> extract -> ingest
```

Не требовать whole-book model context.

Если Chapter слишком велика, extraction может использовать segments. Segments не становятся Vault entities.

---

## 9. Extraction and staging

Основной skill:

```text
erl-chapter-vocabulary-extract
```

Extraction:

* работает в source order;
* не создаёт Vault documents;
* не вызывает object constructors;
* не вызывает `zcreate`;
* пишет Candidates в `.state/erl/staging/`.

Extraction batch должен иметь `EXTRACTION_ID`, generation UUID, Chapter UUID и policy identity.

Candidate содержит lexical metadata, source order и context.

Один Candidate по умолчанию соответствует lexical item на первом relevant occurrence внутри текущей Chapter.

Один `EXTRACTION_ID` нельзя ingest дважды. Completed ingestion receipt хранится в persistent work state.

Материальное изменение extraction/card/lexical policy после ingestion = новая semantic generation, а не silent overwrite.

---

## 10. Vocabulary Memo

Vocabulary — canonical Memo.

Vocabulary не имеет ERL attributes.

Role `vocabulary` хранится в persistent generation/work state и проверяется по structural card contract.

Минимум:

```asciidoc
== Lexical identity

Lemma:: forlorn
POS:: adjective
Lexical type:: word
```

Canonical lexical identity:

```text
normalized lemma + normalized POS + normalized lexical type
```

Vocabulary является global active canonical lexical knowledge.

Vocabulary принадлежит generation первого приобретения через persistent state.

Deprecated Vocabulary не участвует в active lookup/deduplication.

---

## 11. Occurrence Memo

Occurrence — canonical Memo.

Минимальный structural contract:

```asciidoc
== Vocabulary

link:VOCABULARY-UUID.adoc[Description]

== Context

...
```

Occurrence создаётся вместо нового Vocabulary, если active canonical Vocabulary уже существует.

Occurrence является самостоятельным reading-sequence node.

Новый Occurrence не должен ссылаться на deprecated Vocabulary.

---

## 12. Persistent work-state contract

`.state/erl/works/<work-slug>/` хранит минимум:

```text
WORK_ID
logical metadata
source records
Chapter UUID mapping
retained Book generation UUIDs
active generation
processing policy identity
generation members
reading sequence
ingestion receipts
Reduce/dependency metadata
```

State record не должен ссылаться на отсутствующий UUID без explicit historical/tombstone semantics.

Изменение schema works/ требует versioning/migration plan.

---

## 13. Ingestion

```text
erl-vocabulary-ingest
    one Candidate -> Vocabulary Memo | Occurrence Memo

erl-chapter-vocabulary-ingest
    Chapter staging -> ordered documents + work-state entries
```

Persistent Vault object создаётся только через canonical object constructor.

Document creation + persistent work-state update должны быть recoverable.

Повторная ingestion completed `EXTRACTION_ID` не должна создавать duplicates.

---

## 14. Reading sequence

Vocabulary и Occurrence — равноправные sequence nodes.

Sequence принадлежит Book generation и хранится в `.state/erl/works/`, не в document attributes.

Каждая sequence entry содержит минимум:

```text
ordinal
Chapter UUID
role
Vault document UUID
```

Следующая Chapter продолжает active generation sequence.

Deprecated documents исключаются из active sequence. После committed
`erl-book-reduce` generation sequence и membership удаляются из `works/`;
audit сохраняется в compact committed transaction manifest/result.

---

## 15. Deprecated

ERL использует host `:deprecated:` semantics.

Не вводить отдельный ERL archive flag.

Deprecated documents:

* не участвуют в active lookup/deduplication;
* не получают новых ERL hard dependencies;
* не входят в новые active sequences;
* сохраняются как historical documents.

---

## 16. Classic zt-reduce is supported

Classic `zt-reduce` разрешён с active Topic seed, созданной или используемой ERL.

ERL не требует изменения Classic workflow и не требует, чтобы Classic workflow распознавал ERL documents.

Сам запуск `zt-reduce` над ERL document не является ошибкой.

Если host-level Reduce приводит к:

```text
active hard dependency source -> deprecated target
```

ERL сообщает:

```text
CLOSURE_REQUIRED
```

Это поддерживаемый trigger для generation-aware closure, а не запрет Classic Reduce.

Classic successor не становится ERL Book generation автоматически. External close
получает состояние `GENERATION_CLOSED_EXTERNALLY`; запись state и optional adoption
successor выполняет `erl-classic-reduce-reconcile` через dry-run и explicit apply.

---

## 17. erl-book-reduce

`erl-book-reduce` — generation-aware Reduce с dependency closure.

### Mutation scope

Seed = одна или несколько explicit Book Topic generation UUID.

Initial mutation set включает Book Topic и reducible generation members.

`erl-book-reduce` может deprecated:

```text
Memo
Topic
```

если document зарегистрирован как reducible member или входит в dependency closure.

Тип документа сам по себе не определяет reducibility.

**Canonical Note никогда не deprecated автоматически.** Durable Chapter Note
всегда остаётся active при обычном Book Reduce.

### Dependency closure

Обязательный hard dependency:

```text
active Occurrence -> active Vocabulary
active generation state -> active registered Book Topic
```

Если закрываемая Vocabulary имеет active Occurrence в Books B/C/D, owning generations B/C/D входят в closure.

Широкий cross-book closure — ожидаемая feature:

```text
Book A -> Vocabulary X
Book B -> Occurrence -> X
Book C -> Occurrence -> X
Book D -> Occurrence -> X

Reduce A
-> B/C/D enter closure
-> repeat to fixed point
```

ERL не ограничивает closure одной книгой.

### User visibility

`erl-book-reduce.zsh --dry-run` обязан показать полный closure до mutation:

* generations;
* documents;
* type/role;
* dependency reason.

Дополнительные generations никогда не deprecated молча. Cross-book cascade требует explicit confirmation/option (`--include-dependencies` или эквивалент).

### Transactionality

Reduce = semantic all-or-rollback transaction.

Journal:

```text
.state/erl/transactions/<TXID>/
```

Он хранит mutation plan, hashes, backups/snapshots и phase.

Использовать temp + atomic rename где возможно.

После mutation выполнить post-validation всего closure.

Ошибка -> rollback.

Crash -> recovery journal; новая Reduce transaction блокируется до recovery/rollback.

Rollback не перетирает молча неожиданные пользовательские изменения.

Для каждой подтверждённой generation Reduce удаляет из `.state/erl/works/`
generation file, policy, sequence, receipts, dependency metadata, manifest reference
и соответствующий active pointer. Удаление входит в ту же transaction и до commit
полностью покрывается journal backup. Compact committed manifest/result сохраняется
для audit после допустимой очистки backups.

---

## 18. Source books and copyright

Source books — локальные пользовательские файлы.

Не коммитить в public repository:

```text
EPUB
PDF
MOBI
AZW/AZW3
TXT copies of copyrighted books
```

`books/` должен быть исключён из публичного Git history.

`.state/erl/staging/` может содержать copyrighted excerpts и по умолчанию не публикуется.

`.state/erl/works/` должен хранить identities/mappings/hashes/UUID relations/sequence/lifecycle metadata, а не полные тексты книг.

---

## 19. Skills

Минимальный set:

```text
erl-book-ingest
erl-chapter-vocabulary-extract
erl-vocabulary-ingest
erl-chapter-vocabulary-ingest
erl-book-reduce
erl-classic-reduce-reconcile
erl-check
```

Optional orchestration:

```text
erl-book-vocabulary-extract
erl-book-vocabulary-ingest
```

Book-level orchestration не вводит новую semantics; оно использует chapter-level workflow.

Skill/operation identifiers остаются extensionless. Каждый ERL shell executable,
library и test script обязан иметь filename с расширением `.zsh`; запускать нужно
canonical `.scripts/erl/<command>.zsh`, не extensionless wrapper.

---

## 20. Agent validation checklist

Перед завершением изменения проверить минимум:

```text
[ ] .scripts/erl/docs/requirements.md соблюдён
[ ] нет :erl-* attributes в generated document contract
[ ] ERL не source .scripts/zettelkasten/
[ ] canonical object creation идёт через objects/
[ ] .state/erl/works/ не трактуется как disposable
[ ] cache/staging не используются как единственный source of truth
[ ] Vocabulary structural contract детерминированно читается
[ ] Occurrence содержит ровно одну canonical Vocabulary link
[ ] active Vocabulary unique по lexical identity
[ ] одна active generation на WORK_ID
[ ] Chapter resolution unique по WORK_ID × SOURCE_ID × CHAPTER_LOCATOR
[ ] sequence records valid
[ ] completed EXTRACTION_ID не ingest повторно
[ ] Classic zt-reduce не запрещён
[ ] CLOSURE_REQUIRED определяется корректно
[ ] erl-book-reduce dry-run показывает полный closure
[ ] wide cross-book closure не ограничивается одной книгой
[ ] erl-book-reduce закрывает только registered Topic/Memo, не Note
[ ] durable Chapter Note не входит в Book Reduce mutation set
[ ] generation metadata удаляется из works/ согласно ERL-REDUCE-025
[ ] compact committed transaction manifest/result сохраняется для audit
[ ] Classic successor требует erl-classic-reduce-reconcile
[ ] Reduce transaction recoverable/rollback-safe
[ ] source books/copyright excerpts не попадают в public Git
[ ] shellcheck/asciidoctor/git diff --check выполняются где применимо
[ ] все ERL shell scripts/libraries имеют расширение .zsh; extensionless copies отсутствуют
[ ] каждая ERL OpenSpec delta содержит task на derived primary regression test tests/erl-<behavior-slug>.zsh
[ ] primary regression test текущей delta существует и успешно запущен до completion/archive
[ ] archive preflight подтвердил completed tasks, primary test и strict change validation
[ ] archive postcondition подтвердил полный archive, delta synchronization и canonical validation
```

---

## 21. Final invariant

```text
Vault documents
= canonical knowledge objects
= host attributes only
```

```text
.state/erl/works/
= persistent ERL relationships + lifecycle + source mapping
```

```text
.state/erl/staging/
= temporary extraction/enrichment data
```

```text
.state/erl/transactions/
= transactional safety/recovery
```

```text
Classic zt-reduce
= supported host feature
```

```text
erl-book-reduce
= explicit generation-aware feature
= may reduce registered Topic and Memo
= never automatically reduces Note
= computes global dependency closure
= removes closed generation metadata from works/
```

При сомнении ERL должен адаптироваться к Vault contract, а не превращать Vault contract в ERL-specific schema.
