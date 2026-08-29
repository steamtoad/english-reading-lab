# English Reading Lab — CLI Contract v1

## 1. Назначение

`.scripts/erl/` предоставляет детерминированный machine-oriented CLI для ERL skills.

Граница ответственности:

```text
Lexi skill
    semantic reasoning
    orchestration
    model interaction

.scripts/erl/
    validation
    state resolution
    deterministic mutation
    transaction handling
    reports

.scripts/objects/
    canonical Topic / Note / Memo creation
```

CLI не выполняет model inference.

CLI не вызывает `zcreate`.

CLI не source'ит `.scripts/zettelkasten/`.

---

## 2. Public commands v1

```text
.scripts/erl/
├── erl-book-ingest
├── erl-chapter-export
├── erl-extraction-stage
├── erl-vocabulary-ingest
├── erl-chapter-vocabulary-ingest
├── erl-book-reduce
├── erl-classic-reduce-reconcile
└── erl-check.zsh
```

Дополнительные recovery commands можно выделить после стабилизации transaction contract:

```text
erl-transaction-status
erl-transaction-recover
erl-transaction-rollback
```

Они не являются Lexi skills.

---

## 3. Skill → CLI mapping

```text
erl-book-ingest skill
    -> erl-book-ingest

erl-chapter-vocabulary-extract skill
    -> erl-chapter-export
    -> Lexi/model extraction
    -> erl-extraction-stage

erl-vocabulary-ingest skill
    -> erl-vocabulary-ingest

erl-chapter-vocabulary-ingest skill
    -> erl-chapter-vocabulary-ingest

erl-book-reduce skill
    -> erl-book-reduce

erl-classic-reduce-reconcile skill
    -> erl-classic-reduce-reconcile

erl-check skill
    -> erl-check.zsh
```

Таким образом semantic extraction не переносится в shell implementation.

---

# 4. Общий invocation contract

Все команды запускаются как обычные executables:

```bash
${ERL_HOME}/.scripts/erl/erl-check.zsh
```

Для agent-facing invocation сначала разрешается `ERL_HOME`, затем проверяются
repository markers `AGENTS.MD` и `.scripts/erl/docs/requirements.md`. После этого
каждая команда вызывается только как `${ERL_HOME}/.scripts/erl/<command>`.
PATH lookup не является canonical agent protocol и не используется Lexi.

## Общие options

Где применимо:

```text
--vault DIR
--json
--dry-run
--apply
--help
```

Все mutating commands v1 требуют ровно один явный режим:

```text
--dry-run | --apply
```

Отсутствие обоих режимов и их одновременное использование являются usage error.
Read-only commands (`erl-chapter-export`, `erl-check.zsh`) не принимают эти modes.

### `--vault DIR`

Явно задаёт root canonical Vault.

При отсутствии:

```text
1. $ERL_VAULT
2. auto-detection
3. error
```

Auto-detection не должен использовать hard-coded absolute path.

### `--json`

Machine-readable response в stdout.

Lexi всегда вызывает deterministic commands с:

```bash
--json
```

Human-readable output остаётся default для ручной работы.

### stdout / stderr

В `--json` mode:

```text
stdout = ровно один JSON document
stderr = только process/runtime diagnostics
```

Никаких progress messages в stdout.

---

# 5. JSON response envelope

Все команды в `--json` mode возвращают:

```json
{
  "schema_version": 1,
  "command": "erl-check",
  "status": "ok",
  "code": "OK",
  "changed": false,
  "data": {},
  "diagnostics": []
}
```

Обязательные поля:

```text
schema_version
command
status
code
changed
data
diagnostics
```

## status

```text
ok
warning
blocked
error
```

## diagnostics

```json
{
  "severity": "error",
  "code": "ERL-CHECK-005",
  "message": "Occurrence points to deprecated Vocabulary",
  "document_uuid": "..."
}
```

`diagnostics[].code` по возможности использует requirement identifier.

---

# 6. Process exit status

