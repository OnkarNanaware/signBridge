# AGENTS.md — SignBridge

## Project
Offline, on-device, two-way sign-language ⇄ speech caption bridge for hybrid
meetings, per the SignBridge system design diagram: phone does all AI
on-device (MediaPipe Hands + DTW matching against a local sign library, plus
offline ASR/TTS), and bridges to a Flutter Windows desktop dashboard over a
two-way "Office Kit" WebSocket connection (Wi-Fi or USB). Zero cloud calls,
ever.

## Tech stack (do not deviate without asking)
- Flutter, Dart null-safety
- State management: flutter_riverpod
- Architecture: feature-first Clean Architecture (core / services / features / shared)
- Sign recognition: MediaPipe Hands (21 landmarks) → DTW matcher against a
  local sign library — NOT a trained TFLite classifier. Do not introduce a
  training pipeline unless explicitly asked.
- Local storage: Hive (or sqflite) for the sign library and session logs on
  both phone and desktop
- ASR: vosk_flutter (offline model)
- TTS: flutter_tts
- Bridge: shelf + shelf_web_socket (phone, server side), web_socket_channel
  (desktop, client side) — two-way, over local Wi-Fi or USB only
- Desktop app: Flutter Windows Desktop target for the dashboard, not a web page

## Non-functional requirements — hold these in every phase, not just at the end
- Fully offline. No package or API call may reach the internet at runtime.
- Target < 500ms latency from sign captured to caption shown on the dashboard.
- Accuracy is scoped to a controlled vocabulary (25–40 signs) — don't chase
  open-vocabulary sign language recognition.
- Privacy: no data ever leaves the phone↔desktop local-network pair.
- Be battery/resource-conscious — this runs continuously through a meeting,
  so inference and camera use must be efficient, not just "working."

## Conventions
- All heavy work (landmark extraction, DTW matching, ASR) MUST run off the
  UI isolate.
- Every service is an interface + implementation, so it can be mocked for
  demo mode.
- Log every camera activation, mic activation, DTW match run, and bridge
  message to ActivityLogService — required for hackathon device-usage
  scoring, not optional telemetry.
- Write a short doc comment on every public service method.
- After each phase, run `flutter analyze` and fix all warnings before moving on.

## Definition of done for each phase
- Phone app builds and runs on a physical Android device via `flutter run`.
- Desktop app builds and runs via `flutter run -d windows`.
- Each feature works with Wi-Fi/mobile data off (airplane mode), except the
  explicit local bridge connection between phone and desktop.
- No TODO left silently — either implemented or flagged with
  `// TODO(phaseX):` and called out in the phase summary.
