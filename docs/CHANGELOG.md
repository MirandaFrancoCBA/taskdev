# TaskDev delivery history

This changelog records shipped project work and its GitHub attribution. It complements the in-product `TaskActivity` audit trail, which records changes to individual tasks.

## Attribution convention

For each shipped change, record the release/date, linked issue and pull request, a short delivery summary, and the author/contributors shown by GitHub. Do not infer or invent authorship when GitHub does not provide reliable attribution.

## v1.0.0 — stable MVP

TaskDev v1.0.0 established the mobile-first shared task workflow, server-side authorization, transactional claiming, realtime invalidation through Channels/Redis, and the validated two-client browser flow.

### 2026-09-26

- PR #60 / Issue #59 — Documented the successful final two-client browser smoke validation and standardized local ASGI startup on Daphne. Author: Franco Rodrigo Miranda (`MirandaFrancoCBA`).
- PR #58 / Issue #57 — Fixed Redis idle WebSocket timeouts by pinning redis-py below 8 and added an idle-connection regression test. Author: Franco Rodrigo Miranda (`MirandaFrancoCBA`).

### 2026-09-24

- PR #56 — Fixed Daphne ASGI startup ordering and added CI validation for ASGI startup. Author: Franco Rodrigo Miranda (`MirandaFrancoCBA`).

## v1.1 — MasseDev UI refresh (planned)

Tracked by issues #61–#66. The first delivery milestone focuses on the MasseDev design system, responsive shell, richer task cards/work views, task detail with activity timeline, coordinator UX, and production-oriented authentication hardening.

When each PR merges, append its shipped summary and GitHub attribution here.
