# English Reading Lab

**Русский** | **English**

Нормативные требования: `.scripts/erl/docs/requirements.md`.

Локальный OpenClaw workspace Lexi разворачивается из versioned self-contained
setup script. По умолчанию команда только показывает план:

```bash
.scripts/erl/dev/erl-openclaw-agent-setup.zsh \
  --workspace "$PWD" --user-name Саша --timezone Europe/Sofia
```

Изменения требуют `--apply`; проверка уже развёрнутого payload выполняется через
`--check`. Managed conflict не перезаписывается без отдельного
`--replace-managed --apply`. Setup не устанавливает OpenClaw, не регистрирует
agent/channel bindings и не изменяет credentials или global configuration.

Перед завершением или архивированием setup change embedded skills сверяются с
текущим эталонным Lexi workspace:

```bash
.scripts/erl/dev/erl-openclaw-agent-setup.zsh \
  --check-reference-skills "$PWD/skills"
```

Это development gate; обычный bootstrap с чистого листа не требует исходной
папки `skills/`.

---

# Русский

## Описание

English Reading Lab (ERL) — отдельный plugin/domain workflow над Zettelkasten Vault для подготовки к чтению англоязычных книг через персональный словарь.

```text
Zettelkasten Vault
= canonical storage/object contracts

Classic Zettelkasten
= host workflow

English Reading Lab
= отдельный reading/vocabulary workflow
```

ERL использует существующие Topic/Note/Memo constructors, но не добавляет в Vault собственный document type и не требует ERL-specific AsciiDoc attributes.

---

## Цель

ERL уменьшает лексический барьер перед чтением сложной английской литературы.

Вместо абстрактного word list система извлекает lexical items непосредственно из книги, сохраняет порядок появления и строит последовательность карточек для подготовки к чтению.

Первая extraction policy ориентирована на C1/C2 vocabulary. Следующие processing generations могут использовать другие CEFR thresholds, lexical policies и card formats.

---

## Документная модель

ERL использует только canonical Vault objects:

```text
Book        = Topic
Chapter     = Note
Vocabulary  = Memo
Occurrence  = Memo
```

Карточки остаются обычными `UUID.adoc` и используют только metadata host generating scripts.

ERL **не создаёт**:

```text
:erl-kind:
:erl-work-id:
:erl-book:
:erl-chapter:
:erl-sequence:
```

и не использует `:key-topic:` как скрытый ERL foreign key.

---

## Где хранится ERL semantics

ERL source of truth состоит из двух частей:

```text
canonical Vault documents
+
.state/erl/works/
```

Структура:

```text
.state/
└── erl/
    ├── works/              # persistent domain state
    │   └── <work-slug>/
    │       ├── work.json
    │       ├── sources/
    │       └── generations/
    ├── staging/            # extraction/enrichment output
    ├── transactions/       # Reduce/recovery journals
    ├── cache/              # rebuildable
    └── locks/              # runtime
```

Главное отличие:

```text
.state/erl/works/
!= disposable cache
```

В `works/` находятся logical work identity, source mappings, Chapter UUID mappings, Book generations, sequence, ingestion receipts и lifecycle/dependency state.

`staging/`, `cache/` и runtime artifacts имеют отдельный lifecycle. Удалять `.state/` целиком как обычную очистку нельзя, если существует `works/`.

---

## Logical work и Book generation

Logical work получает stable `WORK_ID`, но этот ID находится только в ERL work state.

```text
WORK_ID
    -> source editions
    -> Chapter UUIDs
    -> Book Topic generations
```

Book хранится как canonical Topic:

```text
Book Topic UUID
= semantic processing generation identity
```

Для одного WORK_ID допускается не более одной active generation.

Новая extraction/card/lexical policy может быть реализована через Reduce старой generation и создание нового Book Topic UUID.

`<work-slug>` в `.state/erl/works/<work-slug>/` удобен человеку, но не является identity.

ERL-local `WORK_ID`, `SOURCE_ID`, `EXTRACTION_ID` и `TXID` используют lowercase
UUID v4. UUID Vault documents остаются host UUID v1.

Book Topic получает отдельный host-compatible `:key-topic:` и canonical Topic
presentation. Этот thematic key не является `WORK_ID` и не используется как ERL foreign key.

---

## Chapter — durable source entity

Chapter хранится как canonical Note.

```text
Chapter UUID
= durable Vault identity
```

Chapter Note не получает ERL attributes и переживает смену Book generations.

Source mapping хранится в `works/`:

```text
WORK_ID
SOURCE_ID
source fingerprint
CHAPTER_LOCATOR
source order
Chapter UUID
```

Для EPUB первая версия использует SHA-256 source EPUB и canonical package-relative content href как preferred locator.

---

## Обработка книги по частям

Default processing unit — Chapter:

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

Поэтому не требуется помещать всю книгу в один model context.

Большая Chapter может быть разделена на temporary extraction segments без изменения persistent Chapter Note.

---

## Vocabulary Candidates

`erl-chapter-vocabulary-extract` анализирует одну Chapter и пишет staging Candidates.

