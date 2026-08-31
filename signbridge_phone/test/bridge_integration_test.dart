import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/bridge_message.dart';
import 'package:signbridge_phone/services/mock/mock_activity_log_service.dart';
import 'package:signbridge_phone/services/mock/mock_tts_service.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/services/real/shelf_office_kit_bridge_service.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  group('OfficeKit WebSocket Bridge End-to-End Tests', () {
    late MockActivityLogService activityLogService;
    late MockTtsService ttsService;
    late ShelfOfficeKitBridgeService bridgeService;

    setUp(() {
      activityLogService = MockActivityLogService();
      ttsService = MockTtsService();
      bridgeService = ShelfOfficeKitBridgeService(
        activityLogService: activityLogService,
        ttsService: ttsService,
      );
    });

    tearDown(() async {
      await bridgeService.dispose();
    });

    test('Two-way communication, TTS trigger, and latency measurement', () async {
      // 1. Start server
      await bridgeService.startServer();
      expect(bridgeService.connectionState, equals(BridgeConnectionState.searching));

      // 2. Connect client
      final clientChannel = IOWebSocketChannel.connect(
        Uri.parse('ws://127.0.0.1:$kBridgePort'),
      );

      final Completer<BridgeMessage> receivedByClient = Completer<BridgeMessage>();
      final Stopwatch latencyStopwatch = Stopwatch()..start();

      final subscription = clientChannel.stream.listen((dynamic raw) {
        final BridgeMessage msg = BridgeMessage.fromJson(raw.toString());
        if (!receivedByClient.isCompleted) {
          latencyStopwatch.stop();
          receivedByClient.complete(msg);
        }
      });

      // Wait a moment for connection handshake to complete
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(bridgeService.connectionState, equals(BridgeConnectionState.connected));

      // 3. Test Phone -> Dashboard: Send sign_caption
      final BridgeMessage outMsg = BridgeMessage.signCaption(
        'HELLO',
        confidence: 0.95,
      );
      latencyStopwatch.reset();
      latencyStopwatch.start();
      await bridgeService.sendMessage(outMsg);

      final BridgeMessage inMsg = await receivedByClient.future.timeout(
        const Duration(seconds: 3),
      );

      expect(inMsg.type, equals('sign_caption'));
      expect(inMsg.text, equals('HELLO'));
      expect(inMsg.confidence, closeTo(0.95, 0.01));

      // Latency should be well under the 500ms target
      final int latencyMs = latencyStopwatch.elapsedMilliseconds;
      expect(latencyMs, lessThan(500));

      // 4. Test Dashboard -> Phone: Send dashboard_message
      final BridgeMessage clientMsg = BridgeMessage.dashboardMessage(
        'Hello from Windows Dashboard!',
      );

      final Completer<BridgeMessage> receivedByServer = Completer<BridgeMessage>();
      final serverSub = bridgeService.incomingMessageStream.listen((BridgeMessage msg) {
        if (!receivedByServer.isCompleted) {
          receivedByServer.complete(msg);
        }
      });

      clientChannel.sink.add(clientMsg.toJson());

      final BridgeMessage serverMsg = await receivedByServer.future.timeout(
        const Duration(seconds: 3),
      );

      expect(serverMsg.type, equals('dashboard_message'));
      expect(serverMsg.text, equals('Hello from Windows Dashboard!'));

      // Verify TTS was invoked
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(ttsService.spokenTexts, contains('Hello from Windows Dashboard!'));

      await serverSub.cancel();
      await subscription.cancel();
      await clientChannel.sink.close();
    });
  });
}
