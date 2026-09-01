## Context

Semantic selection выполняет skill, а deterministic staging принимает массив Candidates произвольной длины. Числового ограничения в CLI schema и staging implementation нет; контракт skill ранее лишь не запрещал модели усекать результат.

## Goals / Non-Goals

**Goals:**

- сделать отсутствие Chapter-level quota явной частью extraction contract;
- сохранить дедупликацию lexical identity и source order;
- оставить `candidate_count` наблюдаемой метрикой масштаба.

**Non-Goals:**

- менять extraction policy по уровню CEFR или lexical types;
- гарантировать одинаковый Candidate count между разными моделями;
- вводить сегментацию, новую state schema или host capability.

## Decisions

Ограничение снимается на semantic boundary в skill и нормативном контракте. CLI уже не задаёт maximum для массива `candidates`, поэтому новый runtime flag или schema migration не нужны.

Альтернатива с настраиваемым числовым лимитом отклонена: она сохраняла бы усечение и мешала цели эксперимента — увидеть полный масштаб проблемы.

## Risks / Trade-offs

- Более крупный Candidate batch увеличит model output и время ingestion → пользователь выбирает короткую контрольную книгу, а `candidate_count` позволяет измерить нагрузку.
- Model context может стать практическим пределом для необычно длинной Chapter → это operational warning, но не допустимая semantic quota; временная сегментация остаётся отдельным будущим механизмом.

## Migration Plan

Обновить contract и skill, затем проверить primary regression test `tests/erl-chapter-vocabulary-quota.zsh`. Persistent data migration и rollback не требуются; rollback состоит в возврате contract wording.
