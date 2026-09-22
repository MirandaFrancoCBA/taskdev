# TaskDev Flutter client

Mobile-first Flutter client for TaskDev.

## Setup

From `frontend/`:

```bash
flutter create . --platforms=android,ios,web
flutter pub get
flutter analyze
flutter test
```

Run against the local API with:

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000/api
```

For the Android emulator, a typical host URL is `http://10.0.2.2:8000/api`.

API endpoints must be read through `AppConfig`, not hard-coded in feature code. Routing uses `go_router` and HTTP access begins with the `http` package.
