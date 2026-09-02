# English Reading Lab — Final Requirements

Этот документ является нормативным источником требований English Reading Lab (ERL).

Ключевой принцип:

```text
Zettelkasten Vault
= canonical storage/object contracts

Classic Zettelkasten
= host workflow

English Reading Lab
= отдельный plugin/domain workflow
```

ERL не изменяет модель Vault ради своих domain concepts. ERL использует стандартные Topic/Note/Memo и хранит ERL-specific relationships/lifecycle вне AsciiDoc metadata. Canonical host attributes, включая `:key-topic:` и `:deprecated:`, сохраняют host semantics.

---

## 1. Architecture

```text
ERL-ARCH-001
English Reading Lab является отдельным domain layer/plugin над Zettelkasten Vault.
```

```text
ERL-ARCH-002
ERL не является частью Classic Zettelkasten workflow.
```

```text
ERL-ARCH-003
Runtime dependency direction:

ERL -> objects -> lib
ERL -> lib

objects и lib являются host-provided runtime contracts и не принадлежат ERL repository.
```

```text
ERL-ARCH-004
ERL не зависит от .scripts/zettelkasten/ как от implementation API и не вызывает zcreate.
```

```text
ERL-ARCH-005
ERL может использовать canonical host commands, включая Classic zt-reduce,
как пользовательские host-level workflows, но не source их implementation.
```

```text
ERL-ARCH-006
Skill принимает semantic decisions и выполняет orchestration.
.scripts/erl/ реализует deterministic ERL operations.
Host .scripts/objects/ создаёт canonical Vault objects.
Host .scripts/lib/ предоставляет domain-neutral primitives.
```

```text
ERL-ARCH-007
ERL разрабатывается в отдельном repository.
ERL implementation task не изменяет host Zettelkasten repository.
```

```text
ERL-ARCH-008
Если существующего host contract недостаточно, это фиксируется как contract gap.
ERL не патчит core автоматически.
```

```text
ERL-ARCH-009
ERL source, host implementation и target Zettelkasten home могут находиться
в разных filesystem roots. Host operations разрешаются только через contract
целевого host, а persistent output направляется в target Zettelkasten home.
Repository-relative production fallback запрещён; отсутствие contract даёт explicit error.
```

---

## 2. Repository and write boundary

```text
ERL-REPO-001
ERL repository владеет только plugin code, skills, tests, fixtures,
documentation и ERL-local data contracts.
```

```text
ERL-REPO-002
Marta и другие implementation agents не изменяют host .scripts/lib/,
.scripts/objects/, .scripts/zettelkasten/, zcreate, zt-check или пользовательские Vault documents
как часть обычной ERL development task.
```

```text
ERL-REPO-003
Изменение host contract требует отдельного решения и отдельного change scope.
```

```text
ERL-REPO-004
Удаление ERL plugin не должно ломать Classic Zettelkasten workflow,
существующие UUID, filenames или internal links.
```

```text
ERL-REPO-005
ERL repository не содержит tracked production implementation host core.
Минимальные test doubles допустимы только в явно test-scoped fixtures
и не используются production runtime как fallback.
```

---

## 3. Canonical Vault document model

```text
ERL-DOC-001
ERL использует только существующие canonical document types Vault.
```

Соответствие:

```text
Book        = Topic
Chapter     = Note
Vocabulary  = Memo
Occurrence  = Memo
```

```text
ERL-DOC-002
Persistent ERL documents являются обычными UUID.adoc непосредственно в
<ZETTELKASTEN_HOME>/notes/. Дополнительный промежуточный vault/ не используется.
```

```text
ERL-DOC-008
Каждая зарегистрированная Book, Chapter, Vocabulary и Occurrence card является
valid UTF-8 AsciiDoc с понятным title, непустым role-relevant body, labelled
required values и читаемыми canonical link labels. Raw JSON/YAML, необработанный
HTML/XML, control characters и unresolved placeholders не заменяют content.
```

```text
ERL-HOME-001
Target Zettelkasten home является единым runtime root: canonical Topic, Note и
Memo находятся в notes/, а ERL state — в .state/erl/. ERL source root и host
implementation root не используются как production data destination.
```

```text
ERL-DOC-003
ERL document использует только attributes, которые предоставляет canonical host contract
и generating scripts.
```

Базовые host attributes включают существующие поля вида:

```asciidoc
:date:
:type:
:keywords:
:author:
:description:
:doclink:
:docfilename:
```

Topic может содержать host-defined `:key-topic:`. `:deprecated:` сохраняет host semantics.

```text
ERL-DOC-004
ERL-specific AsciiDoc attributes запрещены.
Не создавать :erl-kind:, :erl-work-id:, :erl-book:, :erl-chapter:,
:erl-sequence: или любое аналогичное семейство plugin-specific attributes.
```

```text
ERL-DOC-005
ERL не переопределяет :key-topic: как скрытый foreign key для WORK_ID,
generation, Chapter identity, sequence или другого ERL state.
```

```text
ERL-DOC-006
ERL role документа определяется сочетанием:

- canonical :type:;
- persistent ERL work state;
- structural contract тела документа.
```

```text
ERL-DOC-007
Canonical internal links сохраняют host format:

link:UUID.adoc[Description]
```

---

## 4. ERL state model

```text
ERL-STATE-001
ERL использует единый local namespace:

<ZETTELKASTEN_HOME>/.state/erl/
```

Рекомендуемая структура:

```text
.state/
└── erl/
    ├── works/              # persistent ERL domain state
    │   └── <work-slug>/
    │       ├── work.json
    │       ├── sources/
    │       └── generations/
    ├── staging/            # intermediate extraction/enrichment data
    ├── transactions/       # Reduce/recovery journals
    ├── cache/              # rebuildable cache/index data
    └── locks/              # runtime locks
```

```text
ERL-STATE-002
.state/erl/works/ является persistent ERL domain state и частью source of truth ERL.
```

```text
ERL-STATE-003
Источник истины ERL состоит из:

<ZETTELKASTEN_HOME>/notes/
+
<ZETTELKASTEN_HOME>/.state/erl/works/
```

```text
ERL-STATE-004
.state/erl/works/ не является disposable cache.
Обычная очистка runtime state не должна удалять works/.
```

