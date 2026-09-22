# TaskDev Backend

Initial Django REST Framework backend.

## Requirements

- Python 3.12+
- PostgreSQL

## Local setup

Create and activate a virtual environment, then:

```bash
pip install -r requirements.txt
cp .env.example .env
```

Export/load the variables from `.env`, create the configured PostgreSQL database, then run:

```bash
python manage.py migrate
python manage.py runserver
```

Health check:

```text
GET http://127.0.0.1:8000/api/health/
{"status": "ok"}
```

Dockerized PostgreSQL/Redis will be introduced by issue #3.
