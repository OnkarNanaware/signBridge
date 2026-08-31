/// Abstract interface for on-device Text-to-Speech output.
///
/// Uses `flutter_tts` under the hood. Must not require network access.
abstract class TtsService {
  /// Speaks the given [text] aloud using the device TTS engine.
  ///
  /// If speech is already in progress, the new [text] is queued.
  Future<void> speak(String text);

  /// Stops any currently playing speech.
  Future<void> stop();

  /// Sets the speech rate (0.0 = slowest, 1.0 = normal, 2.0 = fast).
  Future<void> setSpeechRate(double rate);

  /// Sets the speech volume (0.0 = silent, 1.0 = full).
  Future<void> setVolume(double volume);

  /// Whether the TTS engine is currently speaking.
  bool get isSpeaking;

  /// Disposes TTS engine resources.
  Future<void> dispose();
}
