import 'dart:async';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Events to be emitted during call negotiation.
enum CallEvent { remoteStreamAdded, callStarted, callEnded }

class CallManager {
  final SignalingInterface signaling;
  final String clientId;
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;

  final StreamController<CallEvent> _callEventController =
      StreamController.broadcast();
  Stream<CallEvent> get callEvents => _callEventController.stream;

  // Variable to hold the id of the peer with whom we're in call.
  String? _currentCallPeerId;

  CallManager({required this.signaling, required this.clientId});

  /// Initialize the call manager: create peer connection, get local stream,
  /// attach local tracks and listen for signaling events.
  Future<void> initialize() async {
    // Obtain local media stream.
    localStream = await navigator.mediaDevices.getUserMedia({
      'video': true,
      'audio': true,
    });

    // Create RTCPeerConnection with ICE servers configuration.
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    }, {});

    // Add local tracks to the connection.
    localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream!);
    });

    // Handle ICE candidates: send them via signaling.
    _peerConnection?.onIceCandidate = (candidate) {
      if (_currentCallPeerId != null) {
        signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
      }
    };

    // When a remote stream is added, save it and emit an event.
    _peerConnection?.onAddStream = (stream) {
      remoteStream = stream;
      _callEventController.add(CallEvent.remoteStreamAdded);
    };

    // If renegotiation is needed (for example, after a track is added), create an offer.
    _peerConnection?.onRenegotiationNeeded = () async {
      if (_currentCallPeerId != null && _peerConnection != null) {
        RTCSessionDescription offer = await _peerConnection!.createOffer();
        await _peerConnection?.setLocalDescription(offer);
        signaling.sendOffer(_currentCallPeerId!, offer.toMap());
      }
    };

    // Listen to signaling events to handle incoming offers, answers and ICE candidates.
    signaling.events.listen((event) async {
      switch (event.type) {
        case SignalingEventType.incomingOffer:
          {
            Map<String, dynamic> data = event.data;
            String senderId = data['senderId'];
            var offer = data['offer'];
            _currentCallPeerId = senderId;
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(offer['sdp'], offer['type']),
            );
            RTCSessionDescription answer =
                await _peerConnection!.createAnswer();
            await _peerConnection!.setLocalDescription(answer);
            signaling.sendAnswer(senderId, answer.toMap());
            _callEventController.add(CallEvent.callStarted);
          }
          break;
        case SignalingEventType.incomingAnswer:
          {
            Map<String, dynamic> data = event.data;
            var answer = data['answer'];
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(answer['sdp'], answer['type']),
            );
            _callEventController.add(CallEvent.callStarted);
          }
          break;
        case SignalingEventType.incomingIceCandidate:
          {
            Map<String, dynamic> data = event.data;
            var candidate = data['candidate'];
            RTCIceCandidate rtcCandidate = RTCIceCandidate(
              candidate['candidate'],
              candidate['sdpMid'],
              candidate['sdpMLineIndex'],
            );
            await _peerConnection!.addCandidate(rtcCandidate);
          }
          break;
        default:
          break;
      }
    });
  }

  /// Method to start an outgoing call to a target peer.
  Future<void> makeCall(String targetPeerId) async {
    _currentCallPeerId = targetPeerId;
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    signaling.sendOffer(targetPeerId, offer.toMap());
  }

  /// Hang up the call.
  Future<void> hangUp() async {
    await _peerConnection?.close();
    _peerConnection = null;
    _currentCallPeerId = null;
    _callEventController.add(CallEvent.callEnded);
  }
}
