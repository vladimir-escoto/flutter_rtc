// Enum representing signaling event types.
enum SignalingEventType {
  connected,
  disconnected,
  incomingOffer,
  incomingAnswer,
  incomingIceCandidate,
  error,
}

// Class representing a signaling event.
class SignalingEvent {
  final SignalingEventType type;
  final dynamic data;

  SignalingEvent({required this.type, this.data});
}