```text
ERL-STATE-005
Удаление .state/ целиком считается destructive operation,
если в .state/erl/works/ существуют work manifests.
```

```text
ERL-STATE-006
staging/, transactions/, cache/ и locks/ имеют собственные lifecycle rules
и не должны смешиваться с persistent work state.
```

```text
ERL-STATE-007
cache/ и derived indexes должны быть полностью rebuildable.
```

```text
ERL-STATE-018
Legacy <ZETTELKASTEN_HOME>/vault/{notes,.state/erl} не принимается silently.
Mutation блокируется с HOME_LAYOUT_MIGRATION_REQUIRED до explicit migration,
поддерживающей dry-run, collision detection, journal, rollback и recovery.
```

```text
ERL-STATE-008
Незавершённые transaction artifacts не очищаются. После commit/rollback
backup payload может очищаться согласно recovery policy, но compact committed
manifest/result закрытой generation сохраняется как persistent audit record.
```

```text
ERL-STATE-009
Persistent work state должен быть text-based, deterministic и inspectable из Unix CLI.
Canonical Persistent Work State v1 использует JSON согласно ERL-STATE-011/012.
TSV/JSONL/YAML допустимы только для noncanonical staging, reports или cache,
если конкретный contract явно не устанавливает иное.
```

```text
ERL-STATE-010
Git tracking/back-up policy для пользовательского works/ является deployment decision,
но works/ должен переживать обычную очистку cache/staging и не может считаться временными данными.
```

```text
ERL-STATE-011
Persistent Work State Contract v1 использует UTF-8 JSON и обязательное поле
"schema_version": 1. Generated files используют stable field ordering,
LF line endings и завершающий LF.
```

```text
ERL-STATE-012
Canonical filenames v1:
.state/erl/works/<work-slug>/work.json
.state/erl/works/<work-slug>/sources/<SOURCE_ID>.json
.state/erl/works/<work-slug>/generations/<BOOK_TOPIC_UUID>.json
```

```text
ERL-STATE-013
Переименование <work-slug> выполняется explicit migration под ERL lock,
не меняет WORK_ID/Vault UUID и атомарно обновляет ERL-local path references
либо выполняет rollback.
```

```text
ERL-STATE-014
WORK_ID, SOURCE_ID, EXTRACTION_ID и TXID являются independently generated
UUID v4 в lowercase canonical 8-4-4-4-12 representation и не выводятся
из пользовательского текста или filesystem paths. Это ERL-local identifiers,
не Vault document UUID. Vault documents продолжают использовать host UUID v1.
```

```text
ERL-STATE-015
WORK_ID глобально уникален среди work manifests.
SOURCE_ID уникален как минимум внутри WORK_ID.
```

```text
ERL-STATE-016
Fingerprint EPUB v1 имеет формат sha256:<64 lowercase hexadecimal digits>
и проверяется выражением ^sha256:[0-9a-f]{64}$.
```

```text
ERL-STATE-017
Persistent state update использует temporary file, validation и atomic rename.
Multi-file semantic operation использует journal/recovery protocol.
```

---

## 5. Logical work and Book generation

```text
ERL-BOOK-001
Logical work — стабильная ERL identity произведения.
```

```text
ERL-BOOK-002
Logical work получает stable opaque WORK_ID при первом ingest.
WORK_ID хранится только в .state/erl/works/ и не записывается в Vault document attributes.
```

```text
ERL-BOOK-003
WORK_ID не выводится из title, slug, ISBN, source filename или Book Topic UUID.
```

```text
ERL-BOOK-004
<work-slug> в path .state/erl/works/<work-slug>/ является human-readable locator,
а не canonical identity.
```

```text
ERL-BOOK-005
Переименование work-slug не меняет WORK_ID, Vault UUID или semantic identity произведения.
```

```text
ERL-BOOK-006
Book представлен существующей canonical Topic, видимый title которой
идентифицирует книгу, а не только thematic category.
```

```text
ERL-BOOK-007
Book Topic представляет одну semantic processing generation logical work.
Book Topic UUID является generation identity.
Generation state не публикуется до materialization и validation Book Topic.
```

```text
ERL-BOOK-008
Work manifest связывает WORK_ID со всеми retained Book Topic generation UUID.
Generation, успешно закрытая через erl-book-reduce, удаляется из manifest
согласно ERL-REDUCE-025; её deprecated Vault Topic остаётся historical artifact.
```

```text
ERL-BOOK-009
Для одного WORK_ID допускается не более одной active Book generation.
Active/deprecated состояние определяется canonical :deprecated: semantics Book Topic
и должно согласовываться с work state.
```

```text
ERL-BOOK-010
Новая semantic generation создаёт новый Book Topic UUID.
```

```text
ERL-BOOK-011
Новая generation может использовать другие CEFR threshold, extraction policy,
lexical policy, card format, source processing order и ingestion policy.
```

```text
ERL-BOOK-012
При создании Book Topic пользователь или ERL workflow явно задаёт непустой
host-compatible thematic key для :key-topic:. Этот key не является WORK_ID,
generation identity или ERL foreign key и не используется для восстановления
ERL relationships.
```

```text
ERL-BOOK-013
Book Topic создаётся canonical Topic constructor и соблюдает host Topic
presentation contract для title, :description: и :doclink:.
Visible title, :description: и :doclink: основаны на canonical logical-work title.
Logical-work metadata и название произведения хранятся в work state
и при необходимости в body, не подменяя :key-topic:.
```

```text
ERL-BOOK-014
Создание Book Topic, generation state и active-generation pointer является
одной recoverable operation; ошибка откатывает только её provisional artifacts.
```

---

## 6. Source and Chapter identity

```text
ERL-CHAPTER-001
Chapter представлен canonical Note.
```

```text
ERL-CHAPTER-002
Chapter является durable source entity.
Один Chapter UUID может использоваться последовательными Book generations.
```

```text
ERL-CHAPTER-003
Chapter Note не хранит ERL-specific identity attributes.
```

```text
ERL-CHAPTER-004
Полная source identity Chapter хранится в .state/erl/works/<work-slug>/sources/.
```

Минимальный source/chapter record:

