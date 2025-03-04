// call_bloc.dart
//
// This file contains the implementation of the CallBloc,
// which acts as an intermediary between the signaling layer and the UI.
// All call-related data (including local and remote streams) is maintained
// within the bloc's state, so that the UI depends solely on the bloc.

import 'dart:async';
import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../call_manager.dart';
import 'call_enums.dart';
import 'call_events.dart';
import 'call_state.dart';

class CallBloc extends Bloc<CallBlocEvent, CallBlocState> {
  final CallManager callManager;

  CallBloc({required this.callManager})
    : super(
        initialCallBlocState.copyWith(
          localStream: callManager.localStream,
          remoteStream: callManager.remoteStream,
        ),
      ) {
    on<CallLifecycleEvent>(_handleLifecycleEvent);
    on<ToggleLocalControlEvent>(_handleToggleLocalControlEvent);
    on<RemoteControlEvent>(_handleRemoteControlEvent);
    on<UIEvent>(_handleUIEvent);
    on<SignalingBlocEvent>(_handleSignalingEvent);
    on<CallErrorEvent>(_handleErrorEvent);
    on<AcceptIncomingCallEvent>(_handleAcceptIncomingCallEvent);
    on<DeclineIncomingCallEvent>(_handleDeclineIncomingCallEvent);
    on<StartOutgoingCallEvent>(_handleOutgoingCallEvent);
    on<HangUpCallEvent>(_handleHangUpCallEvent);
    on<RedialCallEvent>(_handlerRedialCallEvent);
    on<SwitchCameraEvent>(_handleSwitchCameraEvent);

    callManager.callEvents.listen((event) {
      if (event == CallEvent.remoteStreamAdded) {
        add(CallLifecycleEvent(status: CallLifecycleStatus.connected));
      } else if (event == CallEvent.callStarted) {
        add(CallLifecycleEvent(status: CallLifecycleStatus.outgoing));
      } else if (event == CallEvent.callEnded) {
        add(CallLifecycleEvent(status: CallLifecycleStatus.ended));
      }
    });
  }

  /// Handles lifecycle events by updating the lifecycle status.
  void _handleLifecycleEvent(CallLifecycleEvent event, Emitter<CallBlocState> emit) {
    // When connected, update remoteStream from the callManager.
    if (event.status == CallLifecycleStatus.connected) {
      emit(
        state.copyWith(
          lifecycleStatus: event.status,
          remoteStream: callManager.remoteStream,
        ),
      );
    } else {
      emit(state.copyWith(lifecycleStatus: event.status));
    }
  }

  /// Handles toggle events by reading the current state and toggling it.
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

  /// Handles signaling events from the WebRTC layer.
  void _handleSignalingEvent(SignalingBlocEvent event, Emitter<CallBlocState> emit) {
    if (event.event == SignalingEventType.connectionQualityChanged) {
      // Update state based on connection quality data if desired.
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
    emit(
      state.copyWith(
        lifecycleStatus: CallLifecycleStatus.connected,
        callDuration: Duration.zero,
        // Optionally update streams from callManager.
        localStream: callManager.localStream,
        remoteStream: callManager.remoteStream,
      ),
    );
  }

  /// New handler: Decline an incoming call.
  void _handleDeclineIncomingCallEvent(
    DeclineIncomingCallEvent event,
    Emitter<CallBlocState> emit,
  ) {
    emit(
      state.copyWith(
        lifecycleStatus: CallLifecycleStatus.declined,
        errorMessage: event.reason,
      ),
    );
  }

  /// New handler: Hang up the current call.
  Future<void> _handleHangUpCallEvent(
    HangUpCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    await callManager.hangUp();
    emit(state.copyWith(lifecycleStatus: CallLifecycleStatus.ended));
  }

  /// New handler: Switch camera.
  Future<void> _handleSwitchCameraEvent(
    SwitchCameraEvent event,
    Emitter<CallBlocState> emit,
  ) async {
    // CallManager is used to send the switch camera command.
    await callManager.switchCamera();
  }

  FutureOr<void> _handleOutgoingCallEvent(StartOutgoingCallEvent event,
      Emitter<CallBlocState> emit) async {
    await callManager.startOutgoingCall(event.targetPeerId);
  }

  FutureOr<void> _handlerRedialCallEvent(RedialCallEvent event,
      Emitter<CallBlocState> emit) async {
    await callManager.startRedialCall();
  }
}
