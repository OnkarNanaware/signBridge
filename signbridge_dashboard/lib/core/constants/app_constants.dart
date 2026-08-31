/// Dashboard app constants — shared with the phone app conceptually,
/// but kept separate to allow independent deployment.
library;

/// Default WebSocket server host (phone's IP on the local network).
/// The user sets the actual IP in the Session Controls panel.
const String kDefaultBridgeHost = '192.168.1.100';

/// The port the phone's Office Kit Bridge WebSocket server listens on.
const int kBridgePort = 8765;

/// Hive box names used by the dashboard.
const String kActivityLogBox = 'dashboard_activity_log';

/// Hive type IDs (must match phone side for schema compatibility).
const int kActivityLogEntryTypeId = 1;
const int kEventTypeTypeId = 3;

/// Maximum number of log entries shown in the UI before pagination.
const int kLogPageSize = 50;

/// Maximum number of caption lines kept in the live caption panel.
const int kMaxCaptionLines = 20;
