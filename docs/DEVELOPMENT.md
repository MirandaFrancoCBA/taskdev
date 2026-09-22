# Local development

## Prerequisites

- Docker with Docker Compose
- Python 3.12+
- Flutter stable / Dart 3.5+

## 1. Start infrastructure

From the repository root:

```bash
cp .env.example .env
docker compose up -d
docker compose ps
```

Both PostgreSQL and Redis must be healthy. Redis is required by Django Channels for real-time events.

## 2. Start the backend

From `backend/`:

```bash
python -m venv .venv
# activate .venv for your shell
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver 0.0.0.0:8000
```

Verify `GET http://127.0.0.1:8000/api/health/`.

## 3. Prepare Flutter

From `frontend/`:

```bash
flutter create . --platforms=android,ios,web
flutter pub get
flutter analyze
flutter test
```

Run on desktop/web against localhost:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

For the standard Android emulator use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

The WebSocket URL is derived from `API_BASE_URL`, switching `http→ws` and `https→wss`.

## 4. Seed a two-user validation scenario

The current Flutter MVP login temporarily expects both the authenticated user ID and team ID. The quickest deterministic setup is Django shell:

```bash
python manage.py shell
```

Then:

```python
from accounts.models import User
from teams.models import Team, TeamMembership
from tasks.models import Task

coord = User.objects.create_user(username="coord", password="taskdev-demo")
member = User.objects.create_user(username="member", password="taskdev-demo")
team = Team.objects.create(name="MVP Team", created_by=coord)
TeamMembership.objects.create(team=team, user=coord, role=TeamMembership.Role.COORDINATOR)
TeamMembership.objects.create(team=team, user=member, role=TeamMembership.Role.MEMBER)
Task.objects.create(title="Prepare shipment", team=team, creator=coord, priority=Task.Priority.HIGH)
print("team", team.id, "coord", coord.id, "member", member.id)
```

Use the printed IDs in two Flutter clients.

## 5. End-to-end checklist

1. Sign in as `coord` in client A and `member` in client B.
2. Confirm both clients show **Prepare shipment** under Available.
3. Press **Take** in client B. It should move into B's My work and disappear from A's Available list without manual refresh.
4. Attempt to claim the same task from a stale/third client. The API must return HTTP 409 and preserve the first assignee.
5. Change the task to Blocked, then In progress, then Complete. The other connected client should update after each committed change.
6. Request `GET /api/tasks/{task_id}/activity/` with a team member JWT and confirm claim/status history is retained.
7. Stop Redis temporarily. REST refresh and task commands should remain usable; real-time delivery pauses. Restart Redis and the Flutter reconnect strategy should restore live invalidation.

## Known MVP limitations

- Flutter login currently asks for team ID and user ID instead of discovering them after authentication.
- Access tokens are kept in memory; secure persistent credential storage/logout is not implemented yet.
- WebSocket authentication passes the short-lived access token in the query string. Production deployment must use TLS and should move to a safer transport/authentication strategy where practical.
- There is no push notification support.
- Task creation/coordination UI is not implemented in Flutter; validation data can be created through the REST API or Django shell.
- Direct assignment/update authorization is intentionally basic and should be tightened before production use.
- Automated tests exist in the repository, but this checklist still requires execution in a local environment; repository edits alone do not prove runtime validation.