```text
WORK_ID
SOURCE_ID
source fingerprint
CHAPTER_LOCATOR
source order
Chapter UUID
```

```text
ERL-CHAPTER-005
SOURCE_ID является stable identity конкретного source/edition внутри WORK_ID.
```

```text
ERL-CHAPTER-006
Для EPUB первой версии source fingerprint = SHA-256 исходного EPUB artifact.
```

```text
ERL-CHAPTER-007
CHAPTER_LOCATOR должен быть stable внутри SOURCE_ID.
Для EPUB предпочтителен canonical package-relative content href
с fragment при необходимости; spine index допустим как fallback.
```

```text
ERL-CHAPTER-008
Chapter resolution key:

WORK_ID × SOURCE_ID × CHAPTER_LOCATOR
```

```text
ERL-CHAPTER-009
Source order является ordering metadata и не является identity.
```

```text
ERL-CHAPTER-010
Другой edition/source получает новый SOURCE_ID,
если не выполнена explicit mapping/migration procedure.
```

```text
ERL-CHAPTER-011
Обычный erl-book-reduce не deprecated'ит durable Chapter Notes.
```

```text
ERL-CHAPTER-012
Каждая materialized Chapter Note наследует exact host-defined `:key-topic:`
текущей active Book Topic своей generation.
```

```text
ERL-CHAPTER-013
Chapter Note содержит ровно одну canonical link в section `Book` на active Book
Topic. Book Topic содержит section `Chapters` с unique reciprocal canonical links
на все materialized Chapters в deterministic source order.
```

```text
ERL-CHAPTER-014
При создании новой active generation reused durable Chapter Note сохраняет UUID,
заменяет прежнюю Book Topic link и синхронизирует `:key-topic:` с новой Topic.
Две active Topic attachments для одной Chapter запрещены.
```

```text
ERL-CHAPTER-015
Создание и rebind Chapter–Topic projection входят в ingest transaction: до первой
mutation сохраняются exact document backups и hashes, а failure/recovery
восстанавливает прежние bytes без partial generation.
```

```text
ERL-CHAPTER-016
Следующая Chapter Note непосредственно после completed Chapter Memo Chain
содержит ровно одну canonical link в section `Reading handoff` на tail Memo с
label `Последнее memo предыдущей главы`. Chapter без Memo Chain не создаёт link.
```

---

## 7. Incremental processing

```text
ERL-PROC-001
Logical work является lifecycle scope.
```

```text
ERL-PROC-002
Chapter является default processing unit.
```

```text
ERL-PROC-003
Основной processing scope:

active Book Topic UUID × Chapter UUID
```

```text
ERL-PROC-004
Книга может обрабатываться постепенно:
Chapter 1 сегодня, Chapter 2 позже, затем следующие Chapters.
```

```text
ERL-PROC-005
Одна Chapter может быть обработана заново в новой semantic generation.
```

```text
ERL-PROC-006
Обработка Chapter в deprecated generation не блокирует её обработку
в новой active generation.
```

```text
ERL-PROC-007
ERL не требует помещения всей книги в один model context.
```

```text
ERL-PROC-008
Если Chapter слишком велика, extraction может делить её на segments.
Segmentation относится только к staging/execution и не меняет persistent Chapter Note.
```

---

## 8. Extraction and Candidate staging

```text
ERL-EXT-001
Основной extraction skill:

erl-chapter-vocabulary-extract
```

```text
ERL-EXT-002
Extraction выполняется для одной Chapter внутри конкретной active Book generation.
```

```text
ERL-EXT-003
Extraction проходит source в source order.
```

```text
ERL-EXT-004
Первая extraction policy ориентирована на C1/C2 lexical items.
Policy может меняться между generations.
```

```text
ERL-EXT-005
Extraction skill не создаёт Vault documents,
не использует object constructors и не вызывает zcreate.
```

```text
ERL-EXT-006
Extraction output хранится в .state/erl/staging/.
```

```text
ERL-CAND-001
Vocabulary Candidate является staging object, а не Vault document.
```

```text
ERL-CAND-002
Extraction batch имеет минимум:

EXTRACTION_ID
Book generation UUID
Chapter UUID
policy identity/fingerprint
source identity
```

В v1 `source identity` в batch представлена объектом:

```text
SOURCE_ID
source fingerprint
```

Оба значения должны совпадать с persistent source state выбранной Book generation.

```text
ERL-CAND-003
Candidate содержит минимум:

candidate ordinal
surface form
lemma
POS
lexical type
estimated CEFR
confidence
first relevant occurrence
context
```

```text
ERL-CAND-004
Один Candidate по умолчанию соответствует одному выбранному lexical item
на его первом relevant occurrence внутри текущей Chapter.
```

```text
ERL-CAND-005
Повторы того же lexical item позже в той же Chapter
по умолчанию не создают дополнительные Candidates.
```

```text
ERL-CAND-006
Candidate ordinal отражает source/extraction order,
а не persistent reading sequence ordinal.
```

```text
ERL-CAND-007
Повторный extraction того же generation × Chapter распознаётся как retry/re-extraction.
```

```text
ERL-CAND-008
Один EXTRACTION_ID не должен быть ingested дважды.
Persistent work state хранит достаточный ingestion receipt для detection повторной ingestion.
```

```text
ERL-CAND-009
Материальное изменение card/extraction/lexical policy после ingestion
создаёт новую semantic generation через Reduce, а не переписывает старую generation молча.
```

```text
ERL-CAND-010
Default extraction policy анализирует Chapter целиком и не применяет
фиксированную или адаптивную квоту к числу подходящих Candidates в Chapter.
Ограничение «один Candidate на lexical identity» сохраняется.
```

---

## 9. Vocabulary Memo

```text
ERL-VOC-001
Vocabulary представлен canonical Memo.
```

```text
ERL-VOC-002
Vocabulary Memo не получает ERL-specific attributes.
```

```text
ERL-VOC-003
Vocabulary role определяется persistent work state и lexical card structure документа.
```

Минимальный deterministic lexical identity block:

```asciidoc
== Lexical identity

Lemma:: forlorn
POS:: adjective
Lexical type:: word
```

Дополнительные sections могут содержать Meaning, Translation, IPA, CEFR, Usage,
Context, Related vocabulary и Notes.

