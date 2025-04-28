// call_events.dart
//
// This file defines all events that the CallBloc can receive.
// It now includes the new ToggleLocalControlEvent for toggling a control.

part of 'call_bloc.dart';

/// Base abstract class for all call events.
abstract class CallBlocEvent {}

/// Event representing a change in the call lifecycle.
class CallLifecycleEvent extends CallBlocEvent {
  final CallEvent status;

  CallLifecycleEvent(this.status);

  factory CallLifecycleEvent.fromStatus(CallLifeCycleStatus event,
      {dynamic value})
  => CallLifecycleEvent(CallEvent(event, value: value));
}

class PeerConnectionEvent extends CallBlocEvent {
  final PeerCallEvent status;

  PeerConnectionEvent(this.status);
}

/// **New Event:** Event for toggling a local control.
/// Instead of providing a new value, the BLoC will compute the toggle.
class ToggleLocalControlEvent extends CallBlocEvent {
  final LocalControlType control;
  final CallMode? callMode;
  final bool? value;

  ToggleLocalControlEvent({required this.control, this.callMode, this.value});
}

/// Event for remote control updates (from other members).
class RemoteControlEvent extends CallBlocEvent {
  final String memberId;
  final RemoteControlType control;
  final bool value;

  RemoteControlEvent({
    required this.memberId,
    required this.control,
    required this.value,
  });
}

/// Event for UI interactions.
class UIEvent extends CallBlocEvent {
  final UIEventType event;
  final dynamic value;

  UIEvent({required this.event, this.value});
}

/// Event representing an error in the call process.
class CallErrorEvent extends CallBlocEvent {
  final String errorMessage;

  CallErrorEvent({required this.errorMessage});
}

/// New event: Decline an incoming call.
class DeclineIncomingCallEvent extends CallBlocEvent {
  final String? reason;

  DeclineIncomingCallEvent({this.reason});
}

/// New event for  AppLifecycle
class AppLifecycleStateEvent extends CallBlocEvent {
  final AppLifecycleState status;

  AppLifecycleStateEvent({required this.status});
}

/// New event: Accept an incoming call.
/// The BLoC can use the provided call mode to set the appropriate UI.
class AcceptIncomingCallEvent extends CallBlocEvent {
  final CallEventData data;

  AcceptIncomingCallEvent({required this.data});
}

class HoldCallEvent extends CallBlocEvent {
  final bool isOnHold;

  HoldCallEvent({required this.isOnHold});
}

class ResumeCallEvent extends CallBlocEvent {}

class StartOutgoingCallEvent extends CallBlocEvent {}

/// New event: Hang up the current call.
class HangUpCallEvent extends CallBlocEvent {}

/// New event: Hang up the current call.
class RedialCallEvent extends CallBlocEvent {}

/// New event for switching the camera.
class SwitchCameraEvent extends CallBlocEvent {}
