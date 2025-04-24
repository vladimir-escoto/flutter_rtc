import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_rtc/src/context/bloc/call_events.dart';
import 'package:flutter_rtc/src/coordinator/signaling_event.dart';

class CallContext {
  final SignalingInterface signaling;
  final String callId;
  final String userId;
  final bool isCaller;

  late final RTCManager _rtcManager;
  late final CallBloc bloc;

  bool _disposed = false;

  CallContext({
    required this.callId,
    required this.userId,
    required this.signaling,
    required this.isCaller,
    required CallMode mode,
    required List<Participant> participants,
  }) {
    if (participants.any((p) => p.userId == userId)) {
      participants.add(Participant(userId: userId));
    }

    final callInfo = CallInfo(
      callId: callId,
      userId: userId,
      participants: participants,
      callMode: mode,
      isCaller: isCaller,
      createdAt: DateTime.now(),
    );

    _rtcManager = RTCManager(callId: callId, userId: userId, signaling: signaling);

    bloc = CallBloc(callInfo: callInfo, rtcManager: _rtcManager);
  }

  /// Called by the initiator to start the call
  void initiateCall() => bloc.add(StartOutgoingCallEvent());

  /// Routes signaling events to the RTC manager
  void handleSignalingEvent(CallEventData data) {
    switch (data.type) {
      case CallDataEventType.offer:
        _rtcManager.handleIncomingOffer(data);
        break;
      case CallDataEventType.answer:
        _rtcManager.handleIncomingAnswer(data);
        break;
      case CallDataEventType.iceCandidate:
        _rtcManager.handleIncomingCandidate(data);
        break;
      case CallDataEventType.callDeclined:
      case CallDataEventType.callEnded:
        _rtcManager.removeParticipant(data.from);
        break;
      default:
        debugPrint('[CallContext] Unhandled event type: ${data.type}');
    }
  }

  /// Ends the call and notifies all participants
  void end() {
    _rtcManager.close();
  }

  void pause() {
    _rtcManager.pause();
    bloc.add(CallLifecycleEvent(status: CallEvent(type: CallLifecycleStatus.paused)));
  }

  void resume() {
    _rtcManager.resume();
    bloc.add(CallLifecycleEvent(status: CallEvent(type: CallLifecycleStatus.resumed)));
  }

  Future<void> setConnectionStatus(bool connected, dynamic error) async {
    //Todo: Manage connection status
  }

  void setAppLifecycleState(AppLifecycleState status) {
    bloc.add(AppLifecycleStateEvent(status: status));
  }

  /// Frees all resources
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    bloc.close();
    _rtcManager.dispose();
  }
}
