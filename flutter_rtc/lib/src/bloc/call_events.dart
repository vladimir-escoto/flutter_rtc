// call_events.dart
//
// This file defines all events that the CallBloc can receive.
// It now includes the new ToggleLocalControlEvent for toggling a control.

import 'call_enums.dart';

/// Base abstract class for all call events.
abstract class CallBlocEvent {}

/// Event representing a change in the call lifecycle.
class CallLifecycleEvent extends CallBlocEvent {
  final CallLifecycleStatus status;
  final String? details;
  CallLifecycleEvent({required this.status, this.details});
}

/// Event for local control actions (with an explicit value).
class LocalControlEvent extends CallBlocEvent {
  final LocalControlType control;
  final bool value;
  LocalControlEvent({required this.control, required this.value});
}

/// **New Event:** Event for toggling a local control.
/// Instead of providing a new value, the BLoC will compute the toggle.
class ToggleLocalControlEvent extends CallBlocEvent {
  final LocalControlType control;
  ToggleLocalControlEvent({required this.control});
}

/// Event for remote control updates (from other participants).
class RemoteControlEvent extends CallBlocEvent {
  final RemoteControlType control;
  final bool value;
  RemoteControlEvent({required this.control, required this.value});
}

/// Event for UI interactions.
class UIEvent extends CallBlocEvent {
  final UIEventType event;
  final dynamic value;
  UIEvent({required this.event, this.value});
}

/// Event for signaling-related updates.
class SignalingBlocEvent extends CallBlocEvent {
  final SignalingEventType event;
  final dynamic value;
  SignalingBlocEvent({required this.event, this.value});
}

/// Event representing an error in the call process.
class CallErrorEvent extends CallBlocEvent {
  final String errorMessage;
  CallErrorEvent({required this.errorMessage});
}

/// New event: Accept an incoming call.
/// The BLoC can use the provided call mode to set the appropriate UI.
class AcceptIncomingCallEvent extends CallBlocEvent {
  final CallMode callMode;
  AcceptIncomingCallEvent({required this.callMode});
}

/// New event: Decline an incoming call.
class DeclineIncomingCallEvent extends CallBlocEvent {
  final String? reason;
  DeclineIncomingCallEvent({this.reason});
}

/// New event: Hang up the current call.
class HangUpCallEvent extends CallBlocEvent {}
