# План исправлений по аудиту ERL от 2026-09-05

Источник: [полный отчёт](../../audit/2026-09-05/7e56c022-a8fc-11f1-8322-b73dbdeee0d4.adoc). Baseline: `openspec/specs/`, commit `918ef5b`.

Подготовлены **20 planning deltas**. Они не меняют current canonical specs и не означают, что дефекты исправлены. Все implementation tasks открыты. Матрица связывает F01–F10, все 12 эксплуатационных областей и риски всех 25 скриптов/библиотек из отчёта. Машинная карта: [audit-2026-09-05-coverage.json](audit-2026-09-05-coverage.json).

## Порядок реализации и зависимости

Порядок ниже — допустимая топологическая последовательность, а не требование выполнять независимые changes строго друг за другом. P1 закрываются до допуска к ценным данным. Уровни 1 (патчи), 2 (локальный рефакторинг), 3 (система разработки/эксплуатации) не смешиваются с предлагаемой заменой архитектуры. Release gate реализуется последним.

| № | Дельта | Приоритет / уровень | Обязательные prerequisites |
|---|---|---|---|
| 1 | [Безопасные пути и владение артефактами rollback](fix-work-state-path-safety/proposal.md) | P1 / 1 | — |
| 2 | [Правдивые ошибки и JSON envelope](fix-cli-error-propagation/proposal.md) | P1 / 1 | — |
| 3 | [Полный и воспроизводимый тестовый запуск](fix-complete-test-suite-gate/proposal.md) | P2 / 1 | — |
| 4 | [Владение блокировками и безопасное освобождение](fix-mutation-lock-ownership/proposal.md) | P1 / 1 | `fix-work-state-path-safety` |
| 5 | [Полный экспорт длинной главы](fix-chapter-export-streaming/proposal.md) | P1 / 1 | `fix-cli-error-propagation` |
| 6 | [Единая проверка input и persistent contracts](fix-runtime-schema-conformance/proposal.md) | P1 / 2 | `fix-cli-error-propagation` |
| 7 | [Единый нормативный источник и трассировка аудита](fix-openspec-contract-authority/proposal.md) | P2 / 3 | `fix-complete-test-suite-gate` |
| 8 | [Сериализация пересекающихся мутаций](fix-cross-operation-mutation-serialization/proposal.md) | P1 / 2 | `fix-work-state-path-safety`, `fix-mutation-lock-ownership` |
| 9 | [Воспроизводимая установка и read-only диагностика](add-reproducible-erl-bootstrap/proposal.md) | P2 / 3 | `fix-work-state-path-safety`, `fix-cli-error-propagation`, `fix-runtime-schema-conformance`, `fix-complete-test-suite-gate` |
| 10 | [Полное восстановление и crash-consistency](fix-transaction-recovery-coverage/proposal.md) | P1 / 2 | `fix-work-state-path-safety`, `fix-cross-operation-mutation-serialization`, `fix-cli-error-propagation`, `fix-runtime-schema-conformance` |
| 11 | [Измерение производительности и границ масштаба](add-erl-performance-baseline/proposal.md) | P2 / 3 | `fix-complete-test-suite-gate`, `fix-chapter-export-streaming`, `fix-cross-operation-mutation-serialization` |
| 12 | [Проверяемая identity источника и policy](fix-source-policy-provenance/proposal.md) | P1 / 1 | `fix-cli-error-propagation`, `fix-chapter-export-streaming`, `fix-runtime-schema-conformance`, `fix-cross-operation-mutation-serialization`, `fix-transaction-recovery-coverage` |
| 13 | [Пустая глава и точный resume batch](fix-empty-chapter-ingestion/proposal.md) | P2 / 1 | `fix-cross-operation-mutation-serialization`, `fix-cli-error-propagation`, `fix-transaction-recovery-coverage` |
| 14 | [Безопасные AsciiDoc sections и сохранение ручных правок](fix-asciidoc-projection-safety/proposal.md) | P2 / 2 | `fix-work-state-path-safety`, `fix-cross-operation-mutation-serialization`, `fix-transaction-recovery-coverage` |
| 15 | [Стабильное чтение EPUB и поддерживаемых форматов](fix-source-format-normalization/proposal.md) | P2 / 1 | `fix-cli-error-propagation`, `fix-chapter-export-streaming`, `fix-source-policy-provenance` |
| 16 | [Сохранение полезного enrichment и происхождения оценок](add-durable-enrichment-provenance/proposal.md) | P2 / 3 | `fix-runtime-schema-conformance`, `fix-transaction-recovery-coverage`, `fix-asciidoc-projection-safety` |
| 17 | [Backup, восстановление Vault и операционная диагностика](add-erl-backup-restore/proposal.md) | P2 / 3 | `fix-work-state-path-safety`, `fix-cross-operation-mutation-serialization`, `fix-transaction-recovery-coverage`, `fix-source-policy-provenance`, `add-reproducible-erl-bootstrap` |
| 18 | [Проверяемая совместимость host и платформ](add-host-compatibility-certification/proposal.md) | P2 / 3 | `fix-runtime-schema-conformance`, `fix-source-format-normalization`, `fix-asciidoc-projection-safety`, `add-reproducible-erl-bootstrap` |
| 19 | [Измеримое качество извлечения и полный агентный сценарий](add-lexi-extraction-evaluation/proposal.md) | P2 / 3 | `fix-chapter-export-streaming`, `fix-source-policy-provenance`, `fix-runtime-schema-conformance`, `fix-empty-chapter-ingestion`, `fix-source-format-normalization`, `add-durable-enrichment-provenance` |
| 20 | [Критерии контролируемой беты и выпуска](add-release-readiness-gates/proposal.md) | P2 / 3 | Все 19 остальных deltas; полный список в proposal и JSON. |

