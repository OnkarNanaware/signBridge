import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/core/models/bridge_message.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';
import 'package:signbridge_phone/services/tts_service.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Real [OfficeKitBridgeService] hosting a local WebSocket server on the phone.
///
/// Uses `shelf` + `shelf_web_socket` to accept connections from the Windows
/// dashboard over local Wi-Fi or USB tethering on [kBridgePort] (8765).
/// All traffic stays strictly on the phone↔desktop device pair.
class ShelfOfficeKitBridgeService implements OfficeKitBridgeService {
  ShelfOfficeKitBridgeService({
    required ActivityLogService activityLogService,
    required TtsService ttsService,
  })  : _activityLogService = activityLogService,
        _ttsService = ttsService;

  final ActivityLogService _activityLogService;
  final TtsService _ttsService;

  final StreamController<BridgeConnectionState> _connectionStateController =
      StreamController<BridgeConnectionState>.broadcast();
  final StreamController<BridgeMessage> _incomingMessageController =
      StreamController<BridgeMessage>.broadcast();

  final Set<WebSocketChannel> _clients = <WebSocketChannel>{};
  HttpServer? _server;
  BridgeConnectionState _state = BridgeConnectionState.disconnected;

  @override
  Stream<BridgeConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  BridgeConnectionState get connectionState => _state;

  @override
  Stream<BridgeMessage> get incomingMessageStream =>
      _incomingMessageController.stream;

  /// Returns the number of currently connected dashboard clients.
  int get clientCount => _clients.length;

  void _updateState(BridgeConnectionState newState) {
    if (_state == newState) return;
    _state = newState;
    if (!_connectionStateController.isClosed) {
      _connectionStateController.add(newState);
    }
  }

  @override
  Future<void> startServer() async {
    if (_server != null) return;

    try {
      final handler = webSocketHandler(
        (WebSocketChannel channel) {
          _clients.add(channel);
          _updateState(BridgeConnectionState.connected);

          _activityLogService.log(
            EventType.bridgeConnected,
            'Dashboard connected (${_clients.length} client active)',
          );

          channel.stream.listen(
            (dynamic data) {
              _handleIncomingRaw(data.toString());
            },
            onDone: () {
              _clients.remove(channel);
              _handleClientDisconnect();
            },
            onError: (dynamic error) {
              _clients.remove(channel);
              _handleClientDisconnect();
            },
          );
        },
      );

      _server = await shelf_io.serve(
        handler,
        InternetAddress.anyIPv4,
        kBridgePort,
      );

      _updateState(BridgeConnectionState.searching);

      await _activityLogService.log(
        EventType.bridgeConnected,
        'WebSocket server started on port $kBridgePort (waiting for dashboard)',
      );
    } catch (e) {
      debugPrint('Failed to start WebSocket server: $e');
      _updateState(BridgeConnectionState.error);
      await _activityLogService.log(
        EventType.error,
        'Failed to start WebSocket server: $e',
      );
    }
  }

  void _handleClientDisconnect() {
    if (_clients.isEmpty) {
      _updateState(
        _server != null
            ? BridgeConnectionState.searching
            : BridgeConnectionState.disconnected,
      );
      _activityLogService.log(
        EventType.bridgeDisconnected,
        'Dashboard disconnected (0 clients active)',
      );
    }
  }

  void _handleIncomingRaw(String raw) {
    try {
      final BridgeMessage message = BridgeMessage.fromJson(raw);

      if (!_incomingMessageController.isClosed) {
        _incomingMessageController.add(message);
      }

      _activityLogService.log(
        EventType.bridgeMessageReceived,
        'Received ${message.type}: "${message.text}"',
      );

      // Requirement 3: incoming messages from dashboard feed into TtsService
      if (message.type == 'dashboard_message') {
        _ttsService.speak(message.text);
      }
    } catch (e) {
      debugPrint('Failed to parse incoming bridge message: $e');
    }
  }

  @override
  Future<void> sendMessage(BridgeMessage message) async {
    final String jsonString = message.toJson();

    for (final WebSocketChannel client in _clients) {
      try {
        client.sink.add(jsonString);
      } catch (e) {
        debugPrint('Error sending message to client: $e');
      }
    }

    await _activityLogService.log(
      EventType.bridgeMessageSent,
      'Sent ${message.type}: "${message.text}"',
    );
  }

  @override
  Future<void> stopServer() async {
    final List<WebSocketChannel> activeClients = _clients.toList();
    for (final WebSocketChannel client in activeClients) {
      try {
        await client.sink.close();
      } catch (_) {}
    }
    _clients.clear();

    await _server?.close(force: true);
    _server = null;

    _updateState(BridgeConnectionState.disconnected);

    await _activityLogService.log(
      EventType.bridgeDisconnected,
      'WebSocket server stopped',
    );
  }

  @override
  Future<void> dispose() async {
    await stopServer();
    await _connectionStateController.close();
    await _incomingMessageController.close();
  }
}