```text
ERL-VOC-004
Базовая lexical identity:

normalized lemma + normalized POS + normalized lexical type
```

```text
ERL-VOC-005
Surface form сам по себе не является canonical lexical identity.
Sense пока не является обязательной частью identity.
```

```text
ERL-VOC-006
Среди active Vocabulary допускается не более одной canonical карточки
для одной lexical identity.
```

```text
ERL-VOC-007
Vocabulary является global canonical lexical knowledge для active library,
а не book-local duplicate.
```

```text
ERL-VOC-008
Vocabulary принадлежит generation первого приобретения lexical item.
Эта ownership relation хранится в persistent generation state.
```

```text
ERL-VOC-009
Deprecated Vocabulary не участвует в active lookup/deduplication.
```

```text
ERL-VOC-010
Если historical Vocabulary deprecated, новая active generation может создать
новую canonical Vocabulary для той же lexical identity.
```

---

## 10. Occurrence Memo

```text
ERL-OCC-001
Occurrence представлен canonical Memo.
```

```text
ERL-OCC-002
Occurrence Memo не получает ERL-specific attributes.
```

```text
ERL-OCC-003
Occurrence создаётся, если Candidate соответствует существующему active Vocabulary.
```

```text
ERL-OCC-004
Occurrence role определяется persistent work state и обязательной structural schema.
```

Минимальная schema:

```asciidoc
== Vocabulary

link:VOCABULARY-UUID.adoc[Description]

== Context

...
```

```text
ERL-OCC-005
Vocabulary section содержит ровно одну canonical internal link на target Vocabulary.
```

```text
ERL-OCC-006
Context section хранит context текущей встречи lexical item.
```

```text
ERL-OCC-007
Occurrence является самостоятельным sequence node,
но не является новым canonical lexical object.
```

```text
ERL-OCC-008
Новый Occurrence не создаётся на deprecated Vocabulary target.
```

---

## 11. Persistent work state contract

```text
ERL-WORKSTATE-001
.state/erl/works/<work-slug>/ хранит все ERL relationships,
которые нельзя надёжно вывести только из canonical Vault document attributes.
```

```text
ERL-WORKSTATE-002
Work manifest хранит минимум:

WORK_ID
logical work metadata
known SOURCE_ID records
retained Book generation UUIDs
active generation pointer/status
```

```text
ERL-WORKSTATE-003
Source state хранит минимум:

SOURCE_ID
WORK_ID
source fingerprint
Chapter resolution records
```

```text
ERL-WORKSTATE-004
Chapter resolution record хранит минимум:

Chapter UUID
SOURCE_ID
CHAPTER_LOCATOR
source order
```

```text
ERL-WORKSTATE-005
Generation state хранит минимум:

Book Topic UUID
WORK_ID
processing policy identity
ordered sequence entries
ingestion receipts
reducible membership/dependency metadata
```

```text
ERL-WORKSTATE-006
Sequence entry хранит минимум:

ordinal
Chapter UUID
role: vocabulary | occurrence
Vault document UUID
```

```text
ERL-WORKSTATE-007
Generation membership и Chapter membership Vocabulary/Occurrence
определяются persistent work state, а не AsciiDoc attributes.
```

```text
ERL-WORKSTATE-008
Для retained generation state и active ERL documents проверка двусторонняя:
state record не может ссылаться на отсутствующий UUID, а structural role
документа должна соответствовать recorded role. Deprecated documents generation,
успешно закрытой через erl-book-reduce, могут не иметь recorded role в works/
после удаления metadata согласно ERL-REDUCE-025.
```

```text
ERL-WORKSTATE-009
Изменение schema .state/erl/works/ требует versioning/migration plan,
поскольку works/ является persistent domain data.
```

---

## 12. Ingestion

```text
ERL-ING-001
Semantic ingestion одного Candidate выполняет erl-vocabulary-ingest.
```

```text
ERL-ING-002
Chapter-level orchestration выполняет erl-chapter-vocabulary-ingest.
```

```text
ERL-ING-003
Ingestion нормализует lexical identity и выполняет lookup
только среди active Vocabulary records.
```

```text
ERL-ING-004
Если active canonical Vocabulary не найден, создаётся Vocabulary Memo.
```

```text
ERL-ING-005
Если active canonical Vocabulary найден, создаётся Occurrence Memo.
```

```text
ERL-ING-006
Vault document создаётся только через canonical object constructor.
```

```text
ERL-ING-007
После успешного создания document ERL обновляет persistent work state
и reading sequence.
```

```text
ERL-ING-008
Операция document creation + work-state update должна быть recoverable.
Состояние «document создан, work state не обновлён» обнаруживается erl-check/recovery.
```

```text
ERL-ING-009
Ingestion одного EXTRACTION_ID идемпотентна относительно ingestion receipt:
повторный запуск не создаёт второй набор документов молча.
```

```text
ERL-ING-010
Созданные Vocabulary и Occurrence Memo наследуют exact :key-topic:
текущей Chapter; existing global Vocabulary не перепривязывается.
```

```text
ERL-ING-011
Каждый sequence Memo и Chapter Note имеют ровно одну reciprocal canonical link
в sections Chapter и Vocabulary; Chapter links упорядочены по Candidate/source order.
```

```text
ERL-ING-012
Memo creation, attachment, Chapter-local chain mutation, generation state и receipt
фиксируются одной recoverable per-Candidate transaction.
```

---

## 13. Reading sequence

```text
ERL-SEQ-001
Vocabulary и Occurrence являются равноправными nodes reading sequence.
```

```text
ERL-SEQ-002
Reading sequence принадлежит конкретной Book generation.
```

```text
ERL-SEQ-003
Sequence хранится в persistent generation state,
а не в AsciiDoc attributes.
```

```text
ERL-SEQ-004
Sequence строится в source order.
```

```text
ERL-SEQ-005
Обработка следующей Chapter продолжает sequence текущей active generation.
```

```text
ERL-SEQ-006
Sequence ordinal и Candidate ordinal являются разными понятиями.
```

```text
ERL-SEQ-007
Sequence должна быть полностью восстанавливаема из .state/erl/works/
и существующих Vault UUID, без cache/ и staging/.
```

