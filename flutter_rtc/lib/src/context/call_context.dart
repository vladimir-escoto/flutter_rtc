import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/callkit_manager.dart';
import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_rtc/src/coordinator/signaling_interface.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
import 'package:flutter_rtc/src/context/bloc/call_events.dart';
import 'package:flutter_rtc/src/coordinator/signaling_event.dart';

class CallContext {
  final callKitManager = CallKitManager();
  final SignalingInterface signaling;
  final String callId;
  final String userId;
  final bool isCaller;

  late final RTCManager _rtcManager;
  late final CallBloc _bloc;

  bool _disposed = false;
  bool _connected = false;

  StreamSubscription? _callSub;
  StreamSubscription? _callBlocSub;

  CallContext({
    required this.callId,
    required this.userId,
    required this.signaling,
    required this.isCaller,
    required CallMode mode,
    required List<Participant> participants,
    Map<String, dynamic> params = const {},
  }) {
    if (participants.any((p) => p.userId == userId)) {
      participants.add(Participant(userId: userId));
    }

    final callInfo = CallInfo(
      params: params,
      callId: callId,
      userId: userId,
      participants: participants,
      callMode: mode,
      isCaller: isCaller,
      createdAt: DateTime.now(),
    );

    _rtcManager = RTCManager(callId: callId, userId: userId, signaling: signaling);

    _bloc = CallBloc(callInfo: callInfo, rtcManager: _rtcManager);

    _callSub = _handleCallKitEvents();
    _callBlocSub = _handleBlocState();
  }

  /// Called by the initiator to start the call
  void startOutgoingCall() {
    _bloc.add(StartOutgoingCallEvent());
  }

  Future<void> handleIncomingOffer(CallEventData data) async {
    _rtcManager.handleIncomingOffer(data);
    await callKitManager.showCallkitIncoming(
      callId: data.callId,
      callerName: data.from,
      body: data.toJson(),
    );
  }

  /// Routes signaling events to the RTC manager
  Future<void> handleSignalingEvent(CallEventData data) async {
    switch (data.type) {
      case CallDataEventType.offer:
        await handleIncomingOffer(data);
        break;
      case CallDataEventType.answer:
        _rtcManager.handleIncomingAnswer(data);
        break;
      case CallDataEventType.iceCandidate:
        _rtcManager.handleIncomingCandidate(data);
        break;
      case CallDataEventType.callDeclined:
      case CallDataEventType.callEnded:
        end();
        // _rtcManager.removeParticipant(data.from);
        break;
      default:
        debugPrint('[CallContext] Unhandled event type: ${data.type}');
    }
  }

  /// Ends the call and notifies all participants
  void end() {
    _rtcManager.close();
    callKitManager.endCall(callId);
  }

  void pause() {
    _rtcManager.pause();
    _bloc.add(CallLifecycleEvent(status: CallEvent(type: CallLifecycleStatus.paused)));
  }

  void resume() {
    _rtcManager.resume();
    _bloc.add(CallLifecycleEvent(status: CallEvent(type: CallLifecycleStatus.resumed)));
  }

  Future<void> setConnectionStatus(bool connected, dynamic error) async {
    //Todo: Manage connection status
  }

  void setAppLifecycleState(AppLifecycleState status) {
    _bloc.add(AppLifecycleStateEvent(status: status));
  }

  StreamSubscription _handleBlocState() => _bloc.stream.listen((state) {
    if (state.lifecycleStatus == CallLifecycleStatus.calling) {
      callKitManager.showOutgoingCall(
        callId: callId,
        callerName: state.self.displayName,
        body: state.callInfo.toJson(),
      );
    } else if (state.lifecycleStatus == CallLifecycleStatus.ended) {
      callKitManager.endCall(callId);
    } else if (state.lifecycleStatus == CallLifecycleStatus.connected && !_connected) {
      callKitManager.setCallConnected(callId);
      _connected = true;
    }

    callKitManager.muteCall(callId, state.self);
  });

  StreamSubscription _handleCallKitEvents() =>
      callKitManager.eventsFor(callId).listen((CallKitEventData data) {
        switch (data.event) {
          case CallKitEvent.accept:
            var callData = CallEventData.fromJson(data.body);
            _bloc.add(AcceptIncomingCallEvent(data: callData));
            break;
          case CallKitEvent.decline:
            _bloc.add(DeclineIncomingCallEvent());
            break;
          case CallKitEvent.ended:
            _bloc.add(DeclineIncomingCallEvent());
            break;
          case CallKitEvent.timeout:
            break;
          case CallKitEvent.actionCallback:
            break;
          case CallKitEvent.toggleHold:
            break;
          case CallKitEvent.toggleMute:
            _bloc.add(ToggleLocalControlEvent(control: LocalControlType.mic));
            break;
          case CallKitEvent.toggleDmtf:
            break;
          case CallKitEvent.toggleGroup:
            break;
          case CallKitEvent.toggleAudioSession:
            break;
          case CallKitEvent.actionCustom:
            break;
          default:
            debugPrint('[CallContext] Unhandled event type: ${data.event}');
            break;
        }
      });

  /// Frees all resources
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _callBlocSub?.cancel();
    _callSub?.cancel();
    _bloc.close();
    _rtcManager.dispose();
  }
}
