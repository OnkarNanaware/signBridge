import 'dart:convert';

import 'package:signbridge_phone/core/constants/app_constants.dart';

/// Direction of a bridge message.
enum BridgeDirection {
  /// Phone → Dashboard
  phoneToDesktop,

  /// Dashboard → Phone
  desktopToPhone,
}

/// The type of payload carried in a [BridgeMessage].
enum BridgeMessageType {
  /// A recognised sign caption (phone → desktop).
  caption,

  /// An ASR speech transcript (phone → desktop).
  speech,

  /// A control command (e.g. start/stop session) — either direction.
  control,

  /// Keep-alive heartbeat — either direction.
  heartbeat,
}

/// A single message exchanged over the Office Kit Bridge WebSocket.
///
/// Serialises to / from a JSON string for wire transport.
class BridgeMessage {
  const BridgeMessage({
    required this.type,
    required this.payload,
    required this.timestamp,
    this.direction = BridgeDirection.phoneToDesktop,
  });

  final BridgeMessageType type;

  /// Free-form string payload. For captions this is the sign name; for speech
  /// this is the ASR transcript; for control this is a command key.
  final String payload;

  final DateTime timestamp;
  final BridgeDirection direction;

  // ── JSON ──────────────────────────────────────────────────────────────────

  /// Serialises to a JSON string suitable for WebSocket.send().
  String toJson() => jsonEncode(<String, dynamic>{
        'type': _typeToString(type),
        'payload': payload,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'direction': direction.name,
      });

  /// Deserialises from a JSON string received over the WebSocket.
  factory BridgeMessage.fromJson(String source) {
    final Map<String, dynamic> map =
        jsonDecode(source) as Map<String, dynamic>;
    return BridgeMessage(
      type: _typeFromString(map['type'] as String),
      payload: map['payload'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      direction: BridgeDirection.values.firstWhere(
        (BridgeDirection d) => d.name == (map['direction'] as String? ?? 'phoneToDesktop'),
        orElse: () => BridgeDirection.phoneToDesktop,
      ),
    );
  }

  // ── Factory helpers ───────────────────────────────────────────────────────

  /// Creates a caption message from a recognised sign name.
  factory BridgeMessage.caption(String signName) => BridgeMessage(
        type: BridgeMessageType.caption,
        payload: signName,
        timestamp: DateTime.now().toUtc(),
      );

  /// Creates a speech message from an ASR transcript.
  factory BridgeMessage.speech(String transcript) => BridgeMessage(
        type: BridgeMessageType.speech,
        payload: transcript,
        timestamp: DateTime.now().toUtc(),
      );

  /// Creates a heartbeat message.
  factory BridgeMessage.heartbeat() => BridgeMessage(
        type: BridgeMessageType.heartbeat,
        payload: 'ping',
        timestamp: DateTime.now().toUtc(),
      );

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _typeToString(BridgeMessageType t) {
    switch (t) {
      case BridgeMessageType.caption:
        return kBridgeMsgCaption;
      case BridgeMessageType.speech:
        return kBridgeMsgSpeech;
      case BridgeMessageType.control:
        return kBridgeMsgControl;
      case BridgeMessageType.heartbeat:
        return kBridgeMsgHeartbeat;
    }
  }

  static BridgeMessageType _typeFromString(String s) {
    switch (s) {
      case kBridgeMsgCaption:
        return BridgeMessageType.caption;
      case kBridgeMsgSpeech:
        return BridgeMessageType.speech;
      case kBridgeMsgControl:
        return BridgeMessageType.control;
      default:
        return BridgeMessageType.heartbeat;
    }
  }

  @override
  String toString() =>
      'BridgeMessage(type=${type.name}, payload=$payload, '
      'ts=${timestamp.millisecondsSinceEpoch})';
}
