import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/bridge/bridge_coordinator.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/bridge_message.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/asr_service.dart';
import 'package:signbridge_phone/services/camera_service.dart';
import 'package:signbridge_phone/services/dtw_matcher_service.dart';
import 'package:signbridge_phone/services/hand_landmark_service.dart';
import 'package:signbridge_phone/services/mock/mock_activity_log_service.dart';
import 'package:signbridge_phone/services/mock/mock_asr_service.dart';
import 'package:signbridge_phone/services/mock/mock_camera_service.dart';
import 'package:signbridge_phone/services/mock/mock_dtw_matcher_service.dart';
import 'package:signbridge_phone/services/mock/mock_hand_landmark_service.dart';
import 'package:signbridge_phone/services/mock/mock_office_kit_bridge_service.dart';
import 'package:signbridge_phone/services/mock/mock_sign_library_repository.dart';
import 'package:signbridge_phone/services/mock/mock_tts_service.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/services/real/flutter_tts_service.dart';
import 'package:signbridge_phone/services/real/hive_activity_log_service.dart';
import 'package:signbridge_phone/services/real/hive_sign_library_repository.dart';
import 'package:signbridge_phone/services/real/native_hand_landmark_service.dart';
import 'package:signbridge_phone/services/real/real_camera_service.dart';
import 'package:signbridge_phone/services/real/real_dtw_matcher_service.dart';
import 'package:signbridge_phone/services/real/shelf_office_kit_bridge_service.dart';
import 'package:signbridge_phone/services/real/vosk_asr_service.dart';
import 'package:signbridge_phone/services/sign_library_repository.dart';
import 'package:signbridge_phone/services/tts_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feature flag — Phase 2/3/4 activates the real on-device pipeline & bridge.
// ─────────────────────────────────────────────────────────────────────────────

/// When true, all service providers return mock implementations.
/// Set to false to activate on-device Vosk ASR, Flutter TTS, and Shelf WebSocket bridge.
const bool useMockServices = false;

// ─────────────────────────────────────────────────────────────────────────────
// Service Providers
// ─────────────────────────────────────────────────────────────────────────────

final Provider<ActivityLogService> activityLogServiceProvider =
    Provider<ActivityLogService>((Ref ref) {
  if (useMockServices) return MockActivityLogService();
  return HiveActivityLogService();
});

final Provider<SignLibraryRepository> signLibraryRepositoryProvider =
    Provider<SignLibraryRepository>((Ref ref) {
  if (useMockServices) return MockSignLibraryRepository();
  return HiveSignLibraryRepository();
});

final Provider<CameraService> cameraServiceProvider =
    Provider<CameraService>((Ref ref) {
  if (useMockServices) return MockCameraService();
  final ActivityLogService logService = ref.watch(activityLogServiceProvider);
  final RealCameraService service = RealCameraService(logService);
  ref.onDispose(service.dispose);
  return service;
});

final Provider<HandLandmarkService> handLandmarkServiceProvider =
    Provider<HandLandmarkService>((Ref ref) {
  if (useMockServices) return MockHandLandmarkService();
  final NativeHandLandmarkService service = NativeHandLandmarkService();
  ref.onDispose(service.dispose);
  return service;
});

final Provider<DtwMatcherService> dtwMatcherServiceProvider =
    Provider<DtwMatcherService>((Ref ref) {
  if (useMockServices) {
    final MockDtwMatcherService mock = MockDtwMatcherService();
    mock.startMockEmission();
    ref.onDispose(mock.dispose);
    return mock;
  }
  final SignLibraryRepository libRepo =
      ref.watch(signLibraryRepositoryProvider);
  final ActivityLogService logService =
      ref.watch(activityLogServiceProvider);
  final RealDtwMatcherService service = RealDtwMatcherService(
    signLibraryRepository: libRepo,
    activityLogService: logService,
  );
  ref.onDispose(service.dispose);
  return service;
});

