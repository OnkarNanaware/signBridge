import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:signbridge_phone/core/models/activity_log_entry.dart';
import 'package:signbridge_phone/services/activity_log_service.dart';
import 'package:signbridge_phone/services/asr_service.dart';
import 'package:vosk_flutter/vosk_flutter.dart';

/// Real [AsrService] integrating Vosk offline speech recognition.
///
/// Uses the bundled offline model [vosk-model-small-en-us-0.15.zip] located in
/// `assets/models/`. Operates completely on-device without internet access.
/// Emits both partial and final speech transcripts and logs microphone events
/// to [ActivityLogService].
class VoskAsrService implements AsrService {
  VoskAsrService(this._activityLogService);

  static const String _modelAssetPath =
      'assets/models/vosk-model-small-en-us-0.15.zip';

  final ActivityLogService _activityLogService;
  final StreamController<String> _transcriptController =
      StreamController<String>.broadcast();

  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  SpeechService? _speechService;

  StreamSubscription<String>? _partialSub;
  StreamSubscription<String>? _resultSub;

  bool _isInitialized = false;
  bool _isListening = false;

  @override
  Stream<String> get transcriptStream => _transcriptController.stream;

  @override
  bool get isListening => _isListening;

  /// Initializes the offline Vosk speech recognition engine.
  Future<void> _initEngine() async {
    if (_isInitialized) return;

    if (!Platform.isAndroid && !Platform.isIOS) {
      // Vosk Flutter plugin native library primarily targets mobile platforms.
      debugPrint('Vosk ASR: Running on desktop/unsupported platform, skipping native init.');
      _isInitialized = true;
      return;
    }

    try {
      final String modelPath =
          await ModelLoader().loadFromAssets(_modelAssetPath);
      _model = await _vosk.createModel(modelPath);
      _recognizer = await _vosk.createRecognizer(
        model: _model!,
        sampleRate: 16000,
      );

      _speechService = await _vosk.initSpeechService(_recognizer!);

      _partialSub = _speechService!.onPartial().listen((String raw) {
        _handleRawResult(raw, isPartial: true);
      });

      _resultSub = _speechService!.onResult().listen((String raw) {
        _handleRawResult(raw, isPartial: false);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Vosk ASR engine initialization error: $e');
      await _activityLogService.log(
        EventType.error,
        'Vosk ASR init error: $e',
      );
    }
  }

  void _handleRawResult(String rawJson, {required bool isPartial}) {
    try {
      final Map<String, dynamic> data =
          jsonDecode(rawJson) as Map<String, dynamic>;
      final String text = (isPartial
              ? (data['partial'] as String?)
              : (data['text'] as String?))
          ?.trim() ??
          '';

      if (text.isNotEmpty) {
        if (!_transcriptController.isClosed) {
          _transcriptController.add(text);
        }

        if (!isPartial) {
          _activityLogService.log(
            EventType.asrTranscript,
            'Transcribed: "$text"',
          );
        }
      }
    } catch (_) {
      // Ignore JSON parse errors from raw audio frames
    }
  }

  @override
  Future<void> startListening() async {
    if (_isListening) return;

    await _initEngine();

    if (_speechService != null) {
      try {
        await _speechService!.start();
        _isListening = true;
        await _activityLogService.log(
          EventType.micActivated,
          'Microphone activated for offline ASR (Vosk)',
        );
      } catch (e) {
        debugPrint('Failed to start speech service: $e');
      }
    } else {
      _isListening = true;
      await _activityLogService.log(
        EventType.micActivated,
        'Microphone activated (simulated offline mode)',
      );
    }
  }

  @override
  Future<void> stopListening() async {
    if (!_isListening) return;

    if (_speechService != null) {
      try {
        await _speechService!.stop();
      } catch (_) {}
    }

    _isListening = false;
    await _activityLogService.log(
      EventType.micDeactivated,
      'Microphone deactivated',
    );
  }

  @override
  Future<void> dispose() async {
    await stopListening();
    await _partialSub?.cancel();
    await _resultSub?.cancel();
    _speechService?.dispose();
    _recognizer?.dispose();
    _model?.dispose();
    await _transcriptController.close();
  }
}
