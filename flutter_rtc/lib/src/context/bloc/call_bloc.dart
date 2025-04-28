import 'dart:async';
import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_rtc/src/context/model/member.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

part 'call_enums.dart';

part 'call_events.dart';
part 'call_state.dart';

typedef CallEmitter = Emitter<CallBlocState>;

class CallBloc extends Bloc<CallBlocEvent, CallBlocState> {

  final RTCManager rtcManager;

  CallBloc({required CallInfo callInfo, required this.rtcManager})
    : super(CallBlocState.fromCallInfo(callInfo)) {
    on<CallLifecycleEvent>(_onLifecycleEvent);
    on<PeerConnectionEvent>(_onPeerConnectionEvent);
    on<ToggleLocalControlEvent>(_onToggleControlEvent);
    on<RemoteControlEvent>(_onRemoteControlEvent);
    on<UIEvent>(_onUIEvent);
    on<CallErrorEvent>(_onErrorEvent);
    on<AcceptIncomingCallEvent>(_onAcceptIncomingCallEvent);
    on<DeclineIncomingCallEvent>(_onDeclineIncomingCallEvent);
    on<StartOutgoingCallEvent>(_onOutgoingCallEvent);
    on<HangUpCallEvent>(_onHangUpCallEvent);
    on<RedialCallEvent>(_onRedialCallEvent);
    on<SwitchCameraEvent>(_onSwitchCameraEvent);
    on<HoldCallEvent>(_onHoldCallEvent);
    on<AppLifecycleStateEvent>(_onAppLifecycleStateEvent);

    /// **🔹 Listens to events from CallManager**
    rtcManager.callEvents.listen((event) => add(CallLifecycleEvent(event)));
    rtcManager.peerEvents.listen((event) => add(PeerConnectionEvent(event)));
  }

  Future<void> _onPeerConnectionEvent(PeerConnectionEvent event,
      CallEmitter emit) async {
    final type = event.status.type;
    final member = state.getMembersById(event.status.memberId);
    final cpMember = member.copyWith(status: type);

    emit(state.copyMember(cpMember));

    if (type == ConnectionStatus.connected && !state.isConnected) {
      add(CallLifecycleEvent.fromStatus(CallLifeCycleStatus.active));
    }
  }

  /// **🔹 Handling of call lifecycle events**
  void _onLifecycleEvent(CallLifecycleEvent event, CallEmitter emit) {
    final type = event.status.type;

    switch (type) {
      case CallLifeCycleStatus.initial:
        emit(CallBlocState.fromCallInfo(state.callInfo));
        break;
      default:
        final newState = state.copyWithStream(rtcManager.mediaStreams)
            .copyWithCallInfo(state.callInfo.copyWith(callStatus: type));
        emit(newState);
        break;
    }
  }

  /// **🔹 Handles the change of states of local controls**
  void _onToggleControlEvent(
    ToggleLocalControlEvent event,
      CallEmitter emit,
  ) {
    switch (event.control) {
      case LocalControlType.mic:
        if (event.value == state.localMicOn) return;
        rtcManager.toggleMicrophone(!state.localMicOn);
        emit(state.toggleControl(micEnabled: !state.localMicOn));
        break;
      case LocalControlType.camera:
        rtcManager.toggleCamera(!state.localCameraOn);
        emit(state.toggleControl(cameraEnabled: !state.localCameraOn));
        break;
      case LocalControlType.speaker:
        rtcManager.toggleSpeaker(!state.localSpeakerOn);
        emit(state.toggleControl(speakerEnable: !state.localSpeakerOn));
        break;
      case LocalControlType.screenShare:
        var enable = !state.localScreenShareOn;
        rtcManager.toggleScreenSharing(enable);
        emit(state.toggleControl(screenShareEnabled: enable));
        break;
      case LocalControlType.callMode:
        var isVide = state.callMode == CallMode.video;
        rtcManager.toggleCamera(!isVide);
        var callMode = isVide ? CallMode.audio : CallMode.video;
        emit(state.copyWithCallInfo(state.callInfo.copyWith(callMode: callMode)));
        break;
    }
  }

  /// Handles remote control events received via the data channel.
  void _onRemoteControlEvent(RemoteControlEvent event, CallEmitter emit) {
    final enabled = event.value;
    switch (event.control) {
      case RemoteControlType.mic:
        emit(state.setRemoteControl(event.memberId, micEnabled: enabled));
        break;
      case RemoteControlType.camera:
        emit(state.setRemoteControl(event.memberId, cameraEnabled: enabled));
        break;
      case RemoteControlType.screenShare:
        emit(state.setRemoteControl(event.memberId, screenShareEnabled: enabled));
        break;
    }
  }

  /// Handles UI events such as minimizing, maximizing, dragging, and timer updates.
  void _onUIEvent(UIEvent event, CallEmitter emit) {
    switch (event.event) {
      case UIEventType.changeOverlay:
        if (event.value is OverlayStatus) {
          emit(state.copyWith(overlayStatus: event.value));
        }
        break;
      case UIEventType.dragged:
        if (event.value is Offset) {
          emit(state.copyWith(uiPosition: event.value));
        }
        break;
      case UIEventType.callTimerUpdated:
        if (event.value is Duration) {
          emit(state.copyWith(callDuration: event.value));
        }
        break;
    }
  }

  /// Handles error events by updating the error message.
  void _onErrorEvent(CallErrorEvent event, CallEmitter emit) {
    emit(state.copyWith(errorMessage: event.errorMessage));
  }

  /// New handler: Accept an incoming call.
  void _onAcceptIncomingCallEvent(
    AcceptIncomingCallEvent event,
      CallEmitter emit,) async =>
      await rtcManager.answerIncomingCall(event.data);

  /// New handler: Decline an incoming call.
  Future<void> _onDeclineIncomingCallEvent(
    DeclineIncomingCallEvent event,
      CallEmitter emit,
  ) async => await rtcManager.handleDeclineIncomingCall(event.reason);

  /// **🔹 Handles the start of an outgoing call**
  Future<void> _onOutgoingCallEvent(
    StartOutgoingCallEvent event,
      CallEmitter emit,
  ) async => await rtcManager.startOutgoingCall(
    state.callInfo.members,
    state.callInfo.callMode,
  );

  /// **🔹 Handles the end of a call**
  Future<void> _onHangUpCallEvent(
    HangUpCallEvent event,
      CallEmitter emit,
  ) async => await rtcManager.handleEndCall();

  Future<void> _onHoldCallEvent(HoldCallEvent event,
      CallEmitter emit,) async {
    if (event.isOnHold && !state.isOnHold) {
      await rtcManager.holdCall();
    } else if (!event.isOnHold && state.isOnHold) {
      await rtcManager.resumeCall();
    }
  }

  /// **🔹 Handles the retry of a call**
  Future<void> _onRedialCallEvent(
    RedialCallEvent event,
      CallEmitter emit,
  ) async {}

  /// **🔹 Handles the camera switch**
  Future<void> _onSwitchCameraEvent(
    SwitchCameraEvent event,
      CallEmitter emit,
  ) async => await rtcManager.switchCamera();

  FutureOr<void> _onAppLifecycleStateEvent(
    AppLifecycleStateEvent event,
      CallEmitter emit,
  ) async {}

}

