# TaskDev delivery history

This changelog records shipped project work and its GitHub attribution. It complements the in-product `TaskActivity` audit trail, which records changes to individual tasks.

## Attribution convention

For each shipped change, record the release/date, linked issue and pull request, a short delivery summary, and the author/contributors shown by GitHub. Do not infer or invent authorship when GitHub does not provide reliable attribution.

## v1.1.0 — MasseDev UI refresh

Released 2026-09-30. This milestone refreshes the operational UI without changing TaskDev into a generic project-management suite. REST remains authoritative, realtime remains event-driven, and server-side authorization continues to enforce team and coordinator boundaries.

### 2026-09-30

- PR #72 / Issue #66 — Added refresh-token rotation and blacklist-based revocation, server-side logout revocation, and moved the current Flutter WebSocket JWT transport out of the URL query string into WebSocket subprotocol negotiation. A temporary query-string compatibility path remains for older clients. Author: `MirandaFrancoCBA`.
- PR #71 / Issue #65 — Added coordinator member administration with add, role-change and removal flows plus server-side permission coverage. Author: `MirandaFrancoCBA`.
- PR #70 / Issue #62 — Redesigned the operational workspace with My Work, Available, Blocked and Completed views, richer task metadata, responsive layout and improved states. Author: `MirandaFrancoCBA`.
- PR #69 / Issue #63 — Added task detail and the `TaskActivity` history timeline to Flutter, including actor, timestamp and before/after context exposed by the existing REST audit endpoint. Author: `MirandaFrancoCBA`.
- PR #68 / Issue #61 — Established the MasseDev Material 3 design tokens, branded responsive application shell and reusable page foundation. Author: `MirandaFrancoCBA`.
- PR #67 / Issue #64 — Added this project-level delivery history and its GitHub attribution convention. Author: `MirandaFrancoCBA`.

All v1.1 milestone issues #61–#66 are closed.

## v1.0.0 — stable MVP

TaskDev v1.0.0 established the mobile-first shared task workflow, server-side authorization, transactional claiming, realtime invalidation through Channels/Redis, and the validated two-client browser flow.

### 2026-09-26

- PR #60 / Issue #59 — Documented the successful final two-client browser smoke validation and standardized local ASGI startup on Daphne. Author: Franco Rodrigo Miranda (`MirandaFrancoCBA`).
- PR #58 / Issue #57 — Fixed Redis idle WebSocket timeouts by pinning redis-py below 8 and added an idle-connection regression test. Author: Franco Rodrigo Miranda (`MirandaFrancoCBA`).

### 2026-09-24

- PR #56 — Fixed Daphne ASGI startup ordering and added CI validation for ASGI startup. Author: Franco Rodrigo Miranda (`MirandaFrancoCBA`).
