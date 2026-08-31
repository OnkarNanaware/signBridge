import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/tts_service.dart';

/// Real [TtsService] implementation using `flutter_tts`.
///
/// Converts incoming text from the hearing participant's dashboard into spoken
/// audio on the phone's speaker without requiring an internet connection.
class FlutterTtsService implements TtsService {
  FlutterTtsService(this._activityLogService) {
    _initTts();
  }

  final ActivityLogService _activityLogService;
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  void _initTts() {
    _flutterTts.setStartHandler(() {
      _isSpeaking = true;
    });

    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    _flutterTts.setErrorHandler((dynamic msg) {
      _isSpeaking = false;
      debugPrint('TTS Error: $msg');
    });

    // Default configuration for clean, natural speech playback
    _flutterTts.setLanguage('en-US');
    _flutterTts.setSpeechRate(0.5);
    _flutterTts.setVolume(1.0);
    _flutterTts.setPitch(1.0);
  }

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> speak(String text) async {
    final String cleanText = text.trim();
    if (cleanText.isEmpty) return;

    await _activityLogService.log(
      EventType.ttsSpeak,
      'TTS speaking: "$cleanText"',
    );

    try {
      await _flutterTts.speak(cleanText);
    } catch (e) {
      debugPrint('FlutterTts speak exception: $e');
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isSpeaking = false;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    await _flutterTts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