```text
ERL-SEQ-008
Deprecated documents не входят в active reading sequence.
После успешного erl-book-reduce historical membership/ordinal не сохраняются
в .state/erl/works/. Audit закрытой sequence обеспечивается deprecated Vault
documents и обязательным compact committed transaction manifest/result,
который не удаляется обычной очисткой transaction backups.
```

```text
ERL-SEQ-009
Каждая Chapter материализует свою линейную Memo Chain из sequence nodes;
chain не пересекает Chapter boundary.
```

```text
ERL-SEQ-010
Первая Memo Chapter является head без `Предыдущее memo`; single-node chain
также не имеет `Следующее memo`.
```

```text
ERL-SEQ-011
Последующие Memos связаны reciprocal links `Предыдущее memo` и
`Следующее memo`; branches, cycles и duplicates недопустимы.
```

```text
ERL-SEQ-012
Tail Memo completed Chapter chain содержит `Reading handoff` link с label
`Следующая глава` на непосредственно следующую Chapter Note того же SOURCE_ID.
Terminal Chapter не имеет outgoing handoff; Chapter-local Memo Chains не
соединяются напрямую.
```

```text
ERL-SEQ-013
Reciprocal handoff materialизуется только после Candidate completion как одна
recoverable batch-finalization operation. До mutation journal сохраняет paths,
hashes и exact backups обеих сторон; retry не создаёт duplicates, а stale
generated handoff заменяется transactionally.
```

---

## 14. Deprecated semantics

```text
ERL-DEP-001
ERL использует canonical host :deprecated: semantics и не вводит параллельный archive flag.
```

```text
ERL-DEP-002
Deprecated documents не изменяются новыми ERL workflows и не получают новых ERL links.
```

```text
ERL-DEP-003
Deprecated Vocabulary не участвует в active lookup/deduplication.
```

```text
ERL-DEP-004
Deprecated documents не входят в новые active sequences.
```

```text
ERL-DEP-005
Deprecated Vault documents сохраняются для history.
Compact committed transaction manifest/result сохраняется для audit,
но generation-specific operational metadata успешно закрытой generation
удаляется из .state/erl/works/ согласно ERL-REDUCE-025.
```

---

## 15. Classic Reduce — supported host feature

```text
ERL-CLASSIC-REDUCE-001
Classic zt-reduce разрешено применять к active canonical Topic,
созданной или используемой ERL. Seed Classic Reduce всегда является Topic;
Classic zt-reduce не выполняет Reduce отдельной Memo или Note.
```

```text
ERL-CLASSIC-REDUCE-002
ERL не требует от Classic workflow обнаруживать ERL roles,
читать .state/erl/works/ или знать о ERL lifecycle.
```

```text
ERL-CLASSIC-REDUCE-003
Classic zt-reduce выполняет host semantics: создаёт successor Topic с тем же
:key-topic:, deprecates исходную Topic и active Memo с совпадающим :key-topic:,
а active Note не deprecates.
```

```text
ERL-CLASSIC-REDUCE-004
Classic successor Topic не становится ERL Book generation автоматически.
Он остаётся Classic Topic до explicit ERL adoption/migration.
```

```text
ERL-CLASSIC-REDUCE-005
Если Classic Reduce deprecates зарегистрированную Book Topic, work state
переводит generation в GENERATION_CLOSED_EXTERNALLY, очищает active-generation
pointer и сохраняет historical membership. Новые processing operations
для такой generation запрещены.
```

```text
ERL-CLASSIC-REDUCE-006
Если Classic Topic Reduce deprecates Vocabulary Memo с active Occurrence
dependants, ERL классифицирует состояние как CLOSURE_REQUIRED.
```

```text
ERL-CLASSIC-REDUCE-007
До завершения closure ERL не создаёт новые hard dependencies
на deprecated target.
```

```text
ERL-CLASSIC-REDUCE-008
Сам факт Classic Reduce ERL-used Topic не является validation error.
Незавершённая reconciliation является диагностируемым status.
```

```text
ERL-CLASSIC-REDUCE-009
erl-check обнаруживает externally closed Book Topic, незарегистрированную
Classic successor Topic и deprecated Vocabulary с active dependants.
```

```text
ERL-CLASSIC-REDUCE-010
Explicit adoption successor создаёт новую generation state запись,
не меняет WORK_ID и допускается только при отсутствии другой active
Book generation того же WORK_ID.
```

```text
ERL-CLASSIC-REDUCE-011
Запись GENERATION_CLOSED_EXTERNALLY и optional adoption Classic successor
выполняет explicit deterministic operation:

erl-classic-reduce-reconcile BOOK_TOPIC_UUID

Операция имеет read-only dry-run, показывает старую Topic, найденный successor,
изменения work state и blockers. Без explicit apply она не изменяет state.
```

---

## 16. erl-book-reduce — generation-aware Reduce

```text
ERL-REDUCE-001
erl-book-reduce закрывает одну или несколько Book generations как ERL lifecycle operation.
```

```text
ERL-REDUCE-002
Reduce seed — одна или несколько явно указанных active Book Topic generation UUID.
```

```text
ERL-REDUCE-003
Initial mutation set generation содержит:

- Book Topic generation;
- reducible generation members согласно .state/erl/works/.

Durable Chapter Notes не входят в обычный mutation set.
```

```text
ERL-REDUCE-004
erl-book-reduce может deprecate Book Topic и canonical Memo,
зарегистрированные как reducible generation members или включённые
в dependency closure.
```

```text
ERL-REDUCE-005
Canonical :type: сам по себе не определяет reducibility.
Note не является автоматически reducible type.
```

```text
ERL-REDUCE-006
erl-book-reduce никогда автоматически не deprecates canonical Note.
Durable Chapter Note всегда остаётся active.
```

```text
ERL-REDUCE-007
Перед mutation выполняется полный read-only preflight.
```

Preflight обязан:

```text
- проверить acceptable Git/worktree policy;
- проверить consistency work state <-> Vault documents;
- построить dependency graph;
- вычислить hard-dependency closure до fixed point;
- просканировать active inbound links на mutation targets;
- показать точный mutation plan.
```

