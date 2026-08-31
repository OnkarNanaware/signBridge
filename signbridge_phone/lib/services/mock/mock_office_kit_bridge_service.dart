import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signbridge_phone/core/models/bridge_message.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';

/// Mock [OfficeKitBridgeService] that simulates a connected bridge without
/// opening a real WebSocket server.
///
/// Transitions from [BridgeConnectionState.searching] → [connected] after
/// 2 seconds to demonstrate the connection lifecycle in the UI.
class MockOfficeKitBridgeService implements OfficeKitBridgeService {
  final StreamController<BridgeConnectionState> _stateController =
      StreamController<BridgeConnectionState>.broadcast();
  final StreamController<BridgeMessage> _incomingController =
      StreamController<BridgeMessage>.broadcast();

  BridgeConnectionState _state = BridgeConnectionState.disconnected;
  Timer? _connectTimer;

  @override
  Stream<BridgeConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  BridgeConnectionState get connectionState => _state;

  @override
  Stream<BridgeMessage> get incomingMessageStream =>
      _incomingController.stream;

  @override
  Future<void> startServer() async {
    _updateState(BridgeConnectionState.searching);
    _connectTimer = Timer(const Duration(seconds: 2), () {
      _updateState(BridgeConnectionState.connected);
      debugPrint('[MockBridge] Fake dashboard connected.');
    });
  }

  @override
  Future<void> stopServer() async {
    _connectTimer?.cancel();
    _updateState(BridgeConnectionState.disconnected);
    debugPrint('[MockBridge] Server stopped.');
  }

  @override
  Future<void> sendMessage(BridgeMessage message) async {
    if (_state != BridgeConnectionState.connected) {
      throw StateError(
        'MockOfficeKitBridgeService: Cannot send — not connected.',
      );
    }
    debugPrint('[MockBridge] → Sent: ${message.toJson()}');
  }

  @override
  Future<void> dispose() async {
    _connectTimer?.cancel();
    await _stateController.close();
    await _incomingController.close();
  }

  void _updateState(BridgeConnectionState next) {
    _state = next;
    _stateController.add(next);
  }
}