Extraction batch имеет `EXTRACTION_ID`, generation UUID, Chapter UUID и policy identity.

Candidate хранит:

```text
candidate order
surface form
lemma
POS
lexical type
estimated CEFR
confidence
first relevant occurrence
context
```

Один Candidate по умолчанию соответствует lexical item на его первом relevant occurrence внутри текущей Chapter.

Один completed `EXTRACTION_ID` нельзя ingest второй раз.

---

## Vocabulary Memo

Vocabulary — canonical Memo и global active lexical knowledge.

Минимальная lexical structure:

```asciidoc
== Lexical identity

Lemma:: forlorn
POS:: adjective
Lexical type:: word
```

Canonical identity:

```text
normalized lemma + normalized POS + normalized lexical type
```

Если active Vocabulary для lexical item уже существует, новая Vocabulary не создаётся.

Vocabulary считается принадлежащей generation первого приобретения через persistent work state, а не через document attributes.

---

## Occurrence Memo

Повторная встреча известного lexical item создаёт Occurrence Memo.

```asciidoc
== Vocabulary

link:VOCABULARY-UUID.adoc[Description]

== Context

...
```

Occurrence — самостоятельный sequence node и новый context, но не новая canonical lexical card.

Новый Occurrence не создаётся на deprecated Vocabulary.

---

## Reading sequence

Vocabulary и Occurrence являются равноправными nodes.

```text
001 Vocabulary
002 Vocabulary
003 Occurrence
004 Vocabulary
005 Occurrence
```

Sequence принадлежит Book generation и хранится в `.state/erl/works/`, а не в AsciiDoc attributes.

Каждый node связан с Chapter UUID и Vault document UUID.

---

## Classic Reduce — поддерживаемая возможность

Classic `zt-reduce` можно применять с active Topic seed, используемой ERL.

ERL не требует модификации Classic workflow и не требует специального исключения ERL documents.

Сам запуск `zt-reduce` над ERL document не является ошибкой.

Если Classic Reduce deprecated Vocabulary, на которую ещё ссылаются active Occurrence, ERL обнаруживает:

```text
CLOSURE_REQUIRED
```

Это означает: host-level Reduce допустим, но ERL dependency closure ещё не завершён.

Classic successor Topic не становится ERL Book generation автоматически.
External close получает `GENERATION_CLOSED_EXTERNALLY`; состояние сверяет
`erl-classic-reduce-reconcile` через dry-run и explicit apply.

---

## erl-book-reduce

`erl-book-reduce` — отдельный generation-aware Reduce.

Он может переводить в deprecated зарегистрированные Book Topic и Memo.
Canonical Note никогда не deprecated автоматически; durable Chapter Note остаётся active.

### Cross-book dependency closure

Vocabulary является global canonical knowledge и принадлежит generation первого приобретения.

Поэтому возможен нормальный сценарий:

```text
Book A -> Vocabulary X
Book B -> Occurrence -> X
Book C -> Occurrence -> X
Book D -> Occurrence -> X
```

Reduce Book A требует:

```text
Vocabulary X -> deprecated
-> active Occurrences B/C/D потеряют active target
-> B/C/D входят в dependency closure
```

Это **ожидаемая feature**, а не ошибка.

Closure вычисляется транзитивно до fixed point и не ограничивается одной книгой.

### Никакого скрытого cascade

Перед mutation:

```bash
erl-book-reduce.zsh --dry-run ...
```

должен показать:

```text
affected generations
affected documents
role/type
dependency reason
```

Если нужны дополнительные generations, они включаются только явно (`--include-dependencies` или эквивалент).

### Transactionality

Reduce выполняется как all-or-rollback operation.

Journal:

```text
.state/erl/transactions/<TXID>/
```

Crash оставляет recovery journal. Новая Reduce transaction не запускается до recovery/rollback предыдущей.

После успешного commit metadata каждой закрытой generation удаляется из `works/`:
generation file, policy, sequence, ingestion receipts, dependency metadata,
manifest reference и active pointer. Compact committed transaction manifest/result
остаётся для audit, а удаление полностью покрывается rollback journal до commit.

---

## Source books и copyright boundary

Source books остаются локальными пользовательскими файлами.

Не публикуются:

```text
EPUB
PDF
MOBI
AZW/AZW3
TXT copies of copyrighted books
```

`books/` должен быть исключён из публичного Git history.

`.state/erl/staging/` может содержать excerpts и также не должен публиковаться по умолчанию.

`works/` хранит metadata/mappings/hashes/UUID relations, а не копии книги.

---

## Skills

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

Optional book-level orchestration:

```text
erl-book-vocabulary-extract
erl-book-vocabulary-ingest
```

Имена skills и domain operations не содержат расширения. Все реальные ERL
shell executables и libraries имеют расширение `.zsh`; canonical invocation
использует `.scripts/erl/<command>.zsh` без extensionless wrappers.

---

## Главный invariant

```text
Vault documents
= knowledge objects
= canonical host metadata only
```

```text
.state/erl/works/
= persistent ERL domain relationships/lifecycle
```

