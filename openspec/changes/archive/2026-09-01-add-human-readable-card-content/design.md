## Context

Canonical host constructors уже создают Topic/Note/Memo в AsciiDoc, но ERL отдельно дописывает role content. Текущие Vocabulary и Occurrence имеют структурные blocks, Chapter получает минимальный `Source` block, а Book в основном полагается на presentation constructor. Формальная canonical type validity поэтому не гарантирует полезную для человека карточку.

Контракт должен охватить четыре роли, не вводя ERL-specific attributes и не превращая субъективную оценку качества текста в недетерминированную проверку.

## Goals / Non-Goals

**Goals:**

- дать всем четырём ролям общий минимальный readability contract;
- проверять детерминированные признаки валидного и содержательного AsciiDoc;
- сохранить существующие role-specific sections и canonical host metadata;
- безопасно выявлять legacy cards, требующие ручного или explicit repair.

**Non-Goals:**

- оценивать литературное качество, полноту пересказа или стиль текста;
- сохранять полный текст книги или главы в каждой карточке;
- разрешать ERL relationships через prose вместо persistent state;
- менять host constructors или canonical metadata contract.

## Decisions

### Readability is a deterministic structural floor

Проверка использует наблюдаемые признаки: UTF-8, parseable AsciiDoc, non-empty title/body, role-required sections/values, readable canonical link labels и отсутствие явно необработанных machine artifacts. Это минимальный floor, а не NLP-оценка качества. Альтернатива с субъективным scoring отклонена как нестабильная и непроверяемая.

### Role schemas refine one common document contract

`ERL-DOC-008` применяется ко всем cards, а `ERL-VOC-003` и `ERL-OCC-004` остаются специализированными contracts. Book body должен идентифицировать книгу и давать readable description/navigation; Chapter body — readable book/chapter context. Отдельные дублирующие schemas для каждого типа не вводятся.

### Machine data remains state, readable facts remain body

Persistent JSON state остаётся authoritative для ERL identity и lifecycle. В body могут показываться полезные технические факты с labels, но raw state/source dump не считается content. Это сохраняет разделение между human interface и machine state.

### Validation is read-only; repair is explicit

`erl-check` только диагностирует конкретную readability condition. Legacy audit формирует dry-run report и explicit repair plan. Repair сохраняет пользовательские sections, делает backup/journal перед mutation и блокируется при неоднозначном conflict вместо автоматической генерации или перезаписи текста.

## Risks / Trade-offs

- [Синтаксически valid AsciiDoc всё ещё может быть малоинформативным] → role-specific mandatory content задаёт минимальную полезность; более строгая редакционная оценка остаётся вне automated validation.
- [Raw JSON пример может быть осмысленной пользовательской заметкой] → запрещается machine dump, подменяющий обязательное content, а пользовательские supplemental source blocks не удаляются автоматически.
- [AsciiDoc engines различаются] → validation использует canonical host-supported subset и фиксированные positive/negative fixtures.
- [Legacy cards не проходят новый contract] → rollout начинается с read-only audit; repair выполняется только explicit operation с conflict reporting.

## Migration Plan

1. Создать primary regression test `tests/erl-human-readable-card-content.zsh` с positive fixtures всех четырёх ролей и negative fixtures readability conditions.
2. Нормализовать generation paths так, чтобы Book, Chapter, Vocabulary и Occurrence сразу получали role-relevant body.
3. Добавить `ERL-CHECK-030` в read-only validation и CLI diagnostics.
4. Добавить legacy audit/repair dry-run с backups, journal, conflict detection и explicit apply.
5. Обновить CLI contract и legacy requirements traceability.
6. Сначала выпустить validation/audit, затем отдельно применять repair к выбранным cards.

Rollback repair восстанавливает exact pre-mutation bytes из journal backup. Создание новых cards при failure использует существующий transaction rollback. Work state, UUID и document identity не мигрируются.
