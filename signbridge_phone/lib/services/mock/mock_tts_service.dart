import 'package:flutter/foundation.dart';
import 'package:signbridge_phone/services/tts_service.dart';

/// Mock [TtsService] that prints to the debug console instead of speaking.
///
/// Allows the full pipeline to run silently during demo mode without
/// requiring the flutter_tts platform channel.
class MockTtsService implements TtsService {
  final List<String> spokenTexts = <String>[];
  bool _isSpeaking = false;
  double _speechRate = 1.0;
  double _volume = 1.0;

  @override
  Future<void> speak(String text) async {
    _isSpeaking = true;
    spokenTexts.add(text);
    debugPrint('[MockTTS] Speaking: "$text"');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    _isSpeaking = false;
    debugPrint('[MockTTS] Stopped.');
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    debugPrint('[MockTTS] Speech rate set to $_speechRate');
  }

  @override
  Future<void> setVolume(double volume) async {
    _volume = volume;
    debugPrint('[MockTTS] Volume set to $_volume');
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> dispose() async {
    _isSpeaking = false;
  }
}