```text
.state/erl/staging/
= temporary model/extraction output
```

```text
Classic zt-reduce
= supported host feature
```

```text
erl-book-reduce
= generation-aware transactional feature
= registered Topic + Memo
= never automatically deprecates Note
= global dependency closure
= removes committed generation metadata from works/
```

ERL расширяет workflow Zettelkasten Vault, но не превращает Vault document contract в ERL schema.

---

# English

## Description

English Reading Lab (ERL) is a separate plugin/domain workflow on top of a Zettelkasten Vault.

```text
Zettelkasten Vault = canonical storage/object contracts
Classic Zettelkasten = host workflow
English Reading Lab = reading/vocabulary workflow
```

ERL reuses canonical Topic/Note/Memo constructors and does not add ERL-specific AsciiDoc attributes.

---

## Document model

```text
Book        = Topic
Chapter     = Note
Vocabulary  = Memo
Occurrence  = Memo
```

Vault documents remain ordinary `UUID.adoc` files with host-defined metadata only.

ERL does not create `:erl-*` attributes and does not overload `:key-topic:` as an ERL foreign key.

---

## ERL state

The ERL source of truth is:

```text
Vault documents
+
.state/erl/works/
```

```text
.state/
└── erl/
    ├── works/              # persistent domain state
    ├── staging/            # intermediate extraction data
    ├── transactions/       # Reduce/recovery journals
    ├── cache/              # rebuildable
    └── locks/              # runtime
```

`works/` is persistent and must not be treated as disposable cache.

It stores logical work identity, sources, durable Chapter UUID mappings, Book generations, reading sequences, ingestion receipts, and lifecycle/dependency metadata.

State Contract v1 uses UTF-8 JSON with `work.json`, `sources/<SOURCE_ID>.json`,
and `generations/<BOOK_TOPIC_UUID>.json`. ERL-local identifiers use lowercase
UUID v4; Vault document UUIDs remain host UUID v1.

---

## Work, generation and Chapter identity

A logical work has a stable `WORK_ID` stored only in ERL work state.

A Book Topic UUID identifies one semantic processing generation.

A Book Topic has a separate host-compatible `:key-topic:` and canonical Topic
presentation. The thematic key is not `WORK_ID` and is not an ERL foreign key.

A Chapter is a durable Note whose UUID can be reused across multiple generations.

Source/chapter resolution is stored outside the Note using:

```text
WORK_ID × SOURCE_ID × CHAPTER_LOCATOR -> Chapter UUID
```

---

## Incremental extraction

The default processing unit is one Chapter:

```text
active Book Topic UUID × Chapter UUID
```

This allows Chapter-by-Chapter cloud-model processing without requiring the whole book to fit into one context window.

Large Chapters may be split into temporary extraction segments.

---

## Vocabulary and Occurrence

Vocabulary is a canonical Memo with a deterministic lexical identity block.

Occurrence is another canonical Memo containing one canonical link to the active Vocabulary and a new context.

Vocabulary is global active lexical knowledge; later encounters create Occurrences rather than duplicate Vocabulary cards.

---

## Reading sequence

Vocabulary and Occurrence are equal reading-sequence nodes.

The sequence belongs to a Book generation and is stored in persistent ERL work state rather than document attributes.

---

## Classic Reduce

Classic `zt-reduce` is supported with an ERL-used active Topic seed.

ERL does not require Classic Zettelkasten to identify or exclude ERL documents.

If a host-level Reduce leaves an active hard dependency pointing to a deprecated target, ERL reports `CLOSURE_REQUIRED`.

The Classic successor is not adopted as an ERL Book generation automatically.
`erl-classic-reduce-reconcile` records `GENERATION_CLOSED_EXTERNALLY` and may
adopt the successor only through dry-run and explicit apply.

---

## erl-book-reduce

`erl-book-reduce` is the generation-aware, dependency-aware Reduce operation.

It may deprecate registered Book Topic and Memo documents. It never automatically
deprecates a canonical Note; durable Chapter Notes remain active.

Because Vocabulary is global and belongs to its first-acquisition generation, reducing one book may require a cross-book dependency closure involving many later generations.

This is expected behaviour.

The full closure must be shown with a dry run before any cascade, and extra generations require explicit inclusion.

Reduce is transactional and uses recovery journals under `.state/erl/transactions/`.

After commit, closed-generation policy, sequence, receipts, dependency metadata,
generation file, manifest reference, and active pointer are removed from `works/`.
A compact committed transaction manifest/result remains for audit.

---

## Source boundary

Copyrighted source books remain local and are not part of the public plugin repository.

Staging may contain source excerpts and should not be published by default.

Persistent work state stores metadata, mappings, hashes, UUID relations and lifecycle data, not full copyrighted texts.

---

## Core invariant

```text
Vault documents
= canonical knowledge objects

.state/erl/works/
= persistent ERL domain state

Classic zt-reduce
= supported host feature

erl-book-reduce
= explicit generation-aware feature
= registered Topic and Memo only
= never automatically deprecates Note
= removes committed generation metadata from works/
```
