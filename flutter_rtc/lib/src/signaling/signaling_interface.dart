// Abstract signaling interface that all implementations must follow.
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_rtc/src/context/model/participant.dart';

part 'signaling_configuration.dart';

part 'signaling_event.dart';

abstract class ISignaling {
  // Stream of signaling events.
  Stream<SignalingEvent> get signalingEvents;

  Stream<CallEventData> get callEvents;

  // Connect to the signaling server.
  Future<void> connect();

  // Disconnect from the signaling server.
  Future<void> disconnect();

  void dispose();

  /// Sends a signaling event with a free structure (Map)
  Future<void> sendEvent(CallEventData payload);

  /// Informs that a user is active and should receive events
  Future<void> registerUser(String userId);

  /// Informs that a user has disconnected
  Future<void> unregisterUser(String userId);
}
