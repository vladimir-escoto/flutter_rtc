import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';

import 'package:flutter_rtc/src/context/bloc/call_enums.dart';

class CallContext {
  final SignalingInterface signaling;

  late final RTCManager _rtcManager;
  late final CallBloc bloc;
  late CallInfo _callInfo;

  bool _disposed = false;

  String get callId => _callInfo.callId;

  CallContext({
    required String callId,
    required String userId,
    required List<Participant> participants,
    required this.signaling,
    required bool isCaller,
    required CallMode mode,
  }) {
    _callInfo = CallInfo(
      callId: callId,
      userId: userId,
      participants: participants,
      callMode: mode,
      isCaller: isCaller,
      createdAt: DateTime.now(),
    );

    _rtcManager = RTCManager(callId: callId, userId: userId, signaling: signaling);

    bloc = CallBloc(callId: callId, rtcManager: _rtcManager);
  }

  /// Called by the initiator to start the call
  Future<void> initiateCall() async {
    await _rtcManager.createOfferFor(_callInfo.participants, _callInfo.callMode);
  }

  /// Called when receiving an incoming call offer
  void handleIncomingOffer(Map<String, dynamic> offer) {
    _rtcManager.handleOffer(offer);
    for (final participant in _callInfo.participants) {
      if (participant.userId == offer['from']) continue;
      //TODO:Implement Group participants negotiation here, send offer to all participants
    }
  }

  /// Routes signaling events to the RTC manager
  void handleSignalingEvent(String from, dynamic event) {
    _rtcManager.handleRemoteEvent(from, event);
  }

  /// Ends the call and notifies all participants
  void end() {
    _rtcManager.close();
  }

  /// Frees all resources
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    bloc.close();
    _rtcManager.dispose();
  }

  /// Rehydrate from previously saved state
  static CallContext fromPersisted({
    required String callId,
    required String userId,
    required SignalingInterface signaling,
    required Map<String, dynamic> savedState,
  }) {
    final participants = ParticipantListExtension.fromJsonList(
      savedState['participants'] as List<dynamic>? ?? [],
    );

    final isCaller = savedState['isCaller'] ?? false;
    final mode = CallMode.values.firstWhere(
      (c) => c.name == savedState['mode'],
      orElse: () => CallMode.audio,
    );

    final context = CallContext(
      callId: callId,
      userId: userId,
      participants: participants,
      signaling: signaling,
      isCaller: isCaller,
      mode: mode,
    );

    // Restore bloc state if needed
    // context.bloc.restore(savedState['blocState']);

    return context;
  }
}
