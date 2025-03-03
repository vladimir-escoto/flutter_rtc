// call_bloc.dart
//
// This file contains the implementation of the CallBloc,
// which acts as an intermediary between the signaling layer and the UI.
// It processes incoming events and updates the call state accordingly.

import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'call_state.dart';
import 'call_events.dart';
import 'call_enums.dart';

class CallBloc extends Bloc<CallBlocEvent, CallBlocState> {
  // Constructor initializing with the initial state.
  CallBloc() : super(initialCallBlocState) {
    on<CallLifecycleEvent>(_handleLifecycleEvent);
    on<LocalControlEvent>(_handleLocalControlEvent);
    //toggle event handler:
    on<ToggleLocalControlEvent>(_handleToggleLocalControlEvent);
    on<RemoteControlEvent>(_handleRemoteControlEvent);
    on<UIEvent>(_handleUIEvent);
    on<SignalingBlocEvent>(_handleSignalingEvent);
    on<CallErrorEvent>(_handleErrorEvent);
    //incoming call events:
    on<AcceptIncomingCallEvent>(_handleAcceptIncomingCallEvent);
    on<DeclineIncomingCallEvent>(_handleDeclineIncomingCallEvent);
    on<HangUpCallEvent>(_handleHangUpCallEvent);
  }

  /// Handles lifecycle events by updating the lifecycle status.
  void _handleLifecycleEvent(CallLifecycleEvent event, Emitter<CallBlocState> emit) {
    emit(state.copyWith(lifecycleStatus: event.status));
  }

  /// Handles explicit local control events (if provided with a value).
  void _handleLocalControlEvent(LocalControlEvent event, Emitter<CallBlocState> emit) {
    switch (event.control) {
      case LocalControlType.mic:
        emit(state.copyWith(localMicOn: event.value));
        break;
      case LocalControlType.camera:
        emit(state.copyWith(localCameraOn: event.value));
        break;
      case LocalControlType.speaker:
        emit(state.copyWith(localSpeakerOn: event.value));
        break;
      case LocalControlType.screenshare:
        emit(state.copyWith(localScreenShareOn: event.value));
        break;
      case LocalControlType.callMode:
      // Here, event.value is expected to be true for video, false for audio.
        emit(state.copyWith(callMode: event.value ? CallMode.video : CallMode.audio));
        break;
    }
  }

  /// Handles toggle events by reading the current state and toggling it.
  void _handleToggleLocalControlEvent(ToggleLocalControlEvent event, Emitter<CallBlocState> emit) {
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
      // Toggle between video and audio.
        emit(state.copyWith(
          callMode: state.callMode == CallMode.video ? CallMode.audio : CallMode.video,
        ));
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
      // This event can be used to update additional UI state if needed.
        break;
    }
  }

  /// Handles signaling events from the WebRTC layer.
  void _handleSignalingEvent(SignalingBlocEvent event, Emitter<CallBlocState> emit) {
    if (event.event == SignalingEventType.connectionQualityChanged) {
      // Update state based on connection quality data if desired.
    }
    // Additional signaling events can be handled here.
  }

  /// Handles error events by updating the error message in the state.
  void _handleErrorEvent(CallErrorEvent event, Emitter<CallBlocState> emit) {
    emit(state.copyWith(errorMessage: event.errorMessage));
  }

  /// New handler: Accept an incoming call.
  void _handleAcceptIncomingCallEvent(AcceptIncomingCallEvent event, Emitter<CallBlocState> emit) {
    // When an incoming call is accepted, update lifecycle to connected.
    // Additional logic, such as starting the call timer, should be implemented in your signaling layer.
    emit(state.copyWith(lifecycleStatus: CallLifecycleStatus.connected, callDuration: Duration.zero));
  }

  /// New handler: Decline an incoming call.
  void _handleDeclineIncomingCallEvent(DeclineIncomingCallEvent event, Emitter<CallBlocState> emit) {
    // Update lifecycle to declined.
    emit(state.copyWith(lifecycleStatus: CallLifecycleStatus.declined, errorMessage: event.reason));
  }

  /// New handler: Hang up the current call.
  void _handleHangUpCallEvent(HangUpCallEvent event, Emitter<CallBlocState> emit) {
    // Update lifecycle to ended.
    emit(state.copyWith(lifecycleStatus: CallLifecycleStatus.ended));
  }
}
