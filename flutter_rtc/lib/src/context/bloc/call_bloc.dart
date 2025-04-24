import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/src/context/model/call_info.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_events.dart';
import 'package:flutter_rtc/src/context/bloc/call_state.dart';
import 'package:flutter_rtc/src/context/bloc/call_enums.dart';

class CallBloc extends Bloc<CallBlocEvent, CallBlocState> {
  final RTCManager rtcManager;

  CallBloc({required CallInfo callInfo, required this.rtcManager})
    : super(CallBlocState.fromCallInfo(callInfo)) {
    on<CallLifecycleEvent>(_handleLifecycleEvent);
    on<ToggleLocalControlEvent>(_handleToggleLocalControlEvent);
    on<RemoteControlEvent>(_handleRemoteControlEvent);
    on<UIEvent>(_handleUIEvent);
    on<CallErrorEvent>(_handleErrorEvent);
    on<AcceptIncomingCallEvent>(_handleAcceptIncomingCallEvent);
    on<DeclineIncomingCallEvent>(_handleDeclineIncomingCallEvent);
    on<StartOutgoingCallEvent>(_handleOutgoingCallEvent);
    on<HangUpCallEvent>(_handleHangUpCallEvent);
    on<RedialCallEvent>(_handleRedialCallEvent);
    on<SwitchCameraEvent>(_handleSwitchCameraEvent);
    on<AppLifecycleStateEvent>(_handleAppLifecycleStateEvent);

    /// **🔹 Listens to events from CallManager**
    rtcManager.callEvents.listen((event) => add(CallLifecycleEvent(status: event)));
  }

  /// **🔹 Handling of call lifecycle events**
  void _handleLifecycleEvent(CallLifecycleEvent event, Emitter<CallBlocState> emit) {}

  /// **🔹 Handles the change of states of local controls**
  void _handleToggleLocalControlEvent(
    ToggleLocalControlEvent event,
    Emitter<CallBlocState> emit,
  ) {
    switch (event.control) {
      case LocalControlType.mic:
        rtcManager.toggleMicrophone(!state.localMicOn);
        emit(state.copySelf(state.self.copyWith(micEnabled: !state.localMicOn)));
        break;
      case LocalControlType.camera:
        rtcManager.toggleCamera(!state.localCameraOn);
        emit(state.copySelf(state.self.copyWith(cameraEnabled: !state.localCameraOn)));
        break;
      case LocalControlType.speaker:
        rtcManager.toggleSpeaker(!state.localSpeakerOn);
        emit(state.copySelf(state.self.copyWith(speakerEnable: !state.localSpeakerOn)));
        break;
      case LocalControlType.screenShare:
        var enable = !state.localScreenShareOn;
        rtcManager.toggleScreenSharing(enable);
        emit(state.copySelf(state.self.copyWith(screenShareEnabled: enable)));
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
  void _handleRemoteControlEvent(RemoteControlEvent event, Emitter<CallBlocState> emit) {}

  /// Handles UI events such as minimizing, maximizing, dragging, and timer updates.
  void _handleUIEvent(UIEvent event, Emitter<CallBlocState> emit) {}

  /// Handles error events by updating the error message.
  void _handleErrorEvent(CallErrorEvent event, Emitter<CallBlocState> emit) {
    emit(state.copyWith(errorMessage: event.errorMessage));
  }

  /// New handler: Accept an incoming call.
  void _handleAcceptIncomingCallEvent(
    AcceptIncomingCallEvent event,
    Emitter<CallBlocState> emit,
  ) {}

  /// New handler: Decline an incoming call.
  Future<void> _handleDeclineIncomingCallEvent(
    DeclineIncomingCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {}

  /// **🔹 Handles the start of an outgoing call**
  Future<void> _handleOutgoingCallEvent(
    StartOutgoingCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {}

  /// **🔹 Handles the end of a call**
  Future<void> _handleHangUpCallEvent(
    HangUpCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {}

  /// **🔹 Handles the retry of a call**
  Future<void> _handleRedialCallEvent(
    RedialCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {}

  /// **🔹 Handles the camera switch**
  Future<void> _handleSwitchCameraEvent(
    SwitchCameraEvent event,
    Emitter<CallBlocState> emit,
  ) async {}

  FutureOr<void> _handleAppLifecycleStateEvent(
    AppLifecycleStateEvent event,
    Emitter<CallBlocState> emit,
  ) {}
}
