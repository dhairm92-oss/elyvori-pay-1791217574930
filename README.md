# Elyvori Pay

Built on **ElyVori Mobile Core** — a production Flutter foundation by Elyvori.

## Run

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://elyvori-api.onrender.com
flutter test
```

Optional build settings (`--dart-define`):

| Name | Default | Meaning |
| --- | --- | --- |
| `API_BASE_URL` | `https://elyvori-api.onrender.com` | REST API |
| `REALTIME_TRANSPORT` | `sse` | `sse` or `websocket` |
| `REALTIME_PATH` | `/realtime/stream` | SSE endpoint on the API |
| `WS_URL` | — | WebSocket URL when `REALTIME_TRANSPORT=websocket` |
| `RECORDS_SYNC` | `false` | also sync module data to `/records/<module>` |
| `APP_NAME` | app title | name shown in the app |

## Architecture

```
lib/
  core/            config · error · result · network (Dio + JWT refresh)
                   realtime (SSE + WebSocket, auto-reconnect) · storage (Hive, offline sync queue)
                   connectivity · theme (cyberpunk glass) · widgets · di (Riverpod) · router (GoRouter)
  features/
    auth/          domain · data · presentation   (sign in, secure token storage)
    agents/        domain · data · presentation   (live agent dashboard over SSE/WebSocket)
    records/       domain · data · presentation   (generic offline-first modules)
    home/          modules home for standalone apps
    registry.dart  the app's modules, described as data
test/              unit + widget tests (run in CI on every push)
```

- **Clean Architecture**: widgets never call Dio or Hive; they talk to Riverpod providers → use cases → repositories.
- **Networking**: one Dio client, JWT on every request, single-flight token refresh on 401, typed errors.
- **Realtime**: SSE (default) or WebSocket with exponential backoff, heartbeats and resume (`Last-Event-ID`).
- **Offline-first**: Hive cache + a durable sync queue replayed in order when connectivity returns.
- **Design system**: obsidian background, neon cyan/violet, BackdropFilter glass, flutter_animate + CustomPainter widgets.
