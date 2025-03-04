// Enumeration of signaling event types.
enum SignalingEventType {
  connected,
  disconnected,
  incomingOffer,
  incomingAnswer,
  incomingIceCandidate,
  callDeclined,
  callEnded,
  dataChannelMessage,
  connectionQualityChanged,
  error,
}

// A class representing a signaling event.
class SignalingEvent {
  final SignalingEventType type;
  final dynamic data;
  SignalingEvent({required this.type, this.data});
}
