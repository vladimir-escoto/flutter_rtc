// lib/src/session/call_user_session.dart

import 'package:flutter_rtc/src/context/call_context.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';

class CallUserSession {
  final String userId;
  final SignalingInterface signaling;

  final Map<String, CallContext> _activeCalls = {};

  CallUserSession(this.userId, this.signaling);

  /// Returns all active or on-hold calls for this user.
  List<CallContext> get activeCalls => _activeCalls.values.toList();

  Future<String> startSingleVideCall(String remoteUserId) {
    return startCall([Participant(userId: remoteUserId)], CallMode.video);
  }

  Future<String> startSingleAudioCall(String remoteUserId) {
    return startCall([Participant(userId: remoteUserId)], CallMode.audio);
  }

  /// Starts a new outgoing call and returns the callId.
  Future<String> startCall(List<Participant> participants, CallMode mode) async {
    final callId = _generateCallId();

    final context = CallContext(
      callId: callId,
      userId: userId,
      participants: participants,
      signaling: signaling,
      isCaller: true,
      mode: mode,
    );

    _activeCalls[callId] = context;
    await context.initiateCall();
    return callId;
  }

  /// Handles an incoming offer from signaling.
  void receiveCall(String callId, Map<String, dynamic> offer) {
    if (_activeCalls.containsKey(callId)) return;

    final mode = CallMode.values.firstWhere(
      (m) => m.name == offer['mode'],
      orElse: () => CallMode.audio,
    );
    final participants = ParticipantListExtension.fromJsonList(
      offer['participants'] ?? [],
    );

    final context = CallContext(
      callId: callId,
      userId: userId,
      participants: participants,
      signaling: signaling,
      isCaller: false,
      mode: mode,
    );

    _activeCalls[callId] = context;
    context.handleIncomingOffer(offer);
  }

  /// Handles an incoming signaling event and routes it to the correct call context.
  void handleSignalingEvent(dynamic event) {
    final String callId = event['callId'];
    final String from = event['from'];
    final context = _activeCalls[callId];

    if (context != null) {
      context.handleSignalingEvent(from, event);
    } else {
      // Future enhancement: buffer event or log warning
    }
  }

  /// Ends a specific call
  void endCall(String callId) {
    final context = _activeCalls.remove(callId);
    context?.end();
  }

  /// Restore session from saved state (rehydration)
  void restoreFromState(dynamic state) {
    for (final item in state['calls'] ?? []) {
      final context = CallContext.fromPersisted(
        callId: item['callId'],
        userId: userId,
        signaling: signaling,
        savedState: item,
      );
      _activeCalls[context.callId] = context;
    }
  }

  /// Releases all call contexts
  void dispose() {
    for (final context in _activeCalls.values) {
      context.dispose();
    }
    _activeCalls.clear();
  }

  String _generateCallId() {
    // For now use timestamp; can be replaced with UUID if needed
    return '${DateTime.now().millisecondsSinceEpoch}_$userId';
  }
}
