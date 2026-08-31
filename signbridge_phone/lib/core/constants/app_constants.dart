/// App-wide constants for SignBridge phone app.
library;

/// The port the Office Kit Bridge WebSocket server listens on.
const int kBridgePort = 8765;

/// The maximum number of frames kept in a gesture sequence window (≈1.5 s at 30fps).
const int kGestureWindowFrames = 45;

/// DTW matching confidence threshold (0.0–1.0). Matches below this are discarded.
const double kDtwConfidenceThreshold = 0.72;

/// Minimum hold duration in milliseconds before a DTW match is committed.
const int kSignHoldMs = 300;

/// Number of MediaPipe hand landmarks per hand.
const int kLandmarkCount = 21;

/// The curated sign vocabulary (25 signs for Phase 1).
/// Each string is the canonical display name sent as a caption.
const List<String> kSignVocabulary = [
  'HELLO',
  'GOODBYE',
  'THANK YOU',
  'PLEASE',
  'SORRY',
  'YES',
  'NO',
  'HELP',
  'STOP',
  'MORE',
  'WATER',
  'FOOD',
  'BATHROOM',
  'PAIN',
  'GOOD',
  'BAD',
  'UNDERSTAND',
  'REPEAT',
  'SLOW',
  'FAST',
  'I',
  'YOU',
  'WE',
  'NAME',
  'MEETING',
];

/// Hive box names used throughout the app.
const String kSignLibraryBox = 'sign_library';
const String kActivityLogBox = 'activity_log';

/// Hive type IDs (must be globally unique across both apps if sharing boxes).
const int kSignEntryTypeId = 0;
const int kActivityLogEntryTypeId = 1;
const int kLandmarkPointTypeId = 2;

/// Bridge message type IDs for JSON serialisation.
const String kBridgeMsgCaption = 'caption';
const String kBridgeMsgSpeech = 'speech';
const String kBridgeMsgControl = 'control';
const String kBridgeMsgHeartbeat = 'heartbeat';
