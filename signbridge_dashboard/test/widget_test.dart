import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge_dashboard/core/constants/app_constants.dart';
import 'package:signbridge_dashboard/core/di/providers.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/main.dart';
import 'package:signbridge_dashboard/services/mock/mock_activity_log_service.dart';
import 'package:signbridge_dashboard/services/mock/mock_office_kit_client_service.dart';

void main() {
  test('Dashboard constants have correct bridge defaults', () {
    expect(kBridgePort, equals(8765));
    expect(kDefaultBridgeHost, equals('192.168.1.100'));
  });

  test('BridgeMessage JSON serialization round-trip', () {
    final BridgeMessage message = BridgeMessage.signCaption(
      'HELLO',
      confidence: 0.95,
    );

    final String jsonStr = message.toJson();
    final BridgeMessage deserialized = BridgeMessage.fromJson(jsonStr);

    expect(deserialized.type, equals('sign_caption'));
    expect(deserialized.text, equals('HELLO'));
    expect(deserialized.payload, equals('HELLO'));
    expect(deserialized.confidence, equals(0.95));
    expect(deserialized.direction, equals(BridgeDirection.phoneToDesktop));
  });

  test('BridgeMessage dashboardMessage serialization', () {
    final BridgeMessage message = BridgeMessage.dashboardMessage('Can you hear me?');
    final String jsonStr = message.toJson();
    final BridgeMessage deserialized = BridgeMessage.fromJson(jsonStr);

    expect(deserialized.type, equals('dashboard_message'));
    expect(deserialized.text, equals('Can you hear me?'));
    expect(deserialized.direction, equals(BridgeDirection.desktopToPhone));
  });

  testWidgets('SignBridgeDashboardApp smoke test renders panels',
      (WidgetTester tester) async {
    final MockOfficeKitClientService mockClient = MockOfficeKitClientService();
    mockClient.startMock();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientServiceProvider.overrideWithValue(mockClient),
          activityLogServiceProvider.overrideWithValue(MockActivityLogService()),
        ],
        child: const SignBridgeDashboardApp(),
      ),
    );

    await tester.pump();

    // Verify key panels and brand title
    expect(find.text('SignBridge Dashboard'), findsOneWidget);
    expect(find.text('Live Caption'), findsOneWidget);
    expect(find.textContaining('Session Controls'), findsOneWidget);
    expect(find.text('Speech Playback'), findsOneWidget);
    expect(find.text('Logs & History'), findsOneWidget);

    mockClient.dispose();
  });
}
