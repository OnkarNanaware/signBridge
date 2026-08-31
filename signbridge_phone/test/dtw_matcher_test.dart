import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/core/models/landmark_point.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/services/mock/mock_activity_log_service.dart';
import 'package:signbridge_phone/services/mock/mock_sign_library_repository.dart';
import 'package:signbridge_phone/services/real/real_dtw_matcher_service.dart';

List<LandmarkPoint> _generateFrame({double xOffset = 0.0, double yOffset = 0.0}) {
  return List.generate(21, (int i) {
    return LandmarkPoint(
      landmarkIndex: i,
      x: 0.5 + (i * 0.01) + xOffset,
      y: 0.5 + (i * 0.01) + yOffset,
      z: 0.0,
    );
  });
}

List<List<LandmarkPoint>> _generateSequence(int frameCount, {double speed = 0.01}) {
  return List.generate(frameCount, (int f) {
    return _generateFrame(xOffset: f * speed, yOffset: f * speed);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RealDtwMatcherService Unit Tests', () {
    late MockSignLibraryRepository mockRepo;
    late MockActivityLogService mockLog;
    late RealDtwMatcherService dtwService;

    setUp(() {
      mockRepo = MockSignLibraryRepository();
      mockLog = MockActivityLogService();
      dtwService = RealDtwMatcherService(
        signLibraryRepository: mockRepo,
        activityLogService: mockLog,
        confidenceThreshold: 0.60,
        signHoldMs: 100,
      );
    });

    tearDown(() async {
      await dtwService.dispose();
    });

    test('Identical gesture sequence matches reference sign with high confidence', () async {
      final List<List<LandmarkPoint>> helloSeq = _generateSequence(20, speed: 0.01);
      await mockRepo.saveSign(
        SignEntry(
          signName: 'Hello',
          landmarkSequence: helloSeq,
          dateRecorded: DateTime.now(),
        ),
      );

      DtwMatch? matched;
      final sub = dtwService.matchStream.listen((m) => matched = m);

      // Feed frames matching 'Hello' sequence multiple times to satisfy hold duration
      for (int repeat = 0; repeat < 4; repeat++) {
        for (final frame in helloSeq) {
          dtwService.addFrame(frame);
        }
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(matched, isNotNull);
      expect(matched!.signName, equals('Hello'));
      expect(matched!.confidence, greaterThan(0.60));

      // Verify activity logs were generated
      final logs = await mockLog.getAll();
      final hasMatchRun = logs.any((l) => l.eventType == EventType.dtwMatchRun);
      final hasMatchResult = logs.any((l) => l.eventType == EventType.dtwMatchResult);
      expect(hasMatchRun, isTrue);
      expect(hasMatchResult, isTrue);

      await sub.cancel();
    });

    test('Dissimilar sequence returns no match below threshold', () async {
      final List<List<LandmarkPoint>> refSeq = _generateSequence(20, speed: 0.01);
      await mockRepo.saveSign(
        SignEntry(
          signName: 'Stop',
          landmarkSequence: refSeq,
          dateRecorded: DateTime.now(),
        ),
      );

      DtwMatch? matched;
      final sub = dtwService.matchStream.listen((m) => matched = m);

      // Generate completely different positions
      final List<List<LandmarkPoint>> invertedSeq = List.generate(20, (int f) {
        return List.generate(21, (int i) {
          return LandmarkPoint(
            landmarkIndex: i,
            x: 0.1 - (i * 0.02),
            y: 0.9 - (f * 0.03),
            z: 0.5,
          );
        });
      });

      for (final frame in invertedSeq) {
        dtwService.addFrame(frame);
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));

      expect(matched, isNull);
      await sub.cancel();
    });
  });
}
