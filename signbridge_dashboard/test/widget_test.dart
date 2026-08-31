import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge_dashboard/core/constants/app_constants.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/main.dart';

void main() {
  test('Dashboard constants have correct bridge defaults', () {
    expect(kBridgePort, equals(8765));
    expect(kDefaultBridgeHost, equals('192.168.1.100'));
  });

  test('BridgeMessage JSON serialization round-trip', () {
    final DateTime now = DateTime.now().toUtc();
    final BridgeMessage message = BridgeMessage(
      type: BridgeMessageType.caption,
      payload: 'HELLO',
      timestamp: now,
      direction: BridgeDirection.phoneToDesktop,
    );

    final String jsonStr = message.toJson();
    final BridgeMessage deserialized = BridgeMessage.fromJson(jsonStr);

    expect(deserialized.type, equals(BridgeMessageType.caption));
    expect(deserialized.payload, equals('HELLO'));
    expect(deserialized.direction, equals(BridgeDirection.phoneToDesktop));
  });

  testWidgets('SignBridgeDashboardApp smoke test renders panels and demo banner',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SignBridgeDashboardApp(),
      ),
    );

    await tester.pump();

    // Verify key panels and brand title
    expect(find.text('SignBridge Dashboard'), findsOneWidget);
    expect(find.text('Live Caption'), findsOneWidget);
    expect(find.text('Session Controls'), findsOneWidget);
    expect(find.text('Speech Playback'), findsOneWidget);
    expect(find.text('Logs & History'), findsOneWidget);
    expect(find.textContaining('DEMO MODE'), findsOneWidget);
  });
}
