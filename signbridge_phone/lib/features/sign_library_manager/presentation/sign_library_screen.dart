import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_phone/core/di/providers.dart';
import 'package:signbridge_phone/core/models/sign_entry.dart';
import 'package:signbridge_phone/core/theme/app_theme.dart';

/// Displays and manages the local sign reference library.
///
/// Phase 1: read-only listing of seeded/recorded signs.
/// Phase 2: adds record button to capture a new reference sign.
class SignLibraryScreen extends ConsumerStatefulWidget {
  const SignLibraryScreen({super.key});

  @override
  ConsumerState<SignLibraryScreen> createState() => _SignLibraryScreenState();
}

class _SignLibraryScreenState extends ConsumerState<SignLibraryScreen> {
  List<SignEntry> _signs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSigns();
  }

  Future<void> _loadSigns() async {
    final List<SignEntry> signs =
        await ref.read(signLibraryRepositoryProvider).getAllSigns();
    if (mounted) {
      setState(() {
        _signs = signs;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Library'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              label: Text(
                '${_signs.length} signs',
                style: const TextStyle(fontSize: 12),
              ),
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _signs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.sign_language_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No signs recorded yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phase 2 will add sign recording.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _signs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (BuildContext context, int index) {
                    final SignEntry sign = _signs[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withValues(alpha: 0.15),
                          child: Icon(
                            Icons.sign_language_rounded,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          sign.signName,
                          style: theme.textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${sign.frameCount} frames · '
                          'Recorded ${_formatDate(sign.dateRecorded)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO(phase2): Launch sign recording flow.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign recording arrives in Phase 2 🚀'),
            ),
          );
        },
        icon: const Icon(Icons.fiber_manual_record_rounded),
        label: const Text('Record Sign'),
        backgroundColor: AppTheme.statusConnected,
        foregroundColor: Colors.white,
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')}';
  }
}
