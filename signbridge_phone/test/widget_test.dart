import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/main.dart';
import 'package:signbridge_phone/services/mock/mock_dtw_matcher_service.dart';

void main() {
  test('App constants contain expected vocabulary', () {
    expect(kSignVocabulary.length, equals(25));
    expect(kSignVocabulary, contains('HELLO'));
    expect(kSignVocabulary, contains('THANK YOU'));
    expect(kSignVocabulary, contains('HELP'));
  });

  test('MockDtwMatcherService emits cycling vocabulary', () async {
    final MockDtwMatcherService mock = MockDtwMatcherService();
    mock.startMockEmission();

    final DtwMatch firstMatch = await mock.matchStream.first;
    expect(firstMatch.signName, equals('HELLO'));
    expect(firstMatch.confidence, greaterThanOrEqualTo(kDtwConfidenceThreshold));

    await mock.dispose();
  });

  testWidgets('SignBridgeApp smoke test renders in Demo Mode', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SignBridgeApp(),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify SignBridge brand and panels render
    expect(find.text('SignBridge'), findsOneWidget);
    expect(find.text('Sign → Text'), findsOneWidget);
    expect(find.text('Speech → Text'), findsOneWidget);
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
  });
}
