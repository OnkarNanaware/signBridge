import 'dart:convert';

/// Direction of a bridge message.
enum BridgeDirection {
  /// Phone → Dashboard
  phoneToDesktop,

  /// Dashboard → Phone
  desktopToPhone,
}

/// A single message exchanged over the Office Kit Bridge WebSocket.
///
/// Implements the shared JSON schema:
/// `{ "type": "sign_caption" | "speech_caption" | "dashboard_message", "text": "...", "confidence": 0.0, "ts": 1725100000000 }`
class BridgeMessage {
  const BridgeMessage({
    required this.type,
    required this.text,
    this.confidence = 1.0,
    required this.ts,
    this.direction = BridgeDirection.phoneToDesktop,
  });

  /// The message type discriminator ("sign_caption", "speech_caption", "dashboard_message", "control").
  final String type;

  /// Text content (e.g. recognized sign name, transcribed speech, or typed response).
  final String text;

  /// Confidence score in the range [0.0, 1.0].
  final double confidence;

  /// Epoch timestamp in milliseconds.
  final int ts;

  /// Direction of transport.
  final BridgeDirection direction;

  // ── Backward-compatible getters ───────────────────────────────────────────
  String get payload => text;
  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(ts);

  // ── JSON Serialization ───────────────────────────────────────────────────

  /// Serializes to the standard JSON contract string.
  String toJson() => jsonEncode(<String, dynamic>{
        'type': type,
        'text': text,
        'confidence': confidence,
        'ts': ts,
        'direction': direction.name,
      });

  /// Deserializes from a JSON string received over WebSocket.
  factory BridgeMessage.fromJson(String source) {
    final Map<String, dynamic> map =
        jsonDecode(source) as Map<String, dynamic>;

    final String typeStr = map['type'] as String? ?? 'sign_caption';
    final String textVal =
        (map['text'] as String?) ?? (map['payload'] as String?) ?? '';
    final double conf = (map['confidence'] as num?)?.toDouble() ?? 1.0;
    final int tsVal = (map['ts'] as num?)?.toInt() ??
        (map['timestamp'] as num?)?.toInt() ??
        DateTime.now().millisecondsSinceEpoch;

    final String dirStr = map['direction'] as String? ?? 'phoneToDesktop';
    final BridgeDirection dir = BridgeDirection.values.firstWhere(
      (BridgeDirection d) => d.name == dirStr,
      orElse: () => BridgeDirection.phoneToDesktop,
    );

    return BridgeMessage(
      type: typeStr,
      text: textVal,
      confidence: conf,
      ts: tsVal,
      direction: dir,
    );
  }

  // ── Factory Helpers ───────────────────────────────────────────────────────

  /// Creates a sign caption message from a recognised sign.
  factory BridgeMessage.signCaption(String signName, {double confidence = 1.0}) =>
      BridgeMessage(
        type: 'sign_caption',
        text: signName,
        confidence: confidence,
        ts: DateTime.now().millisecondsSinceEpoch,
        direction: BridgeDirection.phoneToDesktop,
      );

  /// Creates a speech caption message from an ASR transcript.
  factory BridgeMessage.speechCaption(String transcript, {double confidence = 1.0}) =>
      BridgeMessage(
        type: 'speech_caption',
        text: transcript,
        confidence: confidence,
        ts: DateTime.now().millisecondsSinceEpoch,
        direction: BridgeDirection.phoneToDesktop,
      );

  /// Creates a message typed by the hearing participant on the dashboard.
  factory BridgeMessage.dashboardMessage(String text) => BridgeMessage(
        type: 'dashboard_message',
        text: text,
        confidence: 1.0,
        ts: DateTime.now().millisecondsSinceEpoch,
        direction: BridgeDirection.desktopToPhone,
      );

  /// Creates a control command message.
  factory BridgeMessage.control(String command) => BridgeMessage(
        type: 'control',
        text: command,
        confidence: 1.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  /// Legacy alias for sign captions.
  factory BridgeMessage.caption(String signName, {double confidence = 1.0}) =>
      BridgeMessage.signCaption(signName, confidence: confidence);

  /// Legacy alias for speech transcripts.
  factory BridgeMessage.speech(String transcript) =>
      BridgeMessage.speechCaption(transcript);

  /// Creates a heartbeat ping.
  factory BridgeMessage.heartbeat() => BridgeMessage(
        type: 'heartbeat',
        text: 'ping',
        confidence: 1.0,
        ts: DateTime.now().millisecondsSinceEpoch,
      );

  @override
  String toString() =>
      'BridgeMessage(type=$type, text=$text, '
      'conf=${confidence.toStringAsFixed(2)}, ts=$ts)';
}