Process exit status описывает класс результата.

Semantic detail находится в JSON `code`.

```text
0   successful operation / successful dry-run
2   invalid CLI usage
10  invalid input or validation failure
20  requested entity not found
30  state conflict
40  operation blocked by ERL invariant
50  filesystem / external tool error
60  transaction / recovery error
70  unexpected internal error
```

Идемпотентный повтор не является ошибкой:

```text
exit = 0
status = ok
code = ALREADY_INGESTED
ALREADY_STAGED
changed = false
```

Это важнее, чем выделять отдельный process exit code для каждого domain status.

---

# 7. Common semantic codes

Минимальный vocabulary:

```text
OK
NO_CHANGES
ALREADY_INGESTED

NOT_FOUND
INVALID_INPUT
VALIDATION_FAILED
STATE_CONFLICT

CLOSURE_REQUIRED
DEPENDENCIES_REQUIRED
GENERATION_CLOSED_EXTERNALLY
PENDING_TRANSACTION
RECOVERY_REQUIRED

IO_ERROR
TRANSACTION_FAILED
INTERNAL_ERROR
```

CLI process codes остаются стабильными даже при добавлении новых semantic codes.

---

# 8. `erl-book-ingest`

Назначение:

```text
source book
    ->
logical work / source state
    +
Book Topic generation
    +
durable Chapter Notes
```

Пример:

```bash
erl-book-ingest \
  --source books/book.epub \
  --title "Example Book" \
  --key-topic "English Reading" \
  --policy-file policies/c1-c2-v1.json \
  --apply \
  --json
```

Для новой edition существующего logical work:

```bash
erl-book-ingest \
  --source books/book-second-edition.epub \
  --work-id "$WORK_ID" \
  --policy-file policies/c1-c2-v1.json \
  --apply \
  --json
```

Предлагаемые arguments:

```text
--source FILE             required
--title TEXT              required для нового WORK_ID
--key-topic TEXT          required при создании Book Topic
--policy-file FILE        required при создании generation
--work-id UUID            optional
--work-slug SLUG          optional human locator
--dry-run
--apply
--json
```

`WORK_ID` и `SOURCE_ID` CLI генерирует сам при apply.

Vault UUID генерирует только canonical host constructor.

Dry-run не генерирует случайные persistent identifiers: вместо фиктивных значений он возвращает `null` и признаки `will_generate_work_id` / `will_generate_source_id`. Это сохраняет повторяемость dry-run при неизменном filesystem state.

### Dry-run

Показывает:

```text
new/existing WORK_ID
new SOURCE_ID
source fingerprint
resolved Chapters
planned Topic
planned Notes
planned state files
```

Не создаёт documents или persistent state.

### Response

```json
{
  "schema_version": 1,
  "command": "erl-book-ingest",
  "status": "ok",
  "code": "OK",
  "changed": true,
  "data": {
    "work_id": "...",
    "source_id": "...",
    "generation_uuid": "...",
    "source_fingerprint": "sha256:...",
    "chapter_count": 27,
    "created": {
      "topics": 1,
      "notes": 27
    }
  },
  "diagnostics": []
}
```

---

# 9. `erl-chapter-export`

Это read-only bridge между Vault/state и Lexi extraction skill.

Он не является отдельным ERL skill.

Назначение:

```text
generation UUID + Chapter UUID
    ->
validated extraction context
```

Invocation:

```bash
erl-chapter-export \
  --generation "$BOOK_TOPIC_UUID" \
  --chapter "$CHAPTER_UUID" \
  --json
```

Arguments:

```text
--generation UUID
--chapter UUID
--json
```

Команда проверяет:

```text
generation существует;
generation active;
Chapter существует;
Chapter зарегистрирована для logical work/source;
processing scope корректен.
```

Response:

