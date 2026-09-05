## Purpose

Определить критерии проверенного выпуска ERL, полноту execution evidence, явные ограничения поддерживаемых профилей и безопасное обновление данных.

## ADDED Requirements

### Requirement: ERL-RELEASE-001 — Release gates aggregate complete reproducible evidence

Readiness gate MUST включать mandatory offline behavioral suite, strict OpenSpec validation, packaging/payload checks и regressions закрываемых audit findings. Evidence MUST привязываться к exact source/config versions; missing, stale или failed обязательный результат MUST блокировать readiness.

#### Scenario: General suite passes but safety regression fails

- **GIVEN** обычные tests зелёные, path-safety regression падает
- **WHEN** запускается release-check
- **THEN** итог SHALL быть FAIL с названным blocker

#### Scenario: Evidence belongs to an older source revision

- **GIVEN** после successful tests изменён runtime/contract
- **WHEN** строится readiness report
- **THEN** старый result SHALL помечаться stale и не закрывать текущий gate

### Requirement: ERL-RELEASE-002 — Readiness distinguishes verified and unavailable profiles

Beta/operational readiness MUST иметь явные criteria для safety, installation, host/platform compatibility, backup/restore, semantic quality и supported scale. Optional отсутствующий live run MUST быть SKIP/NOT VERIFIED; claims MUST ограничиваться фактически verified profiles.

#### Scenario: Live quality or real-host lane is unavailable

- **GIVEN** offline gate прошёл, обязательное для заявленного профиля live/host evidence отсутствует
- **WHEN** готовится readiness conclusion
- **THEN** неподтверждённый профиль SHALL быть blocked/not verified
- **AND** fixture PASS SHALL не заменять отсутствующее evidence

### Requirement: ERL-RELEASE-003 — Upgrade and rollback preserve supported data versions

Release documentation и drills MUST задавать backup, compatibility preflight, explicit migration, post-validation и безопасный rollback для поддерживаемых предыдущих versions. Unknown/too-new state или pending unsupported journal MUST блокировать upgrade/downgrade до записи.

#### Scenario: Upgrade encounters an unsupported pending journal

- **GIVEN** target содержит journal, неподдержанный новой либо старой версией
- **WHEN** оператор выполняет upgrade preflight
- **THEN** upgrade SHALL блокироваться с recover/backup action без удаления journal

#### Scenario: Upgrade fails after a supported migration

- **GIVEN** upgrade drill работает на копии Vault с проверенным backup
- **WHEN** инъецирован failure после migration
- **THEN** documented rollback/restore SHALL вернуть валидное согласованное состояние без смены UUID
