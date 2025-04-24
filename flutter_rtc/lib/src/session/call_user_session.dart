// lib/src/session/call_user_session.dart

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_rtc/src/context/call_context.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_rtc/src/coordinator/signaling_event.dart';

class CallUserSession {
  final String userId;
  final Map<String, dynamic> params;
  final SignalingInterface signaling;

  final Map<String, CallContext> _activeCalls = {};

  CallUserSession(this.userId, this.signaling, this.params);

  /// Returns all active or on-hold calls for this user.
  List<CallContext> get activeCalls {
    debugPrint('[CallUserSession] get activeCalls');
    return _activeCalls.values.toList();
  }

  bool containsCall(String callId) => _activeCalls.containsKey(callId);

  Future<String> startSingleVideCall(String remoteUserId) {
    debugPrint('[CallUserSession] startSingleVideCall $remoteUserId');
    return startCall([Participant(userId: remoteUserId)], CallMode.video);
  }

  Future<String> startSingleAudioCall(String remoteUserId) {
    debugPrint('[CallUserSession] startSingleAudioCall $remoteUserId');
    return startCall([Participant(userId: remoteUserId)], CallMode.audio);
  }

  /// Starts a new outgoing call and returns the callId.
  Future<String> startCall(List<Participant> participants, CallMode mode) async {
    debugPrint(
      '[CallUserSession] startCall participants: ${participants.map((e) => e.userId)} , mode: $mode',
    );

    final context = makeCall(participants, mode);
    context.startOutgoingCall();
    return context.callId;
  }

  CallContext makeCall(List<Participant> participants, CallMode mode) {
    final callId = _generateCallId();
    debugPrint('[CallUserSession] makeCall, callId: $callId');

    final context = CallContext(
      params: params,
      callId: callId,
      userId: userId,
      participants: participants,
      signaling: signaling,
      isCaller: true,
      mode: mode,
    );

    _activeCalls[callId] = context;
    return context;
  }

  /// Handles an incoming signaling event and routes it to the correct call context.
  Future<void> handleSignalingCallEvent(CallEventData data) async {
    debugPrint('[CallUserSession] handleSignalingCallEvent $data');
    final context = _activeCalls[data.callId];

    if (context != null) {
      await context.handleSignalingEvent(data);
    } else {
      // Future enhancement: buffer event or log warning
    }
  }

  /// Ends a specific call
  void endCall(String callId) {
    debugPrint('[CallUserSession] endCall $callId');
    final context = _activeCalls.remove(callId);
    context?.end();
  }

  /// Releases all call contexts
  void dispose() {
    debugPrint('[CallUserSession] dispose');
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
    debugPrint('[CallUserSession] setConnectionStatus connected:$connected');
    for (final context in _activeCalls.values) {
      context.setConnectionStatus(connected, error);
    }
  }

  void setAppLifecycleState(AppLifecycleState status) {
    debugPrint('[CallUserSession] setAppLifecycleState $status');
    for (final context in _activeCalls.values) {
      context.setAppLifecycleState(status);
    }
  }

  void receiveIncomingCall(CallEventData data) {
    if (!_activeCalls.containsKey(data.callId)) {
      debugPrint('[CallUserSession] receiveIncomingCall ${data.callId}');
      var offer = data.toOffer();
      var context = makeCall(offer.participants, offer.mode);
      context.handleIncomingOffer(data);
    }
  }
}
