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

  final _callStatusController = StreamController<CallLifeCycleStatus>.broadcast();

  late final RTCManager _rtcManager;
  late final CallBloc _bloc;

  StreamSubscription? _callSub;
  StreamSubscription? _callBlocSub;

  bool _disposed = false;

  bool get isOnHold => _callInfo.callStatus == CallLifeCycleStatus.hold;

  bool get isActive => !isOnHold;

  CallBloc get callBloc => _bloc;

  CallLifeCycleStatus get status => _callInfo.callStatus;

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
    final isVideoCall = mode == CallMode.video;
    var copyMembers = List<Member>.from(members);

    if (!copyMembers.any((p) => p.id == userId)) {
      copyMembers.add(Member(id: userId,
          cameraEnabled: isVideoCall,
          speakerEnable: isVideoCall,
          micEnabled: true));
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

    _rtcManager = RTCManager(callId: callId, userId: userId, signaling: signaling);

    _bloc = CallBloc(callInfo: _callInfo, rtcManager: _rtcManager);

    _callSub = _handleCallKitEvents();
    _callBlocSub = _handleBlocState();
  }

  /// Called by the initiator to start the call
  void startOutgoingCall() {
    debugPrint('[CallContext][callId: $callId] startOutgoingCall');
    _bloc.add(StartOutgoingCallEvent());
    // callKitManager.showOutgoingCall(
    //   callId: callId,
    //   callerName: _callInfo.self.displayNameOrId,
    //   body: _callInfo.toJson(),
    // );
  }

  Future<void> handleIncomingOffer(CallEventData data) async {
    debugPrint('[CallContext][callId: $callId] handleIncomingOffer: $data');
    _rtcManager.handleIncomingOffer(data);
    await callKitManager.showCallkitIncoming(
      callId: data.callId,
      callerName: data.from,
      body: data.toJson(),
    );
  }

  /// Routes signaling events to the RTC manager
  Future<void> handleSignalingEvent(CallEventData data) async {
    debugPrint('[CallContext][callId: $callId] handleSignalingEvent: $data');
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
        debugPrint('[CallContext][callId: $callId] Unhandled event type: ${data
            .type}');
    }
  }

  /// Ends the call and notifies all members
  Future<void> endCall() async {
    if (_callInfo.callStatus != CallLifeCycleStatus.ended) {
      debugPrint('[CallContext][callId: $callId] endCall');
      _bloc.add(HangUpCallEvent());
    }
  }

  Future<void> holdCall() async {
    if (isOnHold) return;
    debugPrint('[CallContext][callId: $callId] holdCall');
    _bloc.add(HoldCallEvent(isOnHold: true));
    callKitManager.holdCall(callId, isOnHold: true);
  }

  Future<void> resumeCall() async {
    debugPrint('[CallContext][callId: $callId] resumeCall');
    _bloc.add(HoldCallEvent(isOnHold: false));
    callKitManager.holdCall(callId, isOnHold: false);
  }

  Future<void> declineCall() async {
    if (_callInfo.callStatus != CallLifeCycleStatus.declined) {
      debugPrint('[CallContext][callId: $callId] declineCall');
      _bloc.add(DeclineIncomingCallEvent(""));
    }
  }

  Future<void> setConnectionStatus(bool connected, dynamic error) async {
    debugPrint(
        '[CallContext][callId: $callId] setConnectionStatus: connected=$connected, error=$error');
  }

  void setAppLifecycleState(AppLifecycleState status) {
    debugPrint(
        '[CallContext][callId: $callId] setAppLifecycleState: ${status.name}');
    _bloc.add(AppLifecycleStateEvent(status: status));
  }

  StreamSubscription _handleBlocState() => _bloc.stream.listen((state) {
    debugPrint('[CallContext][callId: $callId] _handleBlocState: $state');

    if (_callInfo.self.micEnabled != state.self.micEnabled) {
      callKitManager.muteCall(callId, state.self.micEnabled);
    }

    if (_callInfo.callStatus != state.callInfo.callStatus) {
      _callStatusController.add(state.lifecycleStatus);

      if (state.isConnected) {
        callKitManager.setCallConnected(callId);
      }
    }
    _callInfo = state.callInfo.copyWith();
  });

  StreamSubscription _handleCallKitEvents() =>
      callKitManager.eventsFor(callId).listen((CallKitEventData data) {
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
            break;
          case CallKitEvent.toggleHold:
            var isOnHold = data.body["isOnHold"] as bool;
            _bloc.add(HoldCallEvent(isOnHold: isOnHold));
          case CallKitEvent.toggleMute:
            var isMute = data.body["isMuted"] as bool;
            _bloc.add(ToggleLocalControlEvent(
              control: LocalControlType.mic, value: isMute,
            ));
            break;
          default:
            debugPrint(
                '[CallContext][callKit][callId: $callId] Unhandled event: ${data.event}');
            break;
        }
      });

  void simulateCall(CallLifeCycleStatus state) {
    //Used for testing purposes
    debugPrint('[CallContext] [callId: $callId] simulateCall');
    _bloc.add(CallLifecycleEvent(CallEvent(state)));
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
    debugPrint('[CallContext][callId: $callId] dispose');
  }
}
