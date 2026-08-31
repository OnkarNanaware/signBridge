# SignBridge

> Offline, on-device, two-way sign-language ⇄ speech caption bridge for hybrid meetings.

## Architecture

```
Phone (Flutter Android)                    Laptop (Flutter Windows Desktop)
┌─────────────────────────────┐            ┌──────────────────────────────────┐
│ MediaPipe Hands (21 pts)    │            │ Live Caption Panel               │
│ → DTW Matcher               │            │ Speech Playback Control          │
│ → Local Sign Library (Hive) │  WebSocket │ Session Controls & Settings      │
│ ← Offline ASR (Vosk)        │◄──────────►│ Logs & History (Hive)            │
│   On-device TTS             │  Wi-Fi/USB │                                  │
└─────────────────────────────┘            └──────────────────────────────────┘
```

## Projects

| Directory | Target | Description |
|-----------|--------|-------------|
| `signbridge_phone/` | Android | On-device AI pipeline — sign recognition + ASR + TTS + bridge server |
| `signbridge_dashboard/` | Windows Desktop | Hearing participant dashboard — captions, logs, session controls |

## Prerequisites

- Flutter SDK ≥ 3.22 — [flutter.dev](https://flutter.dev/docs/get-started/install)
- `flutter config --enable-windows-desktop` (for dashboard)
- Android SDK with API 26+ (for phone)

## Getting Started

### Phone App
```bash
cd signbridge_phone
flutter pub get
flutter run        # connects to physical Android device
```

### Dashboard (Windows)
```bash
cd signbridge_dashboard
flutter pub get
flutter run -d windows
```

## Phase 1 — Mock Pipeline (current)
Both apps run entirely on **mock services** — no camera, no ML, no real WebSocket needed. A yellow **Demo Mode** banner is shown. Toggle `useMockServices = false` in `core/di/providers.dart` to activate real services in later phases.

## Non-functional Targets
- ✅ Fully offline — zero internet calls at runtime
- ✅ < 500ms end-to-end latency (sign → caption on laptop)
- ✅ High accuracy within 25–40 curated signs (DTW matching)
- ✅ Private — data never leaves phone ↔ laptop local pair
- ✅ Battery-conscious — all heavy work runs off UI isolate

## License
MIT
