import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/constants/app_constants.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';
import 'package:signbridge_phone/features/sign_library_manager/presentation/record_sign_modal.dart';

/// Displays and manages the local sign reference library.
///
/// Features:
/// - Pre-seeded curated 25-sign vocabulary list.
/// - Sample status badges and counts per sign.
/// - Hold-to-record sample collection with multi-sample support for robustness.
/// - Local Hive persistence in [kSignLibraryBox].
class SignLibraryScreen extends ConsumerStatefulWidget {
  const SignLibraryScreen({super.key});

  @override
  ConsumerState<SignLibraryScreen> createState() => _SignLibraryScreenState();
}

class _SignLibraryScreenState extends ConsumerState<SignLibraryScreen> {
  List<SignEntry> _allEntries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  Future<void> _loadSigns() async {
    final List<SignEntry> entries =
        await ref.read(signLibraryRepositoryProvider).getAllSigns();
    if (mounted) {
      setState(() {
        _allEntries = entries;
        _loading = false;
      });
    }
  }

  Future<void> _openRecordModal(String signName) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => RecordSignModal(signName: signName),
        fullscreenDialog: true,
      ),
    );
    // Reload signs when returning from recording
    await _loadSigns();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Group recorded entries by sign name
    final Map<String, List<SignEntry>> sampleMap = {};
    for (final SignEntry entry in _allEntries) {
      sampleMap.putIfAbsent(entry.signName, () => []).add(entry);
    }

    final int recordedCount = sampleMap.keys.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Library'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                '$recordedCount / ${kSignVocabulary.length} recorded',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              backgroundColor:
                  theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: kSignVocabulary.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (BuildContext context, int index) {
                final String signName = kSignVocabulary[index];
                final List<SignEntry> samples = sampleMap[signName] ?? [];
                final bool hasSamples = samples.isNotEmpty;

                return Card(
                  elevation: hasSamples ? 2 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: hasSamples
                          ? AppTheme.statusConnected.withValues(alpha: 0.4)
                          : theme.colorScheme.outline.withValues(alpha: 0.2),
                      width: hasSamples ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    onTap: () => _openRecordModal(signName),
                    leading: CircleAvatar(
                      backgroundColor: hasSamples
                          ? AppTheme.statusConnected.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      child: Icon(
                        hasSamples
                            ? Icons.check_circle_rounded
                            : Icons.sign_language_rounded,
                        size: 20,
                        color: hasSamples
                            ? AppTheme.statusConnected
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    title: Text(
                      signName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      hasSamples
                          ? '${samples.length} sample${samples.length == 1 ? '' : 's'} recorded · '
                              'avg ${(samples.map((e) => e.frameCount).reduce((a, b) => a + b) / samples.length).toStringAsFixed(0)} frames'
                          : 'No samples recorded yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: hasSamples
                            ? theme.colorScheme.onSurface.withValues(alpha: 0.7)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                    trailing: FilledButton.tonal(
                      onPressed: () => _openRecordModal(signName),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            hasSamples
                                ? Icons.add_circle_outline
                                : Icons.fiber_manual_record,
                            size: 14,
                            color: hasSamples
                                ? theme.colorScheme.primary
                                : AppTheme.statusError,
                          ),
                          const SizedBox(width: 4),
                          Text(hasSamples ? 'Add Sample' : 'Record'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Find first unrecorded sign or fallback to first sign
          final String target = kSignVocabulary.firstWhere(
            (String s) => !sampleMap.containsKey(s),
            orElse: () => kSignVocabulary.first,
          );
          _openRecordModal(target);
        },
        icon: const Icon(Icons.fiber_manual_record_rounded),
        label: const Text('Record Next Sign'),
        backgroundColor: AppTheme.statusConnected,
        foregroundColor: Colors.white,
      ),
    );
  }
}
