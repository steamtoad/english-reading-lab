STUDY-001 — одна книга = один каталог studies/<book-slug>/
STUDY-002 — главы именуются NNN-<real-chapter-title>.adoc
STUDY-003 — NNN отражает порядок главы в конкретном издании/источнике
STUDY-004 — настоящее название главы сохраняется в :chapter-title:
STUDY-005 — slug используется только для filename

DEV-001 — .claude/ является локальной инфраструктурой разработки.
DEV-002 — .claude/ полностью исключается из Git.
DEV-003 — Martin.agent.md не является частью runtime-конфигурации OpenClaw.
DEV-004 — публичный репозиторий не должен зависеть от содержимого .claude/.