```text
ERL-REDUCE-008
Hard dependency — relation, где active source требует active target.
Обязательные hard dependencies:
active Occurrence -> active Vocabulary
active generation state -> active registered Book Topic

Deprecated Book Topic переводит generation в GENERATION_CLOSED_EXTERNALLY;
она больше не считается active generation.
```

```text
ERL-REDUCE-009
Если Vocabulary из mutation set является target active Occurrence другой generation,
owning generation этого Occurrence входит в dependency closure.
```

```text
ERL-REDUCE-010
Dependency closure транзитивен, вычисляется до fixed point
и может пересекать границы любого количества books/works/generations.
```

```text
ERL-REDUCE-011
Широкий cross-book closure является ожидаемой feature ERL,
а не ошибкой алгоритма.
```

Причина:

```text
global canonical Vocabulary
+
Vocabulary принадлежит generation первого приобретения
+
deprecated Vocabulary не может оставаться active hard-dependency target
```

Пример:

```text
Book A -> Vocabulary X
Book B -> Occurrence -> Vocabulary X
Book C -> Occurrence -> Vocabulary X
Book D -> Occurrence -> Vocabulary X

Reduce generation A
-> generations B/C/D входят в dependency closure
-> closure продолжает вычисляться рекурсивно до fixed point
```

```text
ERL-REDUCE-012
ERL не ограничивает dependency closure границей исходной книги.
```

```text
ERL-REDUCE-013
Любая новая ERL relation с invariant «active target required»
должна быть зарегистрирована в dependency model Reduce.
```

```text
ERL-REDUCE-014
Прочие active inbound links являются soft references,
если их contract не требует active target.
Неизвестная ERL-specific dependency должна быть классифицирована до mutation.
```

```text
ERL-REDUCE-015
erl-book-reduce --dry-run выполняет полный preflight/closure
и не изменяет Vault documents или persistent work state.
```

```text
ERL-REDUCE-016
Если closure включает дополнительные generations,
каскад не выполняется молча.
Полный closure показывается пользователю и требует explicit confirmation/option,
например --include-dependencies.
```

```text
ERL-REDUCE-017
Dry-run/report должен показывать:

- все affected generations;
- все mutation target UUID;
- type/role каждого target;
- причину включения каждой generation/target в closure.
```

```text
ERL-REDUCE-018
Reduce является semantic all-or-rollback transaction.
```

```text
ERL-REDUCE-019
До первой mutation создаётся transaction journal:

.state/erl/transactions/<TXID>/
```

Journal содержит минимум:

```text
mutation plan
original file hashes
backups/snapshots изменяемых documents/work-state files
transaction phase
```

```text
ERL-REDUCE-020
Изменения отдельных файлов применяются через temporary file + atomic rename,
где это поддерживает локальная filesystem.
```

```text
ERL-REDUCE-021
После mutation выполняется post-validation всего closure.
При ошибке выполняется rollback всех mutation targets.
```

```text
ERL-REDUCE-022
Crash/interruption оставляет recovery journal.
Новая Reduce transaction не начинается до завершения или explicit rollback предыдущей.
```

```text
ERL-REDUCE-023
Rollback проверяет recorded hashes и не перетирает молча
неожиданные пользовательские изменения, появившиеся после начала transaction.
```

```text
ERL-REDUCE-024
Если Classic Topic Reduce deprecates Vocabulary Memo с active dependants,
это supported closure trigger. erl-check/erl-book-reduce обнаруживают его
и предлагают полный closure.
```

```text
ERL-REDUCE-025
Для каждой Book generation, вошедшей в подтверждённый mutation set/closure,
erl-book-reduce обязан удалить её generation-specific persistent metadata
из .state/erl/works/.

Удаляются:

- Book generation state;
- processing policy;
- reading sequence;
- ingestion receipts;
- reducible/dependency metadata;
- generation reference из work manifest;
- active-generation pointer, если он указывает на закрываемую generation.

Удаление входит в ту же all-or-rollback transaction, что и deprecation Vault
documents. До commit удаляемые state files/records включаются в journal backup;
ошибка mutation или post-validation восстанавливает их вместе с документами.
После commit cache/staging не считаются допустимой копией удалённого persistent
generation state.
```

---

## 17. Staging, source books and copyright boundary

```text
ERL-SOURCE-001
Source books являются локально предоставленными пользователем файлами
и не являются обязательной частью публичного plugin repository.
```

```text
ERL-SOURCE-002
books/ должен быть исключён из публичного Git history.
```

```text
ERL-SOURCE-003
Не коммитить EPUB/PDF/MOBI/AZW/AZW3/TXT copies copyrighted books.
```

```text
ERL-SOURCE-004
<ZETTELKASTEN_HOME>/.state/erl/staging/ может содержать copyrighted context excerpts
и по умолчанию не должен публиковаться.
```

```text
ERL-SOURCE-005
<ZETTELKASTEN_HOME>/.state/erl/works/ хранит identities, mappings, hashes, UUID relations,
sequence/lifecycle data и policy metadata, но не полные копии защищённого текста.
```

---

## 18. Skills

Минимальный skill set:

```text
erl-book-ingest
    source -> Book Topic + durable Chapter Notes + work state

erl-chapter-vocabulary-extract
    Book generation + Chapter -> staging Candidates

erl-vocabulary-ingest
    one Candidate -> Vocabulary Memo | Occurrence Memo

erl-chapter-vocabulary-ingest
    Chapter staging -> ordered Vault documents + work-state entries

erl-book-reduce
    active generation(s) -> dependency-safe historical generation(s)

erl-classic-reduce-reconcile
    externally reduced Book Topic -> reconciled historical state
    + optional explicit successor adoption

erl-check
    ERL validation/recovery diagnostics
```

Optional orchestration:

```text
erl-book-vocabulary-extract
erl-book-vocabulary-ingest
```

```text
ERL-SKILL-001
Book-level orchestration не вводит новую semantics;
оно последовательно вызывает chapter-level workflow.
```

```text
ERL-SKILL-002
erl-check остаётся read-only diagnostic operation.
Исправление work state после Classic Reduce выполняет только
erl-classic-reduce-reconcile с explicit apply.
```

---

## 19. Validation

