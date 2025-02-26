import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../flutter_rtc.dart';
import 'callkit_manager.dart';

/// Events emitted during the call process.
enum CallEvent { remoteStreamAdded, callStarted, callEnded }

class CallManager {
  final SignalingInterface signaling;
  final String clientId;
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? _currentCallPeerId;
  final StreamController<CallEvent> _callEventController = StreamController.broadcast();
  Stream<CallEvent> get callEvents => _callEventController.stream;
  final CallKitManager _callKitManager = CallKitManager();

  CallManager({required this.signaling, required this.clientId});

  /// Starts an outgoing call by obtaining local media and initiating negotiation.
  Future<void> startOutgoingCall(String targetPeerId) async {
    _currentCallPeerId = targetPeerId;
    print("[CallManager] Starting outgoing call to $targetPeerId");
    // Obtain local media only when starting a call.
    localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    }, {});
    // Add local tracks.
    localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream!);
    });
    // Set up ICE candidate handler.
    _peerConnection?.onIceCandidate = (candidate) {
      if (_currentCallPeerId != null) {
        print("[CallManager] Sending ICE candidate to $_currentCallPeerId");
        signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
      }
    };
    // Handle remote stream.
    _peerConnection?.onAddStream = (stream) {
      remoteStream = stream;
      print("[CallManager] Remote stream added");
      _callEventController.add(CallEvent.remoteStreamAdded);
    };
    // Create offer and send via signaling.
    RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    await signaling.sendOffer(targetPeerId, offer.toMap());
  }

  /// Answers an incoming call after user acceptance.
  Future<void> answerIncomingCall(String senderId, dynamic offer) async {
    _currentCallPeerId = senderId;
    print("[CallManager] Answering incoming call from $senderId");
    localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});
    _peerConnection = await createPeerConnection({
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    }, {});
    localStream?.getTracks().forEach((track) {
      _peerConnection?.addTrack(track, localStream!);
    });
    _peerConnection?.onIceCandidate = (candidate) {
      if (_currentCallPeerId != null) {
        print("[CallManager] Sending ICE candidate to $_currentCallPeerId");
        signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
      }
    };
    _peerConnection?.onAddStream = (stream) {
      remoteStream = stream;
      print("[CallManager] Remote stream added");
      _callEventController.add(CallEvent.remoteStreamAdded);
    };
    // Set remote description from the received offer.
    await _peerConnection!.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
    // Create answer.
    RTCSessionDescription answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);
    await signaling.sendAnswer(senderId, answer.toMap());
  }

  /// Listens to signaling events for incoming calls.
  void setupIncomingCallListener() {
    signaling.events.listen((event) async {
      if (event.type == SignalingEventType.incomingOffer) {
        var data = event.data as Map<String, dynamic>;
        String senderId = data['senderId'];
        dynamic offer = data['offer'];
        print("[CallManager] Incoming call from $senderId");
        // Show CallKit notification for the incoming call.
        await _callKitManager.showIncomingCall(callId: senderId, callerName: senderId);
        // Wait for user response from CallKit.
        var callKitEvent = await _callKitManager.callKitEvents.first;
        if (callKitEvent == CallKitEvent.accepted) {
          await answerIncomingCall(senderId, offer);
          _callEventController.add(CallEvent.callStarted);
        } else {
          print("[CallManager] Call declined by user");
          signaling.sendCallDecline(senderId, {"reason": "declined by user"});
        }
      } else if (event.type == SignalingEventType.incomingAnswer) {
        var data = event.data as Map<String, dynamic>;
        var answer = data['answer'];
        print("[CallManager] Received answer from ${data['senderId']}");
        await _peerConnection?.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
        _callEventController.add(CallEvent.callStarted);
      } else if (event.type == SignalingEventType.incomingIceCandidate) {
        var data = event.data as Map<String, dynamic>;
        var candidate = data['candidate'];
        print("[CallManager] Received ICE candidate from ${data['senderId']}");
        RTCIceCandidate rtcCandidate = RTCIceCandidate(
          candidate['candidate'],
          candidate['sdpMid'],
          candidate['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(rtcCandidate);
      } else if (event.type == SignalingEventType.callDeclined) {
        print("[CallManager] Call declined by ${event.data['senderId']}");
        _callEventController.add(CallEvent.callEnded);
      }
    });
  }

  /// Hangs up the call.
  Future<void> hangUp() async {
    print("[CallManager] Hanging up call");
    await _peerConnection?.close();
    _peerConnection = null;
    _currentCallPeerId = null;
    _callEventController.add(CallEvent.callEnded);
  }
}
