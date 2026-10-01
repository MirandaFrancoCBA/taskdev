# TaskDev

TaskDev is a collaborative, mobile-first task manager for operational teams.

The core idea is simple: a team shares a live pool of work. Tasks can be assigned by a coordinator or claimed by team members, and relevant changes are synchronized in real time.

## Product principles

- Mobile-first for day-to-day work.
- Opening the app should quickly answer: **What can I work on now?**
- Shared task pool plus direct assignments.
- Real-time state changes.
- Simple workflow before advanced project-management features.
- Traceability without unnecessary bureaucracy.

## MVP

The MVP supports authentication, teams and memberships, coordinator/member roles, coordinator task creation, an unassigned task pool, direct assignment, atomic task claiming, task statuses, priority, optional due dates, activity history and real-time updates.

See [MVP scope](docs/MVP.md) and [architecture](docs/ARCHITECTURE.md).

## Stack

- **Client:** Flutter / Dart (Android, iOS and Web)
- **API:** Django + Django REST Framework
- **Database:** PostgreSQL
- **Real time:** Django Channels + WebSockets
- **Messaging/cache:** Redis
- **Development/deployment:** Docker

## Repository structure

```text
taskdev/
├── backend/
├── frontend/
├── docs/
└── .github/
```

Implementation directories are added when their corresponding setup issue begins; no empty placeholder folders.

## Workflow

GitHub Issues are the source of truth for planned work. We intentionally begin without a separate project board.

Work should be incremental: each issue describes a small, verifiable outcome with acceptance criteria.

## Status

**v1.1.0 — MasseDev UI refresh shipped. Automated backend and Flutter CI are green.**

The validated MVP now includes the MasseDev responsive design system, operational work views, task detail/activity timeline, coordinator member administration, refresh-token revocation and safer WebSocket credential transport. The original two-client browser smoke validation remains documented in [local development and MVP validation](docs/DEVELOPMENT.md). See [delivery history](docs/CHANGELOG.md) for v1.1 traceability.

TaskDev is a MasseDev project.
