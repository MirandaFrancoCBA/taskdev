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
daphne -b 0.0.0.0 -p 8000 config.asgi:application
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

CI performs the same runner generation and also builds the Web target in release mode, giving the client a compile/build gate in addition to analysis and tests.

Run on desktop/web against localhost:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

For the standard Android emulator use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

For a physical phone, run Daphne on `0.0.0.0:8000`, connect the phone and development machine to the same trusted LAN, and use the computer's LAN IP instead of localhost, for example `http://192.168.1.50:8000/api`. Replace that example with the actual address of the development machine.

The WebSocket URL is derived from `API_BASE_URL`, switching `http→ws` and `https→wss`.

## 4. Seed a two-user validation scenario

The Flutter client discovers the authenticated user and their teams automatically. The quickest deterministic setup for two accounts is Django shell:

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

## 5. Final two-client smoke-test checklist

1. Sign in as `coord` in client A and `member` in client B.
2. As `coord`, create a task from the Flutter **New task** action, including priority and an optional due date. Confirm both clients receive the new task without manual refresh.
3. Confirm an unassigned task appears under Available for both clients.
4. Press **Take** in client B. It should move into B's My work and disappear from A's Available list without manual refresh.
5. Attempt to claim the same task from a stale/third client. The API must return HTTP 409 and preserve the first assignee.
6. Change the task to Blocked, then In progress, then Complete. The other connected client should update after each committed change.
7. Request `GET /api/tasks/{task_id}/activity/` with a team member JWT and confirm claim/status history is retained.
8. Stop Redis temporarily. REST refresh and task commands should remain usable; real-time delivery pauses. Restart Redis and the Flutter reconnect strategy should restore live invalidation.

## Final smoke-test result

The two-client browser smoke test has been completed successfully. With redis-py 7.4.1, both clients remained connected over WebSockets beyond the previous 5-second failure window. Task creation, claiming and status changes propagated to the other client without manual refresh. The atomic claim conflict behavior had already been validated separately with competing clients.

## Known MVP limitations

- Access and refresh tokens are persisted with platform secure storage; server-side refresh-token revocation/blacklisting is not implemented yet.
- WebSocket authentication passes the short-lived access token in the query string. Production deployment must use TLS and should move to a safer transport/authentication strategy where practical.
- There is no push notification support.
- Team creation/member administration remains API/backend-oriented; the MVP Flutter workflow focuses on selecting existing teams and coordinating their tasks.
- Backend runtime, REST/WebSocket integration, Flutter analysis/tests, and a release Web build are automated in CI. The two-client graphical browser smoke test is a manual release check and has been completed successfully for this MVP candidate.

## Continuous integration

Pull requests and pushes to `main` run `.github/workflows/ci.yml`.

The backend job starts PostgreSQL 17 and Redis 7, installs Python dependencies, runs Django system checks, verifies that migrations are committed, applies migrations and runs the Django test suite.

The Flutter job installs the stable Flutter SDK, generates the standard Android/iOS/Web runner scaffolding, restores packages, runs `flutter analyze`, runs `flutter test`, and produces a release Web build. A failing command fails the corresponding GitHub Actions job and is visible on the commit/pull request.
