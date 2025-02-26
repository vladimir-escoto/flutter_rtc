// Abstract signaling interface that all signaling implementations must follow.
import 'package:flutter_rtc/src/signaling/signaling_event.dart';

abstract class SignalingInterface {
  // Stream of signaling events for the app to listen to.
  Stream<SignalingEvent> get events;

  // Connect to the signaling server.
  Future<void> connect();

  // Disconnect from the signaling server.
  Future<void> disconnect();

  // Send an offer to a specified peer.
  Future<void> sendOffer(String peerId, dynamic offer);

  // Send an answer to a specified peer.
  Future<void> sendAnswer(String peerId, dynamic answer);

  // Send an ICE candidate to a specified peer.
  Future<void> sendIceCandidate(String peerId, dynamic candidate);
}

