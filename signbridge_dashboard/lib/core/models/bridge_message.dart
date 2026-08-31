import 'dart:convert';

/// Direction of a bridge message (re-declared here to avoid cross-package dep).
enum BridgeDirection { phoneToDesktop, desktopToPhone }

/// Message types supported by the Office Kit Bridge.
enum BridgeMessageType { caption, speech, control, heartbeat }

/// A single message exchanged over the Office Kit Bridge WebSocket.
class BridgeMessage {
  const BridgeMessage({
    required this.type,
    required this.payload,
    required this.timestamp,
    this.direction = BridgeDirection.phoneToDesktop,
  });

  final BridgeMessageType type;
  final String payload;
  final DateTime timestamp;
  final BridgeDirection direction;

  String toJson() => jsonEncode(<String, dynamic>{
        'type': type.name,
        'payload': payload,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'direction': direction.name,
      });

  factory BridgeMessage.fromJson(String source) {
    final Map<String, dynamic> map = jsonDecode(source) as Map<String, dynamic>;
    return BridgeMessage(
      type: BridgeMessageType.values.firstWhere(
        (BridgeMessageType t) => t.name == (map['type'] as String),
        orElse: () => BridgeMessageType.heartbeat,
      ),
      payload: map['payload'] as String,
      timestamp:
          DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      direction: BridgeDirection.values.firstWhere(
        (BridgeDirection d) => d.name == (map['direction'] as String? ?? 'phoneToDesktop'),
        orElse: () => BridgeDirection.phoneToDesktop,
      ),
    );
  }

  factory BridgeMessage.control(String command) => BridgeMessage(
        type: BridgeMessageType.control,
        payload: command,
        timestamp: DateTime.now().toUtc(),
        direction: BridgeDirection.desktopToPhone,
      );

  @override
  String toString() => 'BridgeMessage(type=${type.name}, payload=$payload)';
}
