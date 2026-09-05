## Why

Неявная квота на число Vocabulary Candidates в Chapter скрывает реальный масштаб lexical extraction и мешает оценить объём последующей обработки на короткой контрольной книге.

## What Changes

- Default extraction policy анализирует Chapter целиком и не ограничивает число подходящих Candidates квотой на Chapter.
- Один lexical identity по-прежнему создаёт не более одного Candidate в Chapter.
- Фактическое число Candidates остаётся наблюдаемым в результате extraction.

## Capabilities

### New Capabilities

Нет.

### Modified Capabilities

- `vocabulary-extraction`: добавляется явная гарантия отсутствия количественной квоты на Candidates внутри Chapter.

## Impact

Изменяются ERL OpenSpec, legacy traceability, skill `erl-chapter-vocabulary-extract` и его contract test. CLI schema, persistent state, host contract и Vault documents не изменяются. Миграция и destructive operations не требуются.
