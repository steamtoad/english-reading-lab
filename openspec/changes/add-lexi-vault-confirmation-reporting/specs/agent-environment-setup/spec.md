## ADDED Requirements

### Requirement: ERL-AGENT-SETUP-010 — Mutation confirmation binds the exact Vault

Перед каждым L2 или L3 `--apply` Lexi MUST показать пользователю план, содержащий absolute canonical path фактического target Vault в отдельном поле `Vault`, и MUST дождаться отдельного явного подтверждения уже показанного плана. Для Lexi это поле MUST иметь resolved значение `${ERL_HOME}`.

После получения подтверждения и непосредственно перед mutation Lexi MUST повторно разрешить и проверить target Vault. Apply разрешён только если повторно полученный canonical path byte-for-byte совпадает с Vault подтверждённого плана, repository markers и target-home layout по-прежнему действительны, а применяемый plan относится к тому же Vault.

Если path, identity, markers или plan изменились, Lexi MUST отменить прежнее подтверждение, MUST NOT запускать `--apply` и MUST сформировать новый dry-run plan, который требует нового явного подтверждения.

#### Scenario: User confirms a Book ingest plan for the Lexi Vault

- **GIVEN** Book ingest dry-run разрешил `${ERL_HOME}` как `/Users/steamtoad/pub/english-reading-lab`
- **WHEN** Lexi запрашивает L2 confirmation
- **THEN** показанный план SHALL содержать `Vault: /Users/steamtoad/pub/english-reading-lab`
- **AND** Lexi SHALL NOT запускать `--apply` до отдельного явного подтверждения этого плана

#### Scenario: Vault remains unchanged after confirmation

- **GIVEN** пользователь явно подтвердил план с определённым absolute Vault path
- **WHEN** Lexi готовится выполнить `--apply`
- **THEN** Lexi SHALL повторно разрешить и проверить target Vault
- **AND** invocation SHALL использовать тот же canonical path через `--vault "${ERL_HOME}"`

#### Scenario: Vault changes after confirmation

- **GIVEN** пользователь подтвердил план для одного Vault
- **WHEN** pre-apply revalidation получает другой path, изменённую identity, недействительные markers либо plan другого Vault
- **THEN** Lexi SHALL NOT выполнять mutation
- **AND** прежнее подтверждение SHALL считаться недействительным
- **AND** новый dry-run plan SHALL требовать нового явного подтверждения

### Requirement: ERL-AGENT-SETUP-011 — Post-mutation validation and report use the confirmed Vault

После успешного mutation Lexi MUST запустить canonical `${ERL_HOME}/.scripts/erl/erl-check.zsh` с exact `--vault "${ERL_HOME}"` и наиболее широким изменённым semantic scope. Для Book workflow с известным `WORK_ID` invocation MUST содержать `--work "${WORK_ID}" --json`.

Lexi MUST сверить, что проверяемый Vault совпадает с Vault подтверждённого и применённого plan. Итоговый отчёт MUST явно содержать absolute фактический Vault, validation scope и результат `erl-check`. Lexi MUST NOT сообщать об успешной материализации, если post-check не был выполнен для того же Vault, завершился ошибкой либо обнаружил несоответствие scope.

#### Scenario: Book ingest is checked in the same Vault

- **GIVEN** Book ingest был применён к `${ERL_HOME}` и вернул `WORK_ID`
- **WHEN** Lexi выполняет post-mutation validation
- **THEN** invocation SHALL быть эквивалентен `${ERL_HOME}/.scripts/erl/erl-check.zsh --vault "${ERL_HOME}" --work "${WORK_ID}" --json`
- **AND** Lexi SHALL проверить, что `${ERL_HOME}` совпадает с Vault подтверждённого plan

#### Scenario: Final success report identifies the actual Vault

- **GIVEN** mutation и post-check того же Vault успешно завершились
- **WHEN** Lexi формирует итоговый отчёт
- **THEN** отчёт SHALL содержать absolute фактический Vault
- **AND** отчёт SHALL содержать проверенный `WORK_ID` или иной validation scope
- **AND** отчёт SHALL содержать результат `erl-check`

#### Scenario: Post-check targets another Vault

- **GIVEN** mutation была применена к подтверждённому Vault
- **WHEN** post-check настроен на другой Vault либо не может доказать identity проверяемого Vault
- **THEN** Lexi SHALL NOT сообщать об успешном завершении
- **AND** SHALL сообщить validation failure с обоими известными paths без автоматической повторной mutation
