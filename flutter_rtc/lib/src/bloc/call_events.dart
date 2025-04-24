// // call_events.dart
// //
// // This file defines all events that the CallBloc can receive.
// // It now includes the new ToggleLocalControlEvent for toggling a control.
//
// import 'package:flutter_rtc/src/bloc/call_enums.dart';
//
// /// Base abstract class for all call events.
// abstract class CallBlocEvent {}
//
// /// Event representing a change in the call lifecycle.
// class CallLifecycleEvent extends CallBlocEvent {
//   final CallEvent status;
//
//   CallLifecycleEvent({required this.status});
// }
//
// /// **New Event:** Event for toggling a local control.
// /// Instead of providing a new value, the BLoC will compute the toggle.
// class ToggleLocalControlEvent extends CallBlocEvent {
//   final LocalControlType control;
//   final CallMode? callMode;
//
//   ToggleLocalControlEvent({required this.control, this.callMode});
// }
//
// /// Event for remote control updates (from other participants).
// class RemoteControlEvent extends CallBlocEvent {
//   final RemoteControlType control;
//   final bool value;
//
//   RemoteControlEvent({required this.control, required this.value});
// }
//
// /// Event for UI interactions.
// class UIEvent extends CallBlocEvent {
//   final UIEventType event;
//   final dynamic value;
//
//   UIEvent({required this.event, this.value});
// }
//
// /// Event representing an error in the call process.
// class CallErrorEvent extends CallBlocEvent {
//   final String errorMessage;
//
//   CallErrorEvent({required this.errorMessage});
// }
//
// /// New event: Accept an incoming call.
// /// The BLoC can use the provided call mode to set the appropriate UI.
// class AcceptIncomingCallEvent extends CallBlocEvent {
//   final CallMode callMode;
//
//   AcceptIncomingCallEvent({required this.callMode});
// }
//
// /// New event: Decline an incoming call.
// class DeclineIncomingCallEvent extends CallBlocEvent {
//   final String? reason;
//
//   DeclineIncomingCallEvent({this.reason});
// }
//
// class StartOutgoingCallEvent extends CallBlocEvent {
//   final String targetPeerId;
//   final CallMode callMode;
//
//   StartOutgoingCallEvent({required this.callMode, required this.targetPeerId});
// }
//
// /// New event: Hang up the current call.
// class HangUpCallEvent extends CallBlocEvent {}
//
// /// New event: Hang up the current call.
// class RedialCallEvent extends CallBlocEvent {}
//
// /// New event for switching the camera.
// class SwitchCameraEvent extends CallBlocEvent {}
