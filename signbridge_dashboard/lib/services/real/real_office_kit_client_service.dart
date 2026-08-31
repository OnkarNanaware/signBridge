import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/services/activity_log_service.dart';
import 'package:signbridge_dashboard/services/office_kit_client_service.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Real [OfficeKitClientService] implementation connecting to the phone's
/// WebSocket server over local Wi-Fi or USB tethering.
class RealOfficeKitClientService implements OfficeKitClientService {
  RealOfficeKitClientService(this._activityLogService);

  final ActivityLogService _activityLogService;

  final StreamController<ClientConnectionState> _connectionStateController =
      StreamController<ClientConnectionState>.broadcast();
  final StreamController<BridgeMessage> _incomingMessageController =
      StreamController<BridgeMessage>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _channelSub;
  ClientConnectionState _state = ClientConnectionState.disconnected;

  @override
  Stream<ClientConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  ClientConnectionState get connectionState => _state;

  @override
  Stream<BridgeMessage> get incomingMessageStream =>
      _incomingMessageController.stream;

  void _updateState(ClientConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }

  @override
  Future<void> connect(String host, int port) async {
    await disconnect();

    _updateState(ClientConnectionState.connecting);

    final Uri uri = Uri.parse('ws://$host:$port');

    try {
      final IOWebSocketChannel channel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 5),
      );
      _channel = channel;

      _channelSub = channel.stream.listen(
        (dynamic data) {
          if (_state != ClientConnectionState.connected) {
            _updateState(ClientConnectionState.connected);
            _activityLogService.log(
              EventType.bridgeConnected,
              'Connected to phone bridge at $host:$port',
            );
          }
          _handleIncoming(data.toString());
        },
        onDone: () {
          _updateState(ClientConnectionState.disconnected);
          _activityLogService.log(
            EventType.bridgeDisconnected,
            'Disconnected from phone bridge',
          );
        },
        onError: (dynamic error) {
          debugPrint('WebSocket error: $error');
          _updateState(ClientConnectionState.error);
          _activityLogService.log(
            EventType.error,
            'Bridge connection error: $error',
          );
        },
      );

      // Give connection a moment to verify socket readiness
      _updateState(ClientConnectionState.connected);
      await _activityLogService.log(
        EventType.bridgeConnected,
        'Connecting to phone at $host:$port...',
      );
    } catch (e) {
      debugPrint('Failed to connect to WebSocket: $e');
      _updateState(ClientConnectionState.error);
      await _activityLogService.log(
        EventType.error,
        'Connection failed: $e',
      );
    }
  }

  void _handleIncoming(String raw) {
    try {
      final BridgeMessage message = BridgeMessage.fromJson(raw);

      if (!_incomingMessageController.isClosed) {
        _incomingMessageController.add(message);
      }

      // Persist in local Hive activity log
      if (message.type == 'sign_caption') {
        _activityLogService.log(
          EventType.captionReceived,
          'Sign: "${message.text}" (${(message.confidence * 100).toStringAsFixed(0)}% conf)',
        );
      } else if (message.type == 'speech_caption') {
        _activityLogService.log(
          EventType.speechReceived,
          'Speech: "${message.text}"',
        );
      } else {
        _activityLogService.log(
          EventType.captionReceived,
          '${message.type}: "${message.text}"',
        );
      }
    } catch (e) {
      debugPrint('Failed to parse incoming dashboard message: $e');
    }
  }

  @override
  Future<void> sendMessage(BridgeMessage message) async {
    if (_state != ClientConnectionState.connected || _channel == null) {
      throw StateError('Cannot send message: Not connected to phone bridge.');
    }

    final String jsonStr = message.toJson();
    _channel!.sink.add(jsonStr);

    await _activityLogService.log(
      EventType.controlSent,
      'Sent ${message.type}: "${message.text}"',
    );
  }

  @override
  Future<void> disconnect() async {
    await _channelSub?.cancel();
    _channelSub = null;

    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    _updateState(ClientConnectionState.disconnected);
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _connectionStateController.close();
    await _incomingMessageController.close();
  }
}
