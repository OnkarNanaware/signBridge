import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/services/asr_service.dart';
import 'package:signbridge_phone/shared/widgets/caption_text.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';
import 'package:signbridge_phone/shared/widgets/status_chip.dart';

/// Panel that displays the live offline ASR speech transcript and mic controls.
class SpeechCapturePanel extends ConsumerStatefulWidget {
  const SpeechCapturePanel({super.key});

  @override
  ConsumerState<SpeechCapturePanel> createState() => _SpeechCapturePanelState();
}

class _SpeechCapturePanelState extends ConsumerState<SpeechCapturePanel> {
  final List<String> _transcripts = [];
  final ScrollController _scrollController = ScrollController();
  static const int _maxTranscripts = 10;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    // Check initial listening status
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AsrService asr = ref.read(asrServiceProvider);
      if (mounted) setState(() => _isListening = asr.isListening);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onNewTranscript(String text) {
    setState(() {
      _transcripts.add(text);
      if (_transcripts.length > _maxTranscripts) {
        _transcripts.removeAt(0);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    final AsrService asr = ref.read(asrServiceProvider);
    if (_isListening) {
      await asr.stopListening();
      if (mounted) setState(() => _isListening = false);
    } else {
      await asr.startListening();
      if (mounted) setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ref.listen<AsyncValue<String>>(asrTranscriptStreamProvider, (_, next) {
      next.whenData(_onNewTranscript);
    });

    return PanelCard(
      title: 'Speech → Text',
      icon: Icons.mic_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StatusChip(
            label: _isListening ? 'Mic Active' : 'Mic Idle',
            color: _isListening ? AppTheme.statusConnected : AppTheme.statusDisconnected,
            animate: _isListening,
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              _isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
              color: _isListening ? AppTheme.statusError : theme.colorScheme.primary,
            ),
            tooltip: _isListening ? 'Mute Microphone' : 'Start Speech Recognition',
            onPressed: _toggleListening,
          ),
        ],
      ),
      child: SizedBox(
        height: 160,
        child: _transcripts.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                      size: 32,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isListening
                          ? 'Listening for speech (Vosk offline)...'
                          : 'Microphone paused. Tap mic icon to listen.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
            : ListView.separated(
                controller: _scrollController,
                itemCount: _transcripts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (BuildContext context, int index) {
                  final bool isLatest = index == _transcripts.length - 1;
                  return AnimatedOpacity(
                    opacity: isLatest ? 1.0 : 0.55,
                    duration: const Duration(milliseconds: 300),
                    child: CaptionText(
                      _transcripts[index],
                      size: CaptionSize.small,
                      textAlign: TextAlign.left,
                      maxLines: 2,
                    ),
                  );
                },
              ),
      ),
    );
  }
}