```json
{
  "schema_version": 1,
  "command": "erl-chapter-export",
  "status": "ok",
  "code": "OK",
  "changed": false,
  "data": {
    "work_id": "...",
    "source_id": "...",
    "generation_uuid": "...",
    "chapter_uuid": "...",
    "chapter_locator": "OEBPS/chapter-03.xhtml",
    "source_order": 3,
    "policy": {
      "identity": "sha256:...",
      "schema_version": 1,
      "threshold": ["C1", "C2"],
      "lexical_types": ["word", "phrase", "phrasal_verb", "idiom", "collocation", "fixed_expression"],
      "selection_rules": [],
      "exclusions": [],
      "proper_name_policy": "exclude_unless_lexically_relevant",
      "uncertainty_policy": "include_with_confidence",
      "enrichment_requirements": {
        "ipa": true,
        "translation_ru": true,
        "definition_en": true,
        "sense_gloss": true,
        "cefr": true,
        "register": true,
        "rarity": true,
        "labels": true,
        "semantic_relations": true,
        "collocations": true
      }
    },
    "content": "..."
  },
  "diagnostics": []
}
```

`content` предназначен только для текущего model invocation, рассматривается как недоверенные данные и не становится persistent `works/` data, логом skill или частью prompt-инструкций.

`policy` содержит полный immutable semantic contract generation, а не только identity.
Структура соответствует `schemas/extraction-policy-v1.schema.json`. CLI проверяет,
что SHA-256 canonical policy payload без поля `identity` соответствует
`policy.identity`.

---

# 10. `erl-extraction-stage`

Принимает semantic result от Lexi.

```text
Lexi/model Candidates
    ->
validation
    ->
.state/erl/staging/
```

Invocation:

```bash
erl-extraction-stage \
  --input extraction.json \
  --apply \
  --json
```

или Unix pipeline:

```bash
cat extraction.json |
erl-extraction-stage --input - --dry-run --json
```

Arguments:

```text
--input FILE|-
--dry-run
--apply
--json
```

Input:

```json
{
  "schema_version": 1,
  "generation_uuid": "...",
  "chapter_uuid": "...",
  "policy_identity": "sha256:...",
  "candidates": [
    {
      "ordinal": 1,
      "surface_form": "forlorn",
      "lemma": "forlorn",
      "pos": "adjective",
      "lexical_type": "word",
      "candidate_confidence": 0.94,
      "first_relevant_occurrence": {
        "text": "..."
      },
      "context": "...",
      "enrichment": {
        "ipa": "/fəˈlɔːn/",
        "translation_ru": ["покинутый", "унылый"],
        "definition_en": "Sad and abandoned or lonely.",
        "sense_gloss": "sad and abandoned",
        "cefr": {
          "value": "C1",
          "confidence": 0.82,
          "provenance": "model-estimate"
        },
        "register": ["literary"],
        "rarity": "uncommon",
        "labels": ["literary"],
        "semantic_relations": [],
        "collocations": []
      }
    }
  ]
}
```

CLI самостоятельно генерирует:

```text
EXTRACTION_ID
```

и не позволяет модели выбирать этот identifier.

Candidate соответствует `schemas/vocabulary-candidate-v1.schema.json`. `lemma`
содержит linguistic lemma от Lexi; deterministic normalization выполняет ingestion
CLI. Отдельное поле `normalized_lemma` запрещено. `candidate_confidence` и
`enrichment.cefr.confidence` имеют различную семантику. `sense_gloss` не входит
в canonical lexical identity.

CLI также вычисляет deterministic extraction fingerprint из generation UUID, Chapter UUID, policy identity и canonicalized Candidate payload. Повторная staging того же fingerprint возвращает существующий `EXTRACTION_ID` с `code = ALREADY_STAGED`, `changed = false` и не создаёт второй staging batch.

Validation минимум:

```text
generation active;
Chapter valid for generation;
policy identity matches generation;
candidate ordinal unique and ordered;
required lexical fields non-empty;
no persistent Vault mutation.
```

Response:

```json
{
  "schema_version": 1,
  "command": "erl-extraction-stage",
  "status": "ok",
  "code": "OK",
  "changed": true,
  "data": {
    "extraction_id": "...",
    "generation_uuid": "...",
    "chapter_uuid": "...",
    "candidate_count": 18
  },
  "diagnostics": []
}
```

---

# 11. `erl-vocabulary-ingest`

Ингестит один уже staged Candidate.

Не принимает arbitrary generated Memo body как authoritative input.

Invocation:

```bash
erl-vocabulary-ingest \
  --extraction-id "$EXTRACTION_ID" \
  --candidate 4 \
  --apply \
  --json
```

Arguments:

```text
--extraction-id UUID
--candidate INTEGER
--dry-run
--apply
--json
```

Алгоритм:

```text
load Candidate
-> normalize lexical identity
-> lookup active Vocabulary
-> none:
       create canonical Vocabulary Memo
       role = vocabulary
-> exists:
       create canonical Occurrence Memo
       role = occurrence
-> append generation sequence node
-> update persistent state
```

Document creation выполняется только через canonical object constructor.

### Vocabulary result

```json
{
  "data": {
    "role": "vocabulary",
    "document_uuid": "...",
    "lexical_identity": {
      "lemma": "forlorn",
      "pos": "adjective",
      "lexical_type": "word"
    },
    "sequence_ordinal": 41
  }
}
```

### Occurrence result

```json
{
  "data": {
    "role": "occurrence",
    "document_uuid": "...",
    "vocabulary_uuid": "...",
    "sequence_ordinal": 41
  }
}
```

---

# 12. `erl-chapter-vocabulary-ingest`

Batch orchestration над staged extraction.

Invocation:

```bash
erl-chapter-vocabulary-ingest \
  --extraction-id "$EXTRACTION_ID" \
  --apply \
  --json
```

Arguments:

```text
--extraction-id UUID
--dry-run
--apply
--json
```

Dry-run показывает ordered plan:

```text
candidate ordinal
lexical identity
decision: vocabulary | occurrence
existing Vocabulary UUID if applicable
prospective sequence ordinal
```

Apply:

```text
Candidate 1
Candidate 2
...
Candidate N
-> completed ingestion receipt
```

Batch ingestion использует generation/extraction lock и durable receipt state
`pending | applying | completed | failed`. Для каждого Candidate хранится receipt key
`EXTRACTION_ID × candidate ordinal`. CLI, а не skill, классифицирует результат:

```text
ALREADY_INGESTED    success, changed=false
PENDING_TRANSACTION stop; автоматически не повторять mutation
RECOVERY_REQUIRED   stop; передать управление recovery workflow
STATE_CONFLICT      stop; persistent state изменился относительно плана
VALIDATION_FAILED   stop; input или invariant не прошёл validation
```

После interruption повторный запуск либо безопасно продолжает batch по per-candidate
receipts, либо возвращает `RECOVERY_REQUIRED`; уже зарегистрированные документы
не создаются повторно.

Completed `EXTRACTION_ID` при повторном запуске:

```json
{
  "status": "ok",
  "code": "ALREADY_INGESTED",
  "changed": false
}
```

Никаких duplicate documents.

Response:

```json
{
  "data": {
    "extraction_id": "...",
    "chapter_uuid": "...",
    "created_vocabulary": 7,
    "created_occurrences": 11,
    "sequence_from": 34,
    "sequence_to": 51,
    "receipt_status": "completed"
  }
}
```

---

# 13. `erl-book-reduce`

Это destructive lifecycle command.

В v1 он **не мутирует ничего без explicit `--apply`**.

Dry-run:

```bash
erl-book-reduce \
  --generation "$BOOK_TOPIC_UUID" \
  --dry-run \
  --json
```

Несколько seeds:

```bash
erl-book-reduce \
  --generation "$GEN_A" \
  --generation "$GEN_B" \
  --dry-run \
  --json
```

Arguments:

```text
--generation UUID         repeatable
--include-dependencies
--plan-fingerprint sha256:<64 lowercase hex> required with --apply
--dry-run
--apply
--json
```

`--dry-run` и `--apply` mutually exclusive.

Без одного из них v1 возвращает usage error.

### Dry-run всегда вычисляет fixed-point closure

Успешный dry-run возвращает deterministic `plan_fingerprint`, вычисленный по
canonical mutation plan и preflight hashes. Apply требует:

```text
--plan-fingerprint sha256:<64 lowercase hex>
```

Если state/filesystem изменились или fingerprint не совпадает, apply возвращает
`STATE_CONFLICT` до начала transaction.

Apply обязан commit'ить ровно тот semantic plan, который представлен переданным
`plan_fingerprint`. Seed generations, их порядок, `--include-dependencies` и все
прочие semantic arguments apply должны совпадать с последним принятым dry-run;
единственные protocol differences — замена `--dry-run` на `--apply` и добавление
`--plan-fingerprint`. Если пользователь подтвердил dependency closure, свежий
dry-run и apply оба содержат `--include-dependencies`.

Если closure шире seeds, успешный dry-run возвращает process exit `0`, `status = warning`, `code = DEPENDENCIES_REQUIRED`. Это отчёт, а не отказ вычисления. Попытка `--apply` без `--include-dependencies` в таком состоянии возвращает exit `40`, `status = blocked`, `code = DEPENDENCIES_REQUIRED`.

Response:

```json
{
  "status": "warning",
  "code": "DEPENDENCIES_REQUIRED",
  "changed": false,
  "data": {
    "seed_generations": ["..."],
    "closure_generations": ["...", "...", "..."],
    "additional_generations": ["...", "..."],
    "targets": [
      {
        "uuid": "...",
        "type": "memo",
        "role": "vocabulary",
        "reason": "reducible_generation_member"
      },
      {
        "uuid": "...",
        "type": "topic",
        "role": "book",
        "reason": "occurrence_dependency_closure"
      }
    ]
  }
}
```

Если closure шире seeds:

```text
--apply
```

без:

```text
--include-dependencies
```

не допускается.

### Apply

Перед первой mutation:

```text
create TXID
create transaction journal
record plan
record hashes
backup all affected Vault/state files
```

Затем:

```text
mutation
post-validation
commit
```

При ошибке:

```text
rollback
```

Chapter Note никогда не входит в automatic mutation target.

После commit generation-specific state закрытых generations удаляется из `works/`.

Compact committed transaction result остаётся для audit.

---

# 14. `erl-classic-reduce-reconcile`

Команда требует ровно один режим: `--dry-run` или `--apply`. Default mutation отсутствует.

Invocation:

```bash
erl-classic-reduce-reconcile \
  --generation "$OLD_BOOK_TOPIC_UUID" \
  --dry-run \
  --json
```

Apply:

```bash
erl-classic-reduce-reconcile \
  --generation "$OLD_BOOK_TOPIC_UUID" \
  --apply \
  --json
```

Optional successor adoption:

```bash
erl-classic-reduce-reconcile \
  --generation "$OLD_BOOK_TOPIC_UUID" \
  --adopt-successor "$NEW_TOPIC_UUID" \
  --apply \
  --json
```

Arguments:

```text
--generation UUID
--adopt-successor UUID
--dry-run
--apply
--json
```

Dry-run reports:

```text
old Book Topic;
deprecated status;
detected Classic successor;
current work-state status;
active generation conflicts;
CLOSURE_REQUIRED conditions;
planned state changes.
```

Apply may:

```text
record GENERATION_CLOSED_EXTERNALLY;
clear active generation pointer;
optionally create new generation record for explicit successor adoption.
```

Classic successor is never adopted implicitly.

---

# 15. `erl-check.zsh`

Always read-only.

Invocation:

```bash
erl-check.zsh --json
```

Optional scopes:

```bash
erl-check.zsh --work "$WORK_ID" --json
erl-check.zsh --generation "$BOOK_TOPIC_UUID" --json
erl-check.zsh --document "$UUID" --json
```

Arguments:

```text
--work UUID
--generation UUID
--document UUID
--json
```

No:

```text
--apply
--fix
```

in v1.

Example:

```json
{
  "status": "warning",
  "code": "CLOSURE_REQUIRED",
  "changed": false,
  "data": {
    "errors": 0,
    "warnings": 1
  },
  "diagnostics": [
    {
      "severity": "warning",
      "code": "ERL-CHECK-006",
      "message": "Active Occurrence depends on deprecated Vocabulary",
      "document_uuid": "...",
      "target_uuid": "...",
      "generation_uuid": "..."
    }
  ]
}
```

---

# 16. Dry-run rules

`--dry-run` означает строго:

```text
no Vault document mutation
no .state/erl/works mutation
no transaction commit
```

Для `erl-extraction-stage`:

```text
no staging write
```

Допускается:

```text
read files
parse source
compute hashes
resolve dependencies
construct plans in memory
emit reports
```

Dry-run должен быть повторяемым при неизменном filesystem state.

---

# 17. JSON input rules

Structured input:

```text
UTF-8
schema_version = 1
LF
```

Для больших payloads использовать:

```text
--input FILE
```

или:

```text
--input -
```

Не передавать JSON blob как shell argument.

Это уменьшает проблемы с quoting и ARG_MAX.

---

# 18. Mutation safety

Любая операция, меняющая одновременно:

```text
Vault documents
+
.state/erl/works/
```

считается multi-resource semantic mutation.

Она должна быть:

```text
recoverable
```

а для Reduce:

```text
all-or-rollback transactional
```

Persistent state writes:

```text
temporary file
-> validation
-> atomic rename
```

Никаких in-place partial JSON edits через `sed -i`.

---

# 19. CLI invariants

Каждая команда должна гарантировать:

```text
no :erl-* attributes
no zcreate
no sourcing .scripts/zettelkasten/
no WORK_ID stored in Vault metadata
no direct Chapter deprecation by erl-book-reduce
no active Occurrence -> deprecated Vocabulary creation
no duplicate completed EXTRACTION_ID ingestion
no implicit Classic successor adoption
no implicit cross-book Reduce cascade
```

---

# 20. Что намеренно не фиксируем в v1

Пока не стандартизируем:

```text
exact EPUB parser implementation;
exact staging filename layout;
exact Candidate context locator schema;
transaction journal internal file names;
human-readable report formatting;
cache/index implementation;
book-level extraction orchestration.
```

Это можно добавлять без изменения основного CLI protocol.

---

# 21. Минимальный Lexi workflow

Book:

```bash
erl-book-ingest ... --dry-run --json
erl-book-ingest ... --apply --json
```

Chapter extraction:

```bash
erl-chapter-export \
  --generation "$GEN" \
  --chapter "$CHAPTER" \
  --json
```

```text
Lexi performs semantic extraction
```

```bash
erl-extraction-stage \
  --input candidates.json \
  --apply \
  --json
```

Ingestion:

```bash
erl-chapter-vocabulary-ingest \
  --extraction-id "$EXTRACTION_ID" \
  --dry-run \
  --json
```

```bash
erl-chapter-vocabulary-ingest \
  --extraction-id "$EXTRACTION_ID" \
  --apply \
  --json
```

Validation:

```bash
erl-check.zsh --generation "$GEN" --json
```

Reduce:

```bash
erl-book-reduce \
  --generation "$GEN" \
  --dry-run \
  --json
```

а после подтверждения closure:

```bash
erl-book-reduce \
  --generation "$GEN" \
  --include-dependencies \
  --plan-fingerprint "$PLAN_FINGERPRINT" \
  --apply \
  --json
```

Главный API boundary v1:

```text
Lexi generates semantic data.

ERL CLI validates identities and invariants,
performs deterministic mutations,
and owns persistent state transitions.
```