```text
ERL-CHECK-001
Все UUID из <ZETTELKASTEN_HOME>/.state/erl/works/ должны существовать как
соответствующие documents в <ZETTELKASTEN_HOME>/notes/,
если record не помечен как допустимая historical/tombstone relation.
```

```text
ERL-CHECK-002
Recorded role должен соответствовать canonical :type: и structural body contract.
```

```text
ERL-CHECK-003
Vocabulary role допускается только для Memo с valid lexical identity structure.
```

```text
ERL-CHECK-004
Occurrence role допускается только для Memo с ровно одной canonical Vocabulary link
в Vocabulary section и valid Context section.
```

```text
ERL-CHECK-005
В нормальном active состоянии Occurrence target должен быть active Vocabulary.
```

```text
ERL-CHECK-006
Если Occurrence target стал deprecated через supported Reduce workflow,
status = CLOSURE_REQUIRED.
```

```text
ERL-CHECK-007
CLOSURE_REQUIRED report показывает deprecated target,
dependent active documents, owning generations и рекомендуемый dry-run closure.
```

```text
ERL-CHECK-008
Сам факт Classic zt-reduce ERL-used Topic не является validation error.
Classic successor не считается ERL Book generation без explicit adoption.
```

```text
ERL-CHECK-009
Active canonical Vocabulary уникален по lexical identity.
```

```text
ERL-CHECK-010
Для одного WORK_ID существует не более одной active Book generation.
```

```text
ERL-CHECK-011
Chapter resolution record уникален по:
WORK_ID × SOURCE_ID × CHAPTER_LOCATOR.
```

```text
ERL-CHECK-012
EPUB source fingerprint соответствует ^sha256:[0-9a-f]{64}$.
Unsupported scheme требует explicit schema extension.
```

```text
ERL-CHECK-013
Sequence ordinals уникальны и упорядочены внутри generation.
```

```text
ERL-CHECK-014
Каждый sequence node ссылается на существующий Chapter UUID
и существующий Vocabulary/Occurrence UUID.
```

```text
ERL-CHECK-015
Deprecated documents не входят в active generation sequence.
```

```text
ERL-CHECK-016
erl-book-reduce не deprecated'ит durable Chapter Notes в обычном mutation set.
```

```text
ERL-CHECK-017
.state/erl/works/ должен быть достаточен для восстановления ERL semantics
без cache/ и staging/.
```

```text
ERL-CHECK-018
Незавершённая transaction journal обнаруживается и блокирует новую Reduce transaction.
```

```text
ERL-CHECK-019
Один EXTRACTION_ID не имеет более одного completed ingestion receipt.
```

```text
ERL-CHECK-020
ERL document не содержит plugin-specific AsciiDoc attributes :erl-*.
```

```text
ERL-CHECK-021
Book Topic содержит host-compatible :key-topic:, не используемый как WORK_ID,
и удовлетворяет canonical host Topic presentation contract для title logical work.
Missing Topic, wrong canonical type и wrong Book presentation диагностируются раздельно.
```

```text
ERL-CHECK-022
WORK_ID глобально уникален; ERL identifiers соответствуют lowercase UUID format.
```

```text
ERL-CHECK-023
Deprecated Book Topic не остаётся active-generation pointer;
external close отражается как GENERATION_CLOSED_EXTERNALLY.
```

```text
ERL-CHECK-024
Незарегистрированный Classic successor не считается ERL Book generation
и показывается в reconciliation diagnostics.
```

```text
ERL-CHECK-028
`erl-check` read-only проверяет exact Chapter key inheritance, reciprocal
Chapter–Memo attachment и полную linear reciprocal Chapter-local Memo Chain,
совпадающую с persistent sequence order.
```

```text
ERL-CHECK-025
После committed erl-book-reduce в .state/erl/works/ отсутствуют generation file,
manifest reference и active pointer каждой закрытой generation; compact committed
transaction manifest/result существует и достаточен для заявленного audit.
```

```text
ERL-CHECK-026
erl-check проверяет canonical target-home layout и выдаёт
HOME_LAYOUT_MIGRATION_REQUIRED при обнаружении nested vault/ без mutation.
```

```text
ERL-CHECK-027
erl-check read-only проверяет exact Chapter `:key-topic:`, единственную Chapter→Topic
link, reciprocal unique Topic→Chapter links, их source order и отсутствие двух
active Topic attachments для одной durable Chapter Note.
```

```text
ERL-CHECK-029
erl-check read-only проверяет uniqueness, reciprocity, current Chapter tail,
same-SOURCE_ID source-order adjacency, а также terminal/empty exceptions для
Chapter chain handoff. Diagnostic содержит generation/source/Chapter/tail UUID.
```

```text
ERL-CHECK-030
erl-check read-only проверяет ERL-DOC-008 для каждой зарегистрированной card.
Diagnostic содержит document UUID, recorded role и exact violated condition.
Legacy audit выполняется через erl-card-content-repair --dry-run; mutation
разрешена только с --apply, journal backup, hash conflict detection и rollback.
```

---

## 20. Git and shell safety

```text
ERL-GIT-001
Git является основной историей source code plugin.
Mass mutation Vault/work-state выполняется только после preflight working tree policy.
```

```text
ERL-GIT-002
Не выполнять destructive reset и не уничтожать локальные изменения.
```

```text
ERL-GIT-003
Migration schema .state/erl/works/ отделяется от обычного refactoring.
```

```text
ERL-GIT-004
ERL source repository и публикуемые skill distributions не содержат platform-
или editor-generated metadata artifacts, включая .DS_Store. Repository ignore
policy предотвращает их случайное добавление, а validation проверяет physical
distribution tree независимо от Git tracking и сохраняет запрет существующих
skill installation artifacts.
```

```text
ERL-SHELL-001
Основной shell ERL scripts — zsh.
```

```text
ERL-SHELL-002
Использовать quoting, predictable exit codes, проверку пустого ввода,
не использовать hard-coded absolute paths и cut -b для пользовательского текста.
```

```text
ERL-SHELL-003
Учитывать macOS/Linux там, где это относится к shared host/tooling contracts.
```

