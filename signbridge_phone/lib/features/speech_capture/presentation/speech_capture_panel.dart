import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/shared/widgets/caption_text.dart';
import 'package:signbridge_phone/shared/widgets/panel_card.dart';

/// Panel that displays the live ASR speech transcript.
///
/// Maintains a scrollable list of the last 10 transcript segments,
/// auto-scrolling to the bottom as new segments arrive.
class SpeechCapturePanel extends ConsumerStatefulWidget {
  const SpeechCapturePanel({super.key});

  @override
  ConsumerState<SpeechCapturePanel> createState() => _SpeechCapturePanelState();
}

class _SpeechCapturePanelState extends ConsumerState<SpeechCapturePanel> {
  final List<String> _transcripts = [];
  final ScrollController _scrollController = ScrollController();
  static const int _maxTranscripts = 10;

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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ref.listen<AsyncValue<String>>(asrTranscriptStreamProvider, (_, next) {
      next.whenData(_onNewTranscript);
    });

    return PanelCard(
      title: 'Speech → Text',
      icon: Icons.mic_rounded,
      child: SizedBox(
        height: 160,
        child: _transcripts.isEmpty
            ? Center(
                child: Text(
                  'Listening for speech…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
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
