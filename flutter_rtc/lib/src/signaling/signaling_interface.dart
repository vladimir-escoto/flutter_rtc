// Abstract signaling interface that all implementations must follow.
import 'package:flutter_rtc/src/signaling/signaling_event.dart';

import '../../flutter_rtc.dart';

abstract class SignalingInterface {
  // Stream of signaling events.
  Stream<SignalingEvent> get events;

  // Connect to the signaling server.
  Future<void> connect();

  // Disconnect from the signaling server.
  Future<void> disconnect();

  // Send an offer (SDP) to the target peer.
  Future<void> sendOffer(String peerId, dynamic offer);

  // Send an answer (SDP) to the target peer.
  Future<void> sendAnswer(String peerId, dynamic answer);

  // Send an ICE candidate to the target peer.
  Future<void> sendIceCandidate(String peerId, dynamic candidate);

  // Notify the caller that the call was declined.
  Future<void> sendCallDecline(String peerId, dynamic info);
}