```text
ERL-SHELL-004
Каждый shell script и каждая sourceable shell library, принадлежащие ERL,
обязаны использовать расширение .zsh в имени файла. Это относится к public CLI,
internal utilities, development checks, libraries и test scripts ERL.

Skill/operation identifiers сохраняют имена без расширения, но canonical executable
path всегда имеет форму .scripts/erl/<command>.zsh. Extensionless executable wrappers
и дублирующие копии ERL scripts запрещены.
```

```text
ERL-SHELL-005
После обязательного shebang каждый ERL Zsh-файл содержит индивидуальный header
из пяти comment lines: opening separator, полное имя файла, принадлежность в поле
«Тип», назначение и функция в поле «Назначение», closing separator.

Формат separator: #------------------------------------------------------------------------------
```

```text
ERL-TEST-001
Каждый ERL OpenSpec delta change имеет primary test
tests/erl-<behavior-slug>.zsh. Behavioral slug получается удалением ровно одного
leading fix-/add-/change-/update-/migrate-/refactor-/implement-/remove-, после
чего добавляется erl-;
без известного change-kind prefix erl- добавляется к полному change name.
Дополнительные focused tests не заменяют primary test.
```

```text
ERL-TEST-002
Regression-test naming validation различает незавершённый change и change со
всеми выполненными implementation tasks. Отсутствующий primary test не блокирует
repository suite для change с невыполненными tasks, но является validation
failure до признания change завершённым и блокирует archive. Diagnostic содержит
change name и exact expected test path. Planning-only исключение не отменяет
deterministic naming contract ERL-TEST-001: tasks каждой дельты явно требуют
создать или обновить derived primary test и запустить его до completion.
```

```text
ERL-AGENT-SETUP-001
Tracked .scripts/erl/dev/erl-openclaw-agent-setup.zsh является self-contained
versioned source of truth для ignored локального OpenClaw workspace Lexi и не
зависит от уже materialized agent files.
```

```text
ERL-AGENT-SETUP-002
Successful setup materializes root agent files, Lexi runtime documentation и
ровно семь поддерживаемых ERL runtime skills вместе с required references.
```

```text
ERL-AGENT-SETUP-003
Workspace path, user name и timezone задаются явно или разрешаются локально;
payload не содержит credentials, tokens, session history, channel bindings и
не изменяет global OpenClaw configuration.
```

```text
ERL-AGENT-SETUP-004
Default setup выполняет non-mutating dry-run, --check выполняет non-mutating
integrity validation, а mutation разрешена только через explicit --apply.
```

```text
ERL-AGENT-SETUP-005
Apply idempotent, сохраняет совпадающие files без rewrite и блокирует conflicts.
Replacement допускается только через --replace-managed --apply после backup;
unknown target files не удаляются.
```

```text
ERL-AGENT-SETUP-006
Setup prevalidates staging, журналирует mutation, выполняет reverse rollback при
failure и публикует completed openclaw-workspace-state.json последним.
```

```text
ERL-AGENT-SETUP-007
Materialized Lexi infrastructure остаётся ignored, проходит manifest/hash,
skill/reference, distribution-artifact и safety-policy validation.
```

```text
ERL-AGENT-SETUP-008
Embedded skill payload проходит development synchronization с текущими
reference Lexi skills по exact relative file set и byte-exact content. Missing,
extra, changed и symlink paths блокируют Change completion и archive. Runtime
setup в fresh checkout не зависит от наличия reference skills directory.
```

```text
OS-ARCHIVE-001
OpenSpec Change архивируется только после завершения implementation, verification
и specification validation. Любое незавершённое условие блокирует archive.
```

```text
OS-ARCHIVE-002
Все applicable delta specifications синхронизируются в canonical
openspec/specs/ до признания archive завершённым; canonical baseline после
синхронизации проходит validation.
```

```text
OS-ARCHIVE-003
Archive сохраняет полный Change: proposal, design, tasks и все applicable delta
specifications под openspec/changes/archive/.
```

```text
OS-ARCHIVE-004
Archived delta specifications являются только historical records и не
используются как current source of truth.
```

```text
OS-ARCHIVE-005
openspec/specs/ является единственным source of truth текущих system requirements;
active и archived Change artifacts не заменяют canonical baseline.
```

Предпочтительные инструменты:

```text
zsh git grep rg fd fzf awk sed jq yq uuidgen asciidoctor shellcheck vim
```

---

## 21. OpenSpec archive governance

Pre-archive readiness проверяется ERL development checker после завершения tasks:

```bash
.scripts/erl/dev/erl-openspec-archive-check.zsh --pre --change CHANGE_NAME
```

После штатного `openspec archive` проверяются archive completeness,
delta-to-baseline synchronization и canonical validation:

```bash
.scripts/erl/dev/erl-openspec-archive-check.zsh --post \
  --archive openspec/changes/archive/YYYY-MM-DD-CHANGE_NAME
```

---

## 22. Canonical invariants

```text
Vault document
= canonical Topic / Note / Memo
= host-defined attributes only
```

```text
Book Topic UUID
= semantic processing generation identity
```

```text
WORK_ID
= stable logical-work identity
= stored only in .state/erl/works/
```

```text
Chapter UUID
= durable Vault identity of source Chapter
```

```text
Vocabulary
= canonical Memo
= global active lexical knowledge
```

```text
Occurrence
= canonical Memo
= context node linking to active Vocabulary
```

```text
processing scope
= active Book Topic UUID × Chapter UUID
```

```text
ERL source of truth
= Vault documents + .state/erl/works/
```

```text
.state/erl/works/
= persistent domain state
!= disposable runtime cache
```

```text
.state/erl/staging/
= intermediate model/extraction data
```

```text
.state/erl/transactions/
= Reduce/recovery journal
```

```text
Classic zt-reduce
= supported host-level Reduce with Topic seed
= never directly seeds an individual Memo or Note
```

```text
erl-book-reduce
= generation-aware, dependency-aware, transactional Reduce
= may deprecate registered Topic and Memo
= never automatically deprecates canonical Note
```

```text
wide cross-book dependency closure
= expected ERL feature
= always previewed explicitly before cascade
```

```text
Zettelkasten Vault
= storage/object contracts

Classic Zettelkasten
= workflow A

English Reading Lab
= workflow B + persistent ERL work state
```
