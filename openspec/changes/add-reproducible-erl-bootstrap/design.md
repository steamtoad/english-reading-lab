## Context

README не описывает путь от clean checkout до первой книги; setup/check ожидают host, Git и materialized skills. Личные defaults не заменяют переносимый explicit profile. Нужна диагностика готовности, а не автоматическая перенастройка пользовательской машины.

Аудит: `A-INSTALL`, `A-DOCTOR`, `A-ROOT-CONFIG`; исходный baseline: `ERL-ARCH-009`, `ERL-ARCH-010`, `ERL-AGENT-SETUP-001`, `ERL-AGENT-SETUP-003`, `ERL-AGENT-SETUP-009`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

README даёт минимальные dependencies, поддерживаемый layout и явные code/target/host roles; отдельные generic CLI и Lexi examples сохраняют exact --vault ERL_HOME для Lexi.

### 2. Решение

erl-doctor.zsh --vault DIR [--json] read-only проверяет canonical roots, markers, known host entry points, tools, versions/capabilities, writable policy без записи в target и pending setup/runtime diagnostics.

### 3. Решение

Default named local profile может сохранять текущие пути, но portable install принимает explicit values и не требует наличия каталогов автора. Forbidden user Vault остаётся запрещённым, конфигурация не теряет root-role guards.

### 4. Решение

Build embedded skill payload становится документированным reproducible command с source manifest/hash и byte-exact verification; generated ignored infrastructure не становится source baseline.

## Dependencies and sequencing

- [fix-work-state-path-safety](../fix-work-state-path-safety/proposal.md)
- [fix-cli-error-propagation](../fix-cli-error-propagation/proposal.md)
- [fix-runtime-schema-conformance](../fix-runtime-schema-conformance/proposal.md)
- [fix-complete-test-suite-gate](../fix-complete-test-suite-gate/proposal.md)

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Doctor не должен запускать constructor с побочными эффектами ради проверки.
- Source archive требует явного local Git/bootstrap test preparation, не имитации оригинальной истории.

## Migration and rollback

Current working profiles сохраняются без переписывания. Setup создаёт/заменяет managed файлы только через существующие dry-run/apply/replace-managed modes. Global OpenClaw config, credentials и agent registration остаются внешними действиями.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-reproducible-erl-bootstrap.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
