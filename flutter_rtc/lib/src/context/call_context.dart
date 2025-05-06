import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_rtc/src/callkit_manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_rtc/src/context/model/member.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';

class CallContext {
  final callKitManager = CallKitManager();
  final ISignaling signaling;
  final String callId;
  final String userId;
  final bool isCaller;
  late CallInfo _callInfo;

  final _callStatusController = StreamController<
      CallLifeCycleStatus>.broadcast();

  late final RTCManager _rtcManager;
  late final CallBloc _bloc;

  StreamSubscription? _callSub;
  StreamSubscription? _callBlocSub;

  bool _disposed = false;

  bool get isOnHold => _callInfo.callStatus == CallLifeCycleStatus.hold;

  bool get isActive => !isOnHold;

  CallBloc get callBloc => _bloc;

  Stream<CallLifeCycleStatus> get callStatus => _callStatusController.stream;

  CallContext({
    required this.callId,
    required this.userId,
    required this.signaling,
    required this.isCaller,
    required CallMode mode,
    required List<Member> members,
    Map<String, dynamic> params = const {},
  }) {
    var copyMembers = List<Member>.from(members);

    if (!copyMembers.any((p) => p.id == userId)) {
      copyMembers.add(Member(id: userId));
    }

    _callInfo = CallInfo(
      params: params,
      callId: callId,
      userId: userId,
      members: copyMembers,
      callMode: mode,
      isCaller: isCaller,
      createdAt: DateTime.now(),
      callStatus: CallLifeCycleStatus.initial,
    );

    _rtcManager = RTCManager(
        callId: callId,
        userId: userId,
        signaling: signaling);

    _bloc = CallBloc(callInfo: _callInfo, rtcManager: _rtcManager);

    _callSub = _handleCallKitEvents();
    _callBlocSub = _handleBlocState();
  }

  /// Called by the initiator to start the call
  void startOutgoingCall() {
    debugPrint('[CallContext] startOutgoingCall');
    _bloc.add(StartOutgoingCallEvent());
    callKitManager.showOutgoingCall(
      callId: callId,
      callerName: _callInfo.self.displayName,
      body: _callInfo.toJson(),
    );
  }

  Future<void> handleIncomingOffer(CallEventData data) async {
    debugPrint('[CallContext] handleIncomingOffer: $data');
    _rtcManager.handleIncomingOffer(data);
    await callKitManager.showCallkitIncoming(
      callId: data.callId,
      callerName: data.from,
      body: data.toJson(),
    );
  }

  /// Routes signaling events to the RTC manager
  Future<void> handleSignalingEvent(CallEventData data) async {
    debugPrint('[CallContext] handleSignalingEvent: $data');
    switch (data.type) {
      case CallDataEventType.hold:
        _rtcManager.handleIncomingHold(data);
        break;
      case CallDataEventType.resume:
        _rtcManager.handleIncomingResume(data);
        break;
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
      endCall();
        break;
      default:
        debugPrint('[CallContext] Unhandled event type: ${data.type}');
    }
  }

  /// Ends the call and notifies all members
  Future<void> endCall() async {
    debugPrint('[CallContext] end');
    if (_callInfo.callStatus != CallLifeCycleStatus.ended) {
      _bloc.add(HangUpCallEvent());
    }
  }

  Future<void> holdCall() async {
    if (isOnHold) return;
    debugPrint('[CallContext] pause');
    _bloc.add(HoldCallEvent(isOnHold: true));
    callKitManager.holdCall(callId, isOnHold: true);
  }

  Future<void> resumeCall() async {
    debugPrint('[CallContext] resume');
    _bloc.add(HoldCallEvent(isOnHold: false));
    callKitManager.holdCall(callId, isOnHold: false);
  }

  Future<void> declineCall() async {
    debugPrint('[CallContext] decline');
    if (_callInfo.callStatus != CallLifeCycleStatus.declined) {
      _bloc.add(DeclineIncomingCallEvent());
    }
  }

  Future<void> setConnectionStatus(bool connected, dynamic error) async {
    debugPrint('[CallContext] setConnectionStatus: connected=$connected, error=$error');
    //Todo: Manage connection status
  }

  void setAppLifecycleState(AppLifecycleState status) {
    debugPrint('[CallContext] setAppLifecycleState: $status');
    _bloc.add(AppLifecycleStateEvent(status: status));
  }

  StreamSubscription _handleBlocState() => _bloc.stream.listen((state) {
    debugPrint('[CallContext] _handleBlocState: $state');

    if (_callInfo.self.micEnabled != state.self.micEnabled) {
      callKitManager.muteCall(callId, state.self.micEnabled);
    }

    if (_callInfo.callStatus != state.callInfo.callStatus) {
      _callStatusController.add(state.lifecycleStatus);

      if (state.isConnected) {
        callKitManager.setCallConnected(callId);
      }
    }
  });

  StreamSubscription _handleCallKitEvents() =>
      callKitManager.eventsFor(callId).listen((CallKitEventData data) {
        debugPrint('[CallContext] _handleCallKitEvents: $data');
        switch (data.event) {
          case CallKitEvent.accept:
            var callData = CallEventData.fromJson(data.body);
            _bloc.add(AcceptIncomingCallEvent(data: callData));
            break;
          case CallKitEvent.decline:
            declineCall();
            break;
          case CallKitEvent.ended:
          case CallKitEvent.timeout:
          endCall();
          case CallKitEvent.toggleHold:
            debugPrint('[CallContext] toggleHold ${data.body}');
            _bloc.add(HoldCallEvent(isOnHold: data.body["isOnHold"] as bool));
            break;
          case CallKitEvent.toggleMute:
            debugPrint('[CallContext] toggleMute ${data.body}');
            _bloc.add(ToggleLocalControlEvent(
              control: LocalControlType.mic,
                value: data.body["isMuted"] as bool,
              ),
            );
            break;
          default:
            debugPrint('[CallContext] Unhandled event type: ${data.event}');
            break;
        }
      });

  void simulateCall() {
    debugPrint('[CallContext] startOutgoingCall');
    _bloc.add(CallLifecycleEvent(CallEvent(CallLifeCycleStatus.active)));
  }

  /// Frees all resources
  void dispose() {
    if (_disposed) return;
    endCall();
    _disposed = true;
    _callBlocSub?.cancel();
    _callSub?.cancel();
    _bloc.close();
    _rtcManager.dispose();
    debugPrint('[CallContext] dispose');
  }

}
