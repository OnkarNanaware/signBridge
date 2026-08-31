import 'package:signbridge_dashboard/core/models/bridge_message.dart';

/// Connection state from the desktop client perspective.
enum ClientConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Abstract interface for the Office Kit client WebSocket connection.
///
/// The desktop app connects to the phone's WebSocket server (running on
/// [kBridgePort]) over local Wi-Fi or USB. The connection is two-way:
/// the desktop receives caption/speech events and can send control commands.
abstract class OfficeKitClientService {
  /// Stream of the current connection state.
  Stream<ClientConnectionState> get connectionStateStream;

  /// Current connection state (synchronous snapshot).
  ClientConnectionState get connectionState;

  /// Stream of messages received FROM the phone.
  Stream<BridgeMessage> get incomingMessageStream;

  /// Connects to the phone's WebSocket server at [host]:[port].
  ///
  /// The [host] is the phone's local IP address (e.g. '192.168.1.42').
  /// [port] should be [kBridgePort] (8765) by default.
  Future<void> connect(String host, int port);

  /// Disconnects from the phone's server.
  Future<void> disconnect();

  /// Sends a control [message] to the phone.
  ///
  /// Throws [StateError] if not connected.
  Future<void> sendMessage(BridgeMessage message);

  /// Disposes the client and closes all streams.
  Future<void> dispose();
}
