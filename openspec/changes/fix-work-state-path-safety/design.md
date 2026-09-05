## Context

Аудит воспроизвёл удаление заранее существовавшего файла вне Vault: --work-slug принимал traversal, а rollback удалял весь work_dir. Контроль должен распространяться также на paths из journals и результаты constructors.

Аудит: `F01`, `A-PATHS`; исходный baseline: `ERL-BOOK-004`, `ERL-STATE-013`, `ERL-GIT-002`, `ERL-SHELL-002`. Новые requirement IDs принадлежат только этой delta; другие deltas этого набора не заменяют эти же requirements.

## Goals / Non-Goals

**Goals:** выполнить observable acceptance в `specs/` и убрать перечисленные audit gaps.

**Non-Goals:** переписывать ERL на другой язык, добавлять БД/веб-платформу, менять canonical UUID или ссылки массово, изменять host core, запускать production migrations при подготовке спецификации.

## Decisions

### 1. Решение

Вынести единое разрешение допустимых write targets; canonical root и ближайший существующий ancestor проверяются до создания отсутствующих компонентов.

### 2. Решение

Новое имя slug использует одну документированную грамматику lowercase ASCII letters/digits/internal hyphens; существующие иные slug читаются по WORK_ID без неявного rename. UUID не зависит от slug.

### 3. Решение

Rollback удаляет только зарегистрированные как вновь созданные артефакты с ожидаемыми hashes; pre-existing directory не становится собственностью операции. Сведения о constructor result проверяются до append.

### 4. Решение

Проверку выполнять повторно непосредственно перед записью. Модель не заявляет защиту от враждебной одновременной смены symlink другим непривилегированным участником ОС без подходящего filesystem primitive; любые обнаруженные drift блокируются.

## Dependencies and sequencing

Нет обязательных prerequisites внутри этого набора.

Implementation начинается после обязательных prerequisites; независимые changes допускают отдельную реализацию. Перед apply/archive перечитать current canonical specs, проверить отсутствие concurrent contract drift и обновить delta при необходимости. Возможный перенос общего кода в `.scripts/erl/lib/` выполняется в owner delta соответствующего поведения, с сохранением public CLI и regression parity.

## Risks / Trade-offs

- Лексические сравнения префиксов недостаточны: /vault-two не вложен в /vault.
- Строгая грамматика применяется к новым slug, чтобы не сломать доступ к существующим works.

## Migration and rollback

State layout и UUID не меняются. Legacy journal с непроверяемым путём блокируется с диагностикой, исходные файлы сохраняются; конверсия выполняется отдельной explicit recovery procedure.

Новые state/journal representations требуют явной version policy и прочтения supported legacy. Backup, pre/post hashes, dirty-target policy и recovery должны соответствовать applied prerequisite contracts. До migration работающее состояние сохраняется; unspecified legacy не переинтерпретируется. Откат code-only изменения не должен молча читать новый state старой версией.

## Verification

Primary regression: `tests/erl-work-state-path-safety.zsh`. Tests используют disposable target и explicit test host; пользовательский Vault не является fixture. Негативные scenarios проверяют exit/envelope и pre/post inventories; structural text tests дополняют behavioral evidence. Для external/live/platform cases сохраняется NOT VERIFIED/SKIP до реального run; это не successful acceptance.

Implementation evidence хранит source/config versions, команды, результаты и применимые limitations. До completion выполнить strict delta validation, applicable complete suite и diff hygiene; перед архивированием выполнить штатные pre/post archive checks. Все tasks в этом planning change остаются открытыми до фактического исполнения.
