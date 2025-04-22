// lib/src/coordinator/signaling_interface.dart
typedef OnMessageCallback = void Function(Map<String, dynamic> message);

abstract class SignalingInterface {
  /// Connects the signaling channel (e.g., MQTT, WebSocket...)
  Future<void> connect();

  /// Disconnects and cleans up channel resources
  Future<void> disconnect();

  /// Sends a signaling event with a free structure (Map)
  Future<void> sendEvent(Map<String, dynamic> payload);

  /// Defines the callback to be executed upon receiving a message
  void setOnMessage(OnMessageCallback onMessage);

  /// Informs that a user is active and should receive events
  void registerUser(String userId);

  /// Informs that a user has disconnected
  void unregisterUser(String userId);
}
