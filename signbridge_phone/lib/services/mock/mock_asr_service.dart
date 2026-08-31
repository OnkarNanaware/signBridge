import 'dart:async';

import 'package:signbridge_phone/services/asr_service.dart';

/// Mock [AsrService] that emits canned speech phrases every 4 seconds.
///
/// Simulates hearing participants speaking in a meeting so the speech caption
/// panel can be exercised without a microphone or Vosk model.
class MockAsrService implements AsrService {
  static const List<String> _phrases = [
    'Good morning, everyone.',
    'Can you please repeat that?',
    'I understand, thank you.',
    'Let me pull up the document.',
    'Does anyone have questions?',
    'We will take a short break.',
    'Please go ahead.',
    'That is a great point.',
  ];

  final StreamController<String> _controller =
      StreamController<String>.broadcast();
  Timer? _timer;
  int _phraseIndex = 0;
  bool _isListening = false;

  @override
  Stream<String> get transcriptStream => _controller.stream;

  @override
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _timer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _emitNext(),
    );
  }

  @override
  Future<void> stopListening() async {
    _timer?.cancel();
    _timer = null;
    _isListening = false;
  }

  @override
  bool get isListening => _isListening;

  @override
  Future<void> dispose() async {
    await stopListening();
    await _controller.close();
  }

  void _emitNext() {
    _controller.add(_phrases[_phraseIndex % _phrases.length]);
    _phraseIndex++;
  }
}
