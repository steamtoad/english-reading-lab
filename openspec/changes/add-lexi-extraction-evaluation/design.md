## Context

Routing smoke test проверяет выбор имени skill, а не полноту/точность лексики, CEFR, first occurrence или безопасное исполнение. Наличие Vocabulary означает существующую карточку, а не доказанное знание слова пользователем. Для длинных глав нужна проверяемая segmentation без квоты Candidates.

Аудит: `A-SEMANTIC-EVAL`, `A-KNOWN-WORDS`, `A-SEGMENTATION`, `A-MODEL-DATA-BOUNDARY`; исходный baseline: `ERL-CAND-003`, `ERL-CAND-004`, `ERL-CAND-010`, `ERL-PROC-008`, `ERL-SOURCE-004`, `ERL-AGENT-SETUP-010`, `ERL-AGENT-SETUP-011`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Версионированный redistributable corpus включает zero-candidate, ambiguity/polysemy, phrasal verbs, duplicates, cross-segment first occurrence, длинный текст и встраиваемые instruction-like fragments.

### 2. Решение

Metrics: precision/recall lexical identity относительно expert-reviewed gold/allowed alternatives, first-occurrence/order accuracy, duplicate rate, schema success, CEFR disagreement/uncertainty, доля ручных исправлений. Safety assertions отдельно требуют ноль неавторизованных mutations и exact Vault binding.

### 3. Решение

Freeze model/settings/policy/corpus и threshold policy до acceptance run. Первое baseline измерение не считается release acceptance; пропущенный live run не PASS. Offline evaluator тестируется recorded synthetic outputs без API.

### 4. Решение

Segmentation использует offsets/order и overlap policy, результат объединяется в одну Chapter extraction с global per-Chapter dedup и earliest relevant occurrence, без permanent segment entities и candidate quota.

### 5. Решение

README и отчёт Lexi говорят «уже представленная в словаре лексика», если нет модели пользовательского знания. SRS/learned-state не добавляется.

### 6. Решение

End-to-end controlled agent test проходит export→stage→ingest→same-Vault check в scratch environment; prompt-injection fixtures не должны менять scope/consent. Model provider logging/retention проверяется как deployment setting, private full texts не попадают в public eval artifacts.

## Dependencies and sequencing

- [fix-chapter-export-streaming](../fix-chapter-export-streaming/proposal.md)
- [fix-source-policy-provenance](../fix-source-policy-provenance/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-empty-chapter-ingestion](../fix-empty-chapter-ingestion/proposal.md)
- [fix-source-format-normalization](../fix-source-format-normalization/proposal.md)
- [add-durable-enrichment-provenance](../add-durable-enrichment-provenance/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- LLM nondeterminism требует повторов с записанными settings и неопределённостью; один успешный ответ не доказывает quality.
- Низкая полнота не исправляется скрытым снижением threshold или quota после acceptance run.

## Migration and rollback

Semantic output contract не переписывает старые generations. Material policy/segmentation changes требуют новой semantic generation по существующему baseline. Live harness явно opt-in и использует отдельно настроенные operator credentials без включения их в repo.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-lexi-extraction-evaluation.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
