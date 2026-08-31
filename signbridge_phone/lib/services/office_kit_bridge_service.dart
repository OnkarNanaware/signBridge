import 'package:signbridge_phone/core/models/bridge_message.dart';

/// Connection state of the Office Kit Bridge.
enum BridgeConnectionState {
  disconnected,
  searching,
  connecting,
  connected,
  error,
}

/// Abstract interface for the Office Kit Bridge — the two-way WebSocket
/// connection between the phone (server) and the laptop dashboard (client).
///
/// The real implementation uses `shelf` + `shelf_web_socket` to run a
/// WebSocket server on [kBridgePort] that the desktop client connects to
/// over local Wi-Fi or USB. All traffic stays on the device pair —
/// no data ever reaches the internet.
abstract class OfficeKitBridgeService {
  /// A broadcast stream of the current connection state.
  Stream<BridgeConnectionState> get connectionStateStream;

  /// The current connection state (synchronous snapshot).
  BridgeConnectionState get connectionState;

  /// A broadcast stream of messages received FROM the desktop dashboard.
  Stream<BridgeMessage> get incomingMessageStream;

  /// Starts the WebSocket server and begins accepting connections.
  Future<void> startServer();

  /// Stops the WebSocket server and disconnects any active client.
  Future<void> stopServer();

  /// Sends a [message] to the connected desktop dashboard.
  ///
  /// Throws a [StateError] if no client is currently connected.
  Future<void> sendMessage(BridgeMessage message);

  /// Disposes the server and closes all streams.
  Future<void> dispose();
}