final Provider<AsrService> asrServiceProvider =
    Provider<AsrService>((Ref ref) {
  if (useMockServices) {
    final MockAsrService mock = MockAsrService();
    mock.startListening();
    ref.onDispose(mock.dispose);
    return mock;
  }
  final ActivityLogService logService = ref.watch(activityLogServiceProvider);
  final VoskAsrService service = VoskAsrService(logService);
  ref.onDispose(service.dispose);
  return service;
});

final Provider<TtsService> ttsServiceProvider =
    Provider<TtsService>((Ref ref) {
  if (useMockServices) {
    final MockTtsService mock = MockTtsService();
    ref.onDispose(mock.dispose);
    return mock;
  }
  final ActivityLogService logService = ref.watch(activityLogServiceProvider);
  final FlutterTtsService service = FlutterTtsService(logService);
  ref.onDispose(service.dispose);
  return service;
});

final Provider<OfficeKitBridgeService> bridgeServiceProvider =
    Provider<OfficeKitBridgeService>((Ref ref) {
  if (useMockServices) {
    final MockOfficeKitBridgeService mock = MockOfficeKitBridgeService();
    mock.startServer();
    ref.onDispose(mock.dispose);
    return mock;
  }
  final ActivityLogService logService = ref.watch(activityLogServiceProvider);
  final TtsService ttsService = ref.watch(ttsServiceProvider);
  final ShelfOfficeKitBridgeService service = ShelfOfficeKitBridgeService(
    activityLogService: logService,
    ttsService: ttsService,
  );
  ref.onDispose(service.dispose);
  return service;
});

/// Bridge coordinator provider ensuring DTW match and ASR speech auto-publish.
final Provider<BridgeCoordinator> bridgeCoordinatorProvider =
    Provider<BridgeCoordinator>((Ref ref) {
  final DtwMatcherService dtw = ref.watch(dtwMatcherServiceProvider);
  final AsrService asr = ref.watch(asrServiceProvider);
  final OfficeKitBridgeService bridge = ref.watch(bridgeServiceProvider);

  final BridgeCoordinator coordinator = BridgeCoordinator(
    dtwMatcherService: dtw,
    asrService: asr,
    bridgeService: bridge,
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

// ─────────────────────────────────────────────────────────────────────────────
// Derived state providers — consumed by the UI layer
// ─────────────────────────────────────────────────────────────────────────────

/// Stream of DTW match results for the SignCapturePanel.
final StreamProvider<DtwMatch> dtwMatchStreamProvider =
    StreamProvider<DtwMatch>((Ref ref) {
  final DtwMatcherService service = ref.watch(dtwMatcherServiceProvider);
  return service.matchStream;
});

/// Stream of detected hand landmarks for the camera overlay painter.
final StreamProvider<List<LandmarkPoint>> handLandmarkStreamProvider =
    StreamProvider<List<LandmarkPoint>>((Ref ref) {
  final HandLandmarkService service = ref.watch(handLandmarkServiceProvider);
  return service.landmarkStream;
});

/// Stream of ASR transcripts for the SpeechCapturePanel.
final StreamProvider<String> asrTranscriptStreamProvider =
    StreamProvider<String>((Ref ref) {
  final AsrService service = ref.watch(asrServiceProvider);
  return service.transcriptStream;
});

/// Stream of bridge connection state for the ConnectionStatusBadge.
final StreamProvider<BridgeConnectionState> bridgeConnectionStateProvider =
    StreamProvider<BridgeConnectionState>((Ref ref) {
  final OfficeKitBridgeService service = ref.watch(bridgeServiceProvider);
  return service.connectionStateStream;
});

/// Stream of incoming bridge messages.
final StreamProvider<BridgeMessage> incomingBridgeMessageStreamProvider =
    StreamProvider<BridgeMessage>((Ref ref) {
  final OfficeKitBridgeService service = ref.watch(bridgeServiceProvider);
  return service.incomingMessageStream;
});

/// Live stream of activity log entries for the Logs panel.
final StreamProvider<ActivityLogEntry> activityLogStreamProvider =
    StreamProvider<ActivityLogEntry>((Ref ref) {
  final ActivityLogService service = ref.watch(activityLogServiceProvider);
  return service.logStream;
});
