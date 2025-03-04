import 'dart:async';
import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../call_manager.dart';
import 'call_enums.dart';
import 'call_events.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallBlocEvent, CallBlocState> {
  final CallManager callManager;

  CallBloc({required this.callManager}) : super(initialCallBlocState) {
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

    /// **🔹 Listens to events from CallManager**
    callManager.callEvents.listen((event) => add(CallLifecycleEvent(status: event)));
  }

  /// **🔹 Handling of call lifecycle events**
  void _handleLifecycleEvent(CallLifecycleEvent event, Emitter<CallBlocState> emit) {
    if (event.status == CallLifecycleStatus.initial) {
      emit(initialCallBlocState);
    } else {
      emit(
        state.copyWith(
          lifecycleStatus: event.status,
          localStream: callManager.localStream,
          remoteStream: callManager.remoteStream,
        ),
      );
    }
  }

  /// **🔹 Handles the change of states of local controls**
  void _handleToggleLocalControlEvent(
    ToggleLocalControlEvent event,
    Emitter<CallBlocState> emit,
  ) {
    switch (event.control) {
      case LocalControlType.mic:
        emit(state.copyWith(localMicOn: !state.localMicOn));
        break;
      case LocalControlType.camera:
        emit(state.copyWith(localCameraOn: !state.localCameraOn));
        break;
      case LocalControlType.speaker:
        emit(state.copyWith(localSpeakerOn: !state.localSpeakerOn));
        break;
      case LocalControlType.screenshare:
        emit(state.copyWith(localScreenShareOn: !state.localScreenShareOn));
        break;
      case LocalControlType.callMode:
        emit(
          state.copyWith(
            callMode: state.callMode == CallMode.video ? CallMode.audio : CallMode.video,
          ),
        );
        break;
    }
  }

  /// Handles remote control events received via the data channel.
  void _handleRemoteControlEvent(RemoteControlEvent event, Emitter<CallBlocState> emit) {
    switch (event.control) {
      case RemoteControlType.mic:
        emit(state.copyWith(remoteMicOn: event.value));
        break;
      case RemoteControlType.camera:
        emit(state.copyWith(remoteCameraOn: event.value));
        break;
      case RemoteControlType.screenshare:
        emit(state.copyWith(remoteScreenShareOn: event.value));
        break;
    }
  }

  /// Handles UI events such as minimizing, maximizing, dragging, and timer updates.
  void _handleUIEvent(UIEvent event, Emitter<CallBlocState> emit) {
    switch (event.event) {
      case UIEventType.minimized:
        emit(state.copyWith(uiMinimized: true));
        break;
      case UIEventType.maximized:
        emit(state.copyWith(uiMinimized: false));
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
      case UIEventType.callStatusChanged:
        // Additional UI updates if needed.
        break;
    }
  }

  /// Handles error events by updating the error message.
  void _handleErrorEvent(CallErrorEvent event, Emitter<CallBlocState> emit) {
    emit(state.copyWith(errorMessage: event.errorMessage));
  }

  /// New handler: Accept an incoming call.
  void _handleAcceptIncomingCallEvent(
    AcceptIncomingCallEvent event,
    Emitter<CallBlocState> emit,
  ) {
    callManager.answerIncomingCall();
    emit(
      state.copyWith(
        lifecycleStatus: CallLifecycleStatus.connected,
        callDuration: Duration.zero,
        localStream: callManager.localStream,
        remoteStream: callManager.remoteStream,
      ),
    );
  }

  /// New handler: Decline an incoming call.
  Future<void> _handleDeclineIncomingCallEvent(
    DeclineIncomingCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    await callManager.declineCall();
  }

  /// **🔹 Handles the start of an outgoing call**
  Future<void> _handleOutgoingCallEvent(
    StartOutgoingCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    await callManager.startOutgoingCall(event.targetPeerId);
  }

  /// **🔹 Handles the end of a call**
  Future<void> _handleHangUpCallEvent(
    HangUpCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    await callManager.hangUp();
  }

  /// **🔹 Handles the retry of a call**
  Future<void> _handleRedialCallEvent(
    RedialCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    await callManager.startRedialCall();
  }

  /// **🔹 Handles the camera switch**
  Future<void> _handleSwitchCameraEvent(
    SwitchCameraEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    await callManager.switchCamera();
  }
}