## Подтверждённые finding IDs

| Аудит | Дельты |
|---|---|
| F01 | [fix-work-state-path-safety](fix-work-state-path-safety/proposal.md) |
| F02 | [fix-mutation-lock-ownership](fix-mutation-lock-ownership/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md) |
| F03 | [fix-cli-error-propagation](fix-cli-error-propagation/proposal.md) |
| F04 | [fix-cli-error-propagation](fix-cli-error-propagation/proposal.md), [fix-chapter-export-streaming](fix-chapter-export-streaming/proposal.md) |
| F05 | [fix-source-policy-provenance](fix-source-policy-provenance/proposal.md) |
| F06 | [fix-runtime-schema-conformance](fix-runtime-schema-conformance/proposal.md) |
| F07 | [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md) |
| F08 | [fix-empty-chapter-ingestion](fix-empty-chapter-ingestion/proposal.md) |
| F09 | [fix-source-format-normalization](fix-source-format-normalization/proposal.md) |
| F10 | [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md) |

## Функциональные и эксплуатационные области

| Область отчёта | Owner deltas |
|---|---|
| Установка | [add-reproducible-erl-bootstrap](add-reproducible-erl-bootstrap/proposal.md) |
| Host integration | [add-host-compatibility-certification](add-host-compatibility-certification/proposal.md) |
| Переносимость | [fix-source-format-normalization](fix-source-format-normalization/proposal.md), [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [add-host-compatibility-certification](add-host-compatibility-certification/proposal.md) |
| Source provenance | [fix-source-policy-provenance](fix-source-policy-provenance/proposal.md) |
| Извлечение | [add-lexi-extraction-evaluation](add-lexi-extraction-evaluation/proposal.md) |
| Пользовательская известность слов | [add-lexi-extraction-evaluation](add-lexi-extraction-evaluation/proposal.md) |
| Enrichment | [add-durable-enrichment-provenance](add-durable-enrichment-provenance/proposal.md) |
| Backup и restore | [add-erl-backup-restore](add-erl-backup-restore/proposal.md) |
| Операционное сопровождение | [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [add-reproducible-erl-bootstrap](add-reproducible-erl-bootstrap/proposal.md), [add-erl-backup-restore](add-erl-backup-restore/proposal.md) |
| Масштаб | [add-erl-performance-baseline](add-erl-performance-baseline/proposal.md) |
| Релизный процесс | [add-release-readiness-gates](add-release-readiness-gates/proposal.md) |
| Документация | [add-reproducible-erl-bootstrap](add-reproducible-erl-bootstrap/proposal.md), [fix-openspec-contract-authority](fix-openspec-contract-authority/proposal.md) |

## Риски по каждому скрипту

Каждая строка соответствует отдельной оценке в приложении аудита. Owner deltas содержат поведение, design и tests; отдельного бесконтрольного массового рефакторинга нет.

| Компонент | Owner deltas |
|---|---|
| `erl-book-ingest.zsh` | [fix-work-state-path-safety](fix-work-state-path-safety/proposal.md), [fix-cli-error-propagation](fix-cli-error-propagation/proposal.md), [fix-runtime-schema-conformance](fix-runtime-schema-conformance/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md) |
| `erl-book-reduce.zsh` | [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md) |
| `erl-book-title-key-topic-migrate.zsh` | [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md) |
| `erl-card-content-repair.zsh` | [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md), [add-durable-enrichment-provenance](add-durable-enrichment-provenance/proposal.md) |
| `erl-chapter-chain-handoff.zsh` | [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-empty-chapter-ingestion](fix-empty-chapter-ingestion/proposal.md), [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md) |
| `erl-chapter-export.zsh` | [fix-cli-error-propagation](fix-cli-error-propagation/proposal.md), [fix-chapter-export-streaming](fix-chapter-export-streaming/proposal.md), [fix-source-policy-provenance](fix-source-policy-provenance/proposal.md), [fix-source-format-normalization](fix-source-format-normalization/proposal.md) |
| `erl-chapter-memo-chain-migrate.zsh` | [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md) |
| `erl-chapter-topic-binding-migrate.zsh` | [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md) |
| `erl-chapter-vocabulary-ingest.zsh` | [fix-empty-chapter-ingestion](fix-empty-chapter-ingestion/proposal.md), [fix-cli-error-propagation](fix-cli-error-propagation/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md) |
| `erl-check.zsh` | [fix-runtime-schema-conformance](fix-runtime-schema-conformance/proposal.md), [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md), [add-erl-performance-baseline](add-erl-performance-baseline/proposal.md) |
| `erl-classic-reduce-reconcile.zsh` | [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md) |
| `erl-extraction-stage.zsh` | [fix-mutation-lock-ownership](fix-mutation-lock-ownership/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-runtime-schema-conformance](fix-runtime-schema-conformance/proposal.md), [fix-source-policy-provenance](fix-source-policy-provenance/proposal.md) |
| `erl-home-layout-migrate.zsh` | [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [add-host-compatibility-certification](add-host-compatibility-certification/proposal.md) |
| `erl-state-migrate.zsh` | [fix-runtime-schema-conformance](fix-runtime-schema-conformance/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md) |
| `erl-transaction-recover.zsh` | [fix-work-state-path-safety](fix-work-state-path-safety/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [add-erl-backup-restore](add-erl-backup-restore/proposal.md) |
| `erl-vocabulary-ingest.zsh` | [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md), [fix-empty-chapter-ingestion](fix-empty-chapter-ingestion/proposal.md), [add-durable-enrichment-provenance](add-durable-enrichment-provenance/proposal.md) |
| `erl-work-rename.zsh` | [fix-work-state-path-safety](fix-work-state-path-safety/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md), [fix-transaction-recovery-coverage](fix-transaction-recovery-coverage/proposal.md) |
| `lib/common.zsh` | [fix-work-state-path-safety](fix-work-state-path-safety/proposal.md), [fix-mutation-lock-ownership](fix-mutation-lock-ownership/proposal.md), [fix-cli-error-propagation](fix-cli-error-propagation/proposal.md), [fix-runtime-schema-conformance](fix-runtime-schema-conformance/proposal.md) |
| `lib/source.zsh` | [fix-source-policy-provenance](fix-source-policy-provenance/proposal.md), [fix-source-format-normalization](fix-source-format-normalization/proposal.md), [fix-chapter-export-streaming](fix-chapter-export-streaming/proposal.md) |
| `lib/chapter-memo-chain.zsh` | [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md) |
| `lib/card-content.zsh` | [fix-asciidoc-projection-safety](fix-asciidoc-projection-safety/proposal.md), [add-durable-enrichment-provenance](add-durable-enrichment-provenance/proposal.md) |
| `dev/erl-openclaw-agent-setup.zsh` | [add-reproducible-erl-bootstrap](add-reproducible-erl-bootstrap/proposal.md), [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [fix-cross-operation-mutation-serialization](fix-cross-operation-mutation-serialization/proposal.md) |
| `dev/erl-skills-check.zsh` | [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [fix-openspec-contract-authority](fix-openspec-contract-authority/proposal.md), [add-reproducible-erl-bootstrap](add-reproducible-erl-bootstrap/proposal.md) |
| `dev/erl-delta-test-naming-check.zsh` | [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [fix-openspec-contract-authority](fix-openspec-contract-authority/proposal.md) |
| `dev/erl-openspec-archive-check.zsh` | [fix-complete-test-suite-gate](fix-complete-test-suite-gate/proposal.md), [fix-openspec-contract-authority](fix-openspec-contract-authority/proposal.md), [add-release-readiness-gates](add-release-readiness-gates/proposal.md) |

## Инварианты набора

- UUID v1 canonical документов и UUID v4 ERL-local identifiers не смешиваются. Существующие UUID и ссылки не переименовываются без явной миграции.
- `notes/` плюс `.state/erl/works/` остаются source of truth. Backup включает обе части; indexes остаются производными.
- Current Lexi profile сохраняет exact `--vault ERL_HOME` и отделённый host root. Другие explicit profiles не должны требовать личных путей автора.
- БД, web UI, SRS, смена языка и массовая перестройка Vault не вводятся. Измеренный index bottleneck оформляется отдельной последующей delta.
- Разделение common.zsh на paths/locks/validation/transaction helpers выполняется только внутри owner deltas и сохраняет публичные contracts.
- Capability extensions оформлены как ADDED Requirements с уникальными IDs, чтобы несколько changes не перезаписывали один MODIFIED блок. Перед каждым archive нужно вновь проверить current baseline.
- Внешние model/platform/production-host проверки не считаются прошедшими без исполнения. Их отсутствие не мешает создать planning specification, но ограничивает последующую readiness.

## Проверка пакета

В подготовленном наборе проверяются strict OpenSpec validation, unique requirement IDs, dependency DAG, completeness F01–F10/12 областей/25 компонентов, наличие primary-test tasks, все-open status и работоспособность будущего additive baseline merge. Результаты authoring validation не являются runtime acceptance.

## Критерии завершения программы

Контролируемая бета: closed P1 + корректные empty/large/EPUB cases + полный offline test gate + documented clean install + реальный host contract test в scratch target + backup/restore drill. Эксплуатационная readiness дополнительно требует проверенной platform matrix, recovery/upgrade, model-quality evidence и measured supported scale. Конкретные quality/performance budgets фиксируются до acceptance run после отдельного baseline measurement.

Все deltas создаются без выполнения migration, без archive и без изменения baseline в рамках этой задачи.
