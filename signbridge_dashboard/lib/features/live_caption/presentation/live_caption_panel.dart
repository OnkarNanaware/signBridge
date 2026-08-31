import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/di/providers.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/core/theme/app_theme.dart';
import 'package:signbridge_dashboard/shared/widgets/caption_text.dart';
import 'package:signbridge_dashboard/shared/widgets/panel_card.dart';

/// Live caption panel — the primary display for the hearing participant.
///
/// Shows an auto-scrolling list of recognised sign captions and ASR speech
/// transcripts, with the most recent item displayed prominently at the top
/// in large high-contrast text. Includes a copy-to-clipboard button.
class LiveCaptionPanel extends ConsumerStatefulWidget {
  const LiveCaptionPanel({super.key});

  @override
  ConsumerState<LiveCaptionPanel> createState() => _LiveCaptionPanelState();
}

class _LiveCaptionPanelState extends ConsumerState<LiveCaptionPanel>
    with SingleTickerProviderStateMixin {
  final List<_CaptionItem> _items = [];
  final ScrollController _scrollController = ScrollController();
  static const int _maxItems = 20;

  late AnimationController _flashController;
  late Animation<double> _flashAnim;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _flashAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _flashController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onMessage(BridgeMessage msg) {
    if (msg.type != BridgeMessageType.caption &&
        msg.type != BridgeMessageType.speech) {
      return;
    }

    setState(() {
      _items.insert(
        0,
        _CaptionItem(
          text: msg.payload,
          type: msg.type,
          timestamp: msg.timestamp,
        ),
      );
      if (_items.length > _maxItems) _items.removeLast();
    });
    _flashController
      ..reset()
      ..forward();
  }

  Future<void> _copyAll() async {
    final String text = _items.map((i) => i.text).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Captions copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    ref.listen<AsyncValue<BridgeMessage>>(incomingMessageStreamProvider, (_, next) {
      next.whenData(_onMessage);
    });

    return PanelCard(
      title: 'Live Caption',
      icon: Icons.closed_caption_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              tooltip: 'Copy all captions',
              onPressed: _copyAll,
            ),
        ],
      ),
      child: SizedBox(
        height: 340,
        child: _items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hearing_rounded,
                      size: 48,
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waiting for captions…',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero caption — most recent, large display
                  AnimatedBuilder(
                    animation: _flashAnim,
                    builder: (BuildContext context, Widget? child) =>
                        Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary
                            .withValues(alpha: _flashAnim.value * 0.10),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: child,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeBadge(type: _items.first.type),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CaptionText(
                            _items.first.text,
                            size: CaptionSize.large,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  // History
                  Expanded(
                    child: ListView.separated(
                      controller: _scrollController,
                      itemCount: _items.length - 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 2),
                      itemBuilder: (BuildContext context, int index) {
                        final _CaptionItem item = _items[index + 1];
                        return AnimatedOpacity(
                          opacity: 0.45 - index * 0.03,
                          duration: const Duration(milliseconds: 200),
                          child: Row(
                            children: [
                              _TypeBadge(type: item.type, small: true),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CaptionText(
                                  item.text,
                                  size: CaptionSize.small,
                                  maxLines: 1,
                                ),
                              ),
                              Text(
                                _formatTime(item.timestamp),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final DateTime local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}:'
        '${local.second.toString().padLeft(2, '0')}';
  }
}

class _CaptionItem {
  const _CaptionItem({
    required this.text,
    required this.type,
    required this.timestamp,
  });
  final String text;
  final BridgeMessageType type;
  final DateTime timestamp;
}

/// Small badge indicating whether a caption came from sign recognition or ASR.
class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.type, this.small = false});

  final BridgeMessageType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isSign = type == BridgeMessageType.caption;
    final Color color = isSign
        ? theme.colorScheme.primary
        : AppTheme.statusSearching;
    final String label = isSign ? 'SIGN' : 'SPEECH';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 7,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: small ? 9 : 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
