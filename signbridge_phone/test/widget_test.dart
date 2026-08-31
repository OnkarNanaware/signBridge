import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/main.dart';
import 'package:signbridge_phone/services/hand_landmark_service.dart';
import 'package:signbridge_phone/services/mock/mock_activity_log_service.dart';
import 'package:signbridge_phone/services/mock/mock_asr_service.dart';
import 'package:signbridge_phone/services/mock/mock_camera_service.dart';
import 'package:signbridge_phone/services/mock/mock_dtw_matcher_service.dart';
import 'package:signbridge_phone/services/mock/mock_office_kit_bridge_service.dart';
import 'package:signbridge_phone/services/mock/mock_sign_library_repository.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';

class _TestHandLandmarkService implements HandLandmarkService {
  final StreamController<List<LandmarkPoint>> _controller =
      StreamController<List<LandmarkPoint>>.broadcast();

  @override
  Stream<List<LandmarkPoint>> get landmarkStream => _controller.stream;

  @override
  Future<void> startDetection(Stream<dynamic> imageStream) async {}

  @override
  Future<void> stopDetection() async {}

  @override
  bool get isRunning => false;

  @override
  Future<void> dispose() async {
    await _controller.close();
  }
}

void main() {
  test('App constants contain expected vocabulary', () {
    expect(kSignVocabulary.length, equals(25));
    expect(kSignVocabulary, contains('Hello'));
    expect(kSignVocabulary, contains('Thank You'));
    expect(kSignVocabulary, contains('Help'));
  });

  test('MockDtwMatcherService emits cycling vocabulary', () async {
    final MockDtwMatcherService mock = MockDtwMatcherService();
    mock.startMockEmission();

    final DtwMatch firstMatch = await mock.matchStream.first;
    expect(firstMatch.signName, equals('HELLO'));
    expect(firstMatch.confidence, greaterThanOrEqualTo(kDtwConfidenceThreshold));

    await mock.dispose();
  });

  testWidgets('SignBridgeApp smoke test renders panels cleanly', (WidgetTester tester) async {
    final MockAsrService mockAsr = MockAsrService();
    final MockOfficeKitBridgeService mockBridge = MockOfficeKitBridgeService();
    final _TestHandLandmarkService testLandmarks = _TestHandLandmarkService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cameraServiceProvider.overrideWithValue(MockCameraService()),
          handLandmarkServiceProvider.overrideWithValue(testLandmarks),
          signLibraryRepositoryProvider.overrideWithValue(MockSignLibraryRepository()),
          activityLogServiceProvider.overrideWithValue(MockActivityLogService()),
          asrServiceProvider.overrideWithValue(mockAsr),
          bridgeServiceProvider.overrideWithValue(mockBridge),
          bridgeConnectionStateProvider.overrideWith((ref) => Stream.value(BridgeConnectionState.connected)),
        ],
        child: const SignBridgeApp(),
      ),
    );

    await tester.pump(const Duration(milliseconds: 100));

    // Verify SignBridge brand and panels render
    expect(find.text('SignBridge'), findsOneWidget);
    expect(find.text('Sign → Text'), findsOneWidget);
    expect(find.text('Speech → Text'), findsOneWidget);

    // Unmount widget cleanly
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));

    await testLandmarks.dispose();
    await mockAsr.dispose();
    await mockBridge.dispose();
  });
}
