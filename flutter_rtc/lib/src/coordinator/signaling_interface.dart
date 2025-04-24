// lib/src/coordinator/signaling_interface.dart
import 'package:flutter_rtc/src/coordinator/signaling_event.dart';

typedef OnSignalingEventCallback = void Function(SignalingEvent event);
typedef OnCallEventDataCallback = void Function(CallEventData event);

abstract class SignalingInterface {
  // Stream of signaling events.
  Stream<SignalingEvent> get events;

  /// Connects the signaling channel (e.g., MQTT, WebSocket...)
  Future<void> connect();

  /// Disconnects and cleans up channel resources
  Future<void> disconnect();

  /// Sends a signaling event with a free structure (Map)
  Future<void> sendEvent(CallEventData payload);

  /// Defines the callback to be executed upon receiving a message
  void setOnCallEvent(OnCallEventDataCallback onEvent);

  void setOnSignalingEvent(OnSignalingEventCallback onEvent);

  /// Informs that a user is active and should receive events
  void registerUser(String userId);

  /// Informs that a user has disconnected
  void unregisterUser(String userId);
}
