import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/src/context/rtc/rtc_manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_events.dart';
import 'package:flutter_rtc/src/context/bloc/call_state.dart';

class CallBloc extends Bloc<CallBlocEvent, CallBlocState> {
  final RTCManager rtcManager;
  final String callId;

  CallBloc({required this.callId, required this.rtcManager})
    : super(initialCallBlocState) {
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
    //  rtcManager.callEvents.listen((event) => add(CallLifecycleEvent(status: event)));
  }

  /// **🔹 Handling of call lifecycle events**
  void _handleLifecycleEvent(CallLifecycleEvent event, Emitter<CallBlocState> emit) {

  }

  /// **🔹 Handles the change of states of local controls**
  void _handleToggleLocalControlEvent(
    ToggleLocalControlEvent event,
    Emitter<CallBlocState> emit,
  ) {

  }

  /// Handles remote control events received via the data channel.
  void _handleRemoteControlEvent(RemoteControlEvent event, Emitter<CallBlocState> emit) {

  }

  /// Handles UI events such as minimizing, maximizing, dragging, and timer updates.
  void _handleUIEvent(UIEvent event, Emitter<CallBlocState> emit) {

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

  }

  /// New handler: Decline an incoming call.
  Future<void> _handleDeclineIncomingCallEvent(
    DeclineIncomingCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {

  }

  /// **🔹 Handles the start of an outgoing call**
  Future<void> _handleOutgoingCallEvent(
    StartOutgoingCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {

  }

  /// **🔹 Handles the end of a call**
  Future<void> _handleHangUpCallEvent(
    HangUpCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {

  }

  /// **🔹 Handles the retry of a call**
  Future<void> _handleRedialCallEvent(
    RedialCallEvent event,
    Emitter<CallBlocState> emit,
  ) async {

  }

  /// **🔹 Handles the camera switch**
  Future<void> _handleSwitchCameraEvent(
    SwitchCameraEvent event,
    Emitter<CallBlocState> emit,
  ) async {

  }
}
