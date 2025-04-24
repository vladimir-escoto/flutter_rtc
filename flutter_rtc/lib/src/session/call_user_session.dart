// lib/src/session/call_user_session.dart

import 'dart:ui';

import 'package:flutter_rtc/src/context/call_context.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_rtc/src/coordinator/signaling_event.dart';

class CallUserSession {
  final String userId;
  final SignalingInterface signaling;

  final Map<String, CallContext> _activeCalls = {};

  CallUserSession(this.userId, this.signaling);

  /// Returns all active or on-hold calls for this user.
  List<CallContext> get activeCalls => _activeCalls.values.toList();

  bool containsCall(String callId) => _activeCalls.containsKey(callId);

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
    context.initiateCall();
    return callId;
  }

  /// Handles an incoming signaling event and routes it to the correct call context.
  void handleSignalingEvent(CallEventData data) {
    final context = _activeCalls[data.callId];

    if (context != null) {
      context.handleSignalingEvent(data);
    } else {
      // Future enhancement: buffer event or log warning
    }
  }

  /// Ends a specific call
  void endCall(String callId) {
    final context = _activeCalls.remove(callId);
    context?.end();
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

  Future<void> setConnectionStatus(bool connected, dynamic error) async {
    for (final context in _activeCalls.values) {
      context.setConnectionStatus(connected, error);
    }
  }

  void setAppLifecycleState(AppLifecycleState status) {
    for (final context in _activeCalls.values) {
      context.setAppLifecycleState(status);
    }
  }
}
