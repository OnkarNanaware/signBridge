import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
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
import 'package:signbridge_phone/services/sign_library_repository.dart';
import 'package:signbridge_phone/services/tts_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feature flag — set to false in Phase 2 to activate real implementations.
// ─────────────────────────────────────────────────────────────────────────────

/// When true, all service providers return mock implementations.
/// Flip to false and add real implementations to swap the entire service layer.
const bool useMockServices = true;

// ─────────────────────────────────────────────────────────────────────────────
// Service Providers
// ─────────────────────────────────────────────────────────────────────────────

final Provider<CameraService> cameraServiceProvider =
    Provider<CameraService>((Ref ref) {
  if (useMockServices) return MockCameraService();
  // TODO(phase2): return RealCameraService();
  throw UnimplementedError('Real CameraService not yet implemented.');
});

final Provider<HandLandmarkService> handLandmarkServiceProvider =
    Provider<HandLandmarkService>((Ref ref) {
  if (useMockServices) return MockHandLandmarkService();
  // TODO(phase2): return RealHandLandmarkService();
  throw UnimplementedError('Real HandLandmarkService not yet implemented.');
});

final Provider<DtwMatcherService> dtwMatcherServiceProvider =
    Provider<DtwMatcherService>((Ref ref) {
  if (useMockServices) {
    final MockDtwMatcherService mock = MockDtwMatcherService();
    mock.startMockEmission();
    ref.onDispose(mock.dispose);
    return mock;
  }
  // TODO(phase2): return RealDtwMatcherService();
  throw UnimplementedError('Real DtwMatcherService not yet implemented.');
});

final Provider<SignLibraryRepository> signLibraryRepositoryProvider =
    Provider<SignLibraryRepository>((Ref ref) {
  if (useMockServices) return MockSignLibraryRepository();
  // TODO(phase2): return HiveSignLibraryRepository();
  throw UnimplementedError('Real SignLibraryRepository not yet implemented.');
});

final Provider<AsrService> asrServiceProvider =
    Provider<AsrService>((Ref ref) {
  if (useMockServices) {
    final MockAsrService mock = MockAsrService();
    mock.startListening();
    ref.onDispose(mock.dispose);
    return mock;
  }
  // TODO(phase2): return VoskAsrService();
  throw UnimplementedError('Real AsrService not yet implemented.');
});

final Provider<TtsService> ttsServiceProvider =
    Provider<TtsService>((Ref ref) {
  if (useMockServices) {
    final MockTtsService mock = MockTtsService();
    ref.onDispose(mock.dispose);
    return mock;
  }
  // TODO(phase2): return FlutterTtsService();
  throw UnimplementedError('Real TtsService not yet implemented.');
});

final Provider<OfficeKitBridgeService> bridgeServiceProvider =
    Provider<OfficeKitBridgeService>((Ref ref) {
  if (useMockServices) {
    final MockOfficeKitBridgeService mock = MockOfficeKitBridgeService();
    mock.startServer();
    ref.onDispose(mock.dispose);
    return mock;
  }
  // TODO(phase2): return ShelfOfficeKitBridgeService();
  throw UnimplementedError('Real OfficeKitBridgeService not yet implemented.');
});

final Provider<ActivityLogService> activityLogServiceProvider =
    Provider<ActivityLogService>((Ref ref) {
  if (useMockServices) return MockActivityLogService();
  // TODO(phase2): return HiveActivityLogService();
  throw UnimplementedError('Real ActivityLogService not yet implemented.');
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

/// Live stream of activity log entries for the Logs panel.
final StreamProvider<ActivityLogEntry> activityLogStreamProvider =
    StreamProvider<ActivityLogEntry>((Ref ref) {
  final ActivityLogService service = ref.watch(activityLogServiceProvider);
  return service.logStream;
});
