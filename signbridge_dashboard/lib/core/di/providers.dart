import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signbridge_dashboard/core/models/activity_log_entry.dart';
import 'package:signbridge_dashboard/core/models/bridge_message.dart';
import 'package:signbridge_dashboard/services/activity_log_service.dart';
import 'package:signbridge_dashboard/services/mock/mock_activity_log_service.dart';
import 'package:signbridge_dashboard/services/mock/mock_office_kit_client_service.dart';
import 'package:signbridge_dashboard/services/office_kit_client_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Feature flag — flip to false in Phase 2 to use real services.
// ─────────────────────────────────────────────────────────────────────────────
const bool useMockServices = true;

// ─────────────────────────────────────────────────────────────────────────────
// Service Providers
// ─────────────────────────────────────────────────────────────────────────────

final Provider<OfficeKitClientService> clientServiceProvider =
    Provider<OfficeKitClientService>((ProviderRef<OfficeKitClientService> ref) {
  if (useMockServices) {
    final MockOfficeKitClientService mock = MockOfficeKitClientService();
    mock.startMock();
    ref.onDispose(mock.dispose);
    return mock;
  }
  // TODO(phase2): return RealOfficeKitClientService();
  throw UnimplementedError('Real OfficeKitClientService not yet implemented.');
});

final Provider<ActivityLogService> activityLogServiceProvider =
    Provider<ActivityLogService>((ProviderRef<ActivityLogService> ref) {
  if (useMockServices) return MockActivityLogService();
  // TODO(phase2): return HiveActivityLogService();
  throw UnimplementedError('Real ActivityLogService not yet implemented.');
});

// ─────────────────────────────────────────────────────────────────────────────
// Derived state providers
// ─────────────────────────────────────────────────────────────────────────────

/// Stream of all incoming bridge messages for the dashboard panels.
final StreamProvider<BridgeMessage> incomingMessageStreamProvider =
    StreamProvider<BridgeMessage>((StreamProviderRef<BridgeMessage> ref) {
  final OfficeKitClientService service = ref.watch(clientServiceProvider);
  return service.incomingMessageStream;
});

/// Stream of client connection state for the status badge.
final StreamProvider<ClientConnectionState> clientConnectionStateProvider =
    StreamProvider<ClientConnectionState>(
        (StreamProviderRef<ClientConnectionState> ref) {
  final OfficeKitClientService service = ref.watch(clientServiceProvider);
  return service.connectionStateStream;
});

/// Stream of activity log entries for the Logs panel.
final StreamProvider<ActivityLogEntry> activityLogStreamProvider =
    StreamProvider<ActivityLogEntry>((StreamProviderRef<ActivityLogEntry> ref) {
  final ActivityLogService service = ref.watch(activityLogServiceProvider);
  return service.logStream;
});
