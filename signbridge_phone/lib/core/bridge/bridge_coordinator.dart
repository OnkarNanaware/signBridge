import 'dart:async';
import 'package:signbridge_phone/core/models/bridge_message.dart';
import 'package:signbridge_phone/core/models/dtw_match.dart';
import 'package:signbridge_phone/services/asr_service.dart';
import 'package:signbridge_phone/services/dtw_matcher_service.dart';
import 'package:signbridge_phone/services/office_kit_bridge_service.dart';

/// Coordinates automatic publishing of live AI pipeline outputs over the
/// Office Kit WebSocket Bridge.
///
/// Whenever a sign is recognised by [DtwMatcherService] or speech is
/// transcribed by [AsrService], this coordinator packages it into a
/// [BridgeMessage] and broadcasts it to connected dashboard clients.
class BridgeCoordinator {
  BridgeCoordinator({
    required DtwMatcherService dtwMatcherService,
    required AsrService asrService,
    required OfficeKitBridgeService bridgeService,
  })  : _dtwMatcherService = dtwMatcherService,
        _asrService = asrService,
        _bridgeService = bridgeService {
    _startListening();
  }

  final DtwMatcherService _dtwMatcherService;
  final AsrService _asrService;
  final OfficeKitBridgeService _bridgeService;

  StreamSubscription<DtwMatch>? _dtwSub;
  StreamSubscription<String>? _asrSub;

  void _startListening() {
    // 1. Publish sign matches to bridge
    _dtwSub = _dtwMatcherService.matchStream.listen((DtwMatch match) {
      _bridgeService.sendMessage(
        BridgeMessage.signCaption(
          match.signName,
          confidence: match.confidence,
        ),
      );
    });

    // 2. Publish speech transcripts to bridge
    _asrSub = _asrService.transcriptStream.listen((String transcript) {
      _bridgeService.sendMessage(
        BridgeMessage.speechCaption(
          transcript,
          confidence: 1.0,
        ),
      );
    });
  }

  /// Disposes subscriptions.
  void dispose() {
    _dtwSub?.cancel();
    _asrSub?.cancel();
  }
}
