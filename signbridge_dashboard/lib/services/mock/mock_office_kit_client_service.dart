import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:signbridge_dashboard/core/constants/app_constants.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/services/office_kit_client_service.dart';

/// Mock [OfficeKitClientService] that emits fake caption + speech events.
///
/// Simulates the connection lifecycle (disconnected → connecting → connected)
/// and then streams 3-second sign captions and 4-second speech phrases.
class MockOfficeKitClientService implements OfficeKitClientService {
  static const List<String> _captions = [
    'HELLO',
    'THANK YOU',
    'HELP',
    'YES',
    'NO',
  ];

  static const List<String> _speechPhrases = [
    'Good morning, everyone.',
    'Can you repeat that?',
    'I understand, thank you.',
    'Let me pull up the document.',
    'Does anyone have questions?',
  ];

  final StreamController<ClientConnectionState> _stateController =
      StreamController<ClientConnectionState>.broadcast();
  final StreamController<BridgeMessage> _incomingController =
      StreamController<BridgeMessage>.broadcast();

  ClientConnectionState _state = ClientConnectionState.disconnected;
  Timer? _connectTimer;
  Timer? _captionTimer;
  Timer? _speechTimer;
  int _captionIndex = 0;
  int _speechIndex = 0;

  @override
  Stream<ClientConnectionState> get connectionStateStream =>
      _stateController.stream;

  @override
  ClientConnectionState get connectionState => _state;

  @override
  Stream<BridgeMessage> get incomingMessageStream =>
      _incomingController.stream;

  /// Starts the mock connection lifecycle immediately.
  void startMock() {
    _updateState(ClientConnectionState.connecting);
    _connectTimer = Timer(const Duration(seconds: 2), () {
      _updateState(ClientConnectionState.connected);
      debugPrint('[MockClient] Connected to mock phone server.');
      _startMockStreams();
    });
  }

  void _startMockStreams() {
    _captionTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      final String sign = _captions[_captionIndex % _captions.length];
      _captionIndex++;
      _incomingController.add(
        BridgeMessage(
          type: BridgeMessageType.caption,
          payload: sign,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    });
    _speechTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      final String phrase =
          _speechPhrases[_speechIndex % _speechPhrases.length];
      _speechIndex++;
      _incomingController.add(
        BridgeMessage(
          type: BridgeMessageType.speech,
          payload: phrase,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    });
  }

  @override
  Future<void> connect(String host, int port) async {
    debugPrint('[MockClient] Connecting to ws://$host:$port …');
    startMock();
  }

  @override
  Future<void> disconnect() async {
    _captionTimer?.cancel();
    _speechTimer?.cancel();
    _connectTimer?.cancel();
    _updateState(ClientConnectionState.disconnected);
    debugPrint('[MockClient] Disconnected.');
  }

  @override
  Future<void> sendMessage(BridgeMessage message) async {
    if (_state != ClientConnectionState.connected) {
      throw StateError('MockOfficeKitClientService: Not connected.');
    }
    debugPrint('[MockClient] → Sent: ${message.toJson()}');
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _incomingController.close();
  }

  void _updateState(ClientConnectionState next) {
    _state = next;
    _stateController.add(next);
  }
}
