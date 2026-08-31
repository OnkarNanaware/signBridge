/// Abstract interface for offline automatic speech recognition (ASR).
///
/// In Phase 2 the real implementation will use the Vosk offline model
/// running via vosk_flutter (or Whisper.cpp FFI as fallback). All heavy
/// decoding MUST run off the UI isolate.
abstract class AsrService {
  /// A broadcast stream of recognised speech transcripts.
  ///
  /// Events are emitted as the ASR model produces partial or final
  /// transcripts. Each string is a sentence or phrase segment.
  Stream<String> get transcriptStream;

  /// Starts listening to the microphone and feeding audio to the ASR model.
  Future<void> startListening();

  /// Stops the microphone and ASR decoding.
  Future<void> stopListening();

  /// Whether the ASR service is currently active.
  bool get isListening;

  /// Disposes the service and releases mic/model resources.
  Future<void> dispose();
}
