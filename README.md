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

The first usable version will support authentication, teams and memberships, roles, task creation, an unassigned task pool, direct assignment, claiming tasks, task statuses, priority, optional due dates, activity history and real-time updates.

See [MVP scope](docs/MVP.md) and [architecture](docs/ARCHITECTURE.md).

## Proposed stack

- **Client:** Flutter / Dart (Android, iOS and Web)
- **API:** Django + Django REST Framework
- **Database:** PostgreSQL
- **Real time:** Django Channels + WebSockets
- **Messaging/cache:** Redis
- **Development/deployment:** Docker

## Planned repository structure

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

**Phase 0 — Product definition and foundation.**

TaskDev is a MasseDev project.
