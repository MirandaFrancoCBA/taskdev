# TaskDev Architecture

## Overview

TaskDev uses a client-server architecture with a Flutter client and Django backend.

```text
Flutter (Android / iOS / Web)
          |
     HTTPS / REST
          |
 Django REST Framework
          |
      PostgreSQL
          |
Django Channels <-> Redis
          |
      WebSockets
```

## Backend

Django owns business rules and persistence. Django REST Framework exposes the HTTP API.

Initial backend domains:

- accounts/authentication
- teams/memberships
- tasks
- activity/history

Authorization is enforced server-side. Client-side UI restrictions are not security controls.

## Client

Flutter is mobile-first. The same codebase may target Android, iOS and Web while allowing responsive/platform adaptations.

The primary member experience optimizes for seeing available work, seeing the current assigned task, claiming work with minimal interaction and changing task status quickly.

Large-screen web views can progressively expose richer coordination features.

## Real-time model

REST remains authoritative for commands and initial state. WebSockets distribute relevant state-change events.

Initial events include task created, task claimed, assignee changed, status changed and task completed.

Concurrency-sensitive operations belong on the backend. Two users trying to claim the same task must never produce two owners.

## Infrastructure

Development target:

- Django application
- PostgreSQL
- Redis
- Flutter application
- Docker Compose for backend dependencies

## Principles

1. Keep business rules in the backend.
2. Use a modular monolith for the MVP.
3. Do not introduce microservices without demonstrated need.
4. Make concurrency-sensitive operations transactional.
5. Build the REST workflow before real-time synchronization.
6. Keep development infrastructure reproducible.
