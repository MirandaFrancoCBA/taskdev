# Local development

## Prerequisites

- Docker with Docker Compose
- Python 3.12+
- Flutter SDK (required when the frontend is bootstrapped)

## Infrastructure

Copy the root environment example if you want to customize ports or credentials:

```bash
cp .env.example .env
```

Start PostgreSQL and Redis:

```bash
docker compose up -d
```

Check service state:

```bash
docker compose ps
```

Stop services:

```bash
docker compose down
```

To also delete local database/Redis volumes:

```bash
docker compose down -v
```

## Backend

From `backend/`:

```bash
python -m venv .venv
# activate the virtual environment for your shell
pip install -r requirements.txt
```

Configure backend environment variables using `backend/.env.example` as reference. With the root Compose defaults, PostgreSQL is available on `localhost:5432`.

Then:

```bash
python manage.py migrate
python manage.py runserver
```

Verify:

```text
GET http://127.0.0.1:8000/api/health/
```

Redis is provisioned now for the real-time layer planned in issue #9; the Django application does not depend on it yet.
