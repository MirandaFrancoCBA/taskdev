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

The repository keeps the TaskDev Dart source authoritative. CI regenerates the standard Flutter Android/iOS/Web runner scaffolding before analysis, tests, and a release Web build.

## Run targets

Web or a desktop browser can reach a backend on the same machine through localhost:

```bash
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api
```

The standard Android emulator reaches the host machine through `10.0.2.2`:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

A physical phone cannot use the development computer's `localhost`. Start Django on `0.0.0.0:8000`, keep both devices on the same trusted LAN, and use the computer's LAN address, for example:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.50:8000/api
```

Replace the example address with the development computer's actual LAN IP. The WebSocket URL is derived from `API_BASE_URL`; HTTP becomes WS and HTTPS becomes WSS.

API endpoints must be read through `AppConfig`, not hard-coded in feature code.
