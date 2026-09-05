## Context

Runner пропускает падающий chapter-memo-chain test и два других behavioral entry point, при этом часть suites дублируется. Четыре tests зависят от различия /var и /private/var, а archive/skills prerequisites не документированы.

Аудит: `F10`, `A-TEST-GATE`; исходный baseline: `ERL-TEST-001`, `ERL-TEST-002`, `ERL-TEST-003`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Единый явный test manifest разделяет обязательные offline behavioral tests, static checks, test wrappers и opt-in live tests; валидатор ловит missing/unclassified entries.

### 2. Решение

Каждый mandatory behavioral suite запускается один раз, wrapper не добавляет скрытых дублей. Пока implementation tasks новой delta открыты, отсутствие её будущего primary test не считается завершённым change.

### 3. Решение

Нормализовать временные fixture roots и использовать переносимую проверку mtime/hash. Тесты сами предоставляют explicit test host и не зависят от реального home автора.

### 4. Решение

Документировать clean archive/checkout prerequisites и bootstrap test runtime skills; runner диагностирует missing Git/skills явно, без безымянного exit 128.

## Dependencies and sequencing

Нет обязательных prerequisites внутри этого набора.

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Test manifest может стать вторым источником drift: обязательна его проверка по physical test files.
- Live-routing SKIP нельзя суммировать как PASS.

## Migration and rollback

Runtime state и canonical specs meaning не меняются. Старые архивы сохраняются как history; не переписывать completed tasks, чтобы скрыть test debt.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-complete-test-suite-gate.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
