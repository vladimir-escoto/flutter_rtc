import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../flutter_rtc.dart';

/// Internal events emitted during the call process.
enum CallEvent { remoteStreamAdded, callStarted, callEnded }

class CallManager {
  final SignalingInterface signaling;
  final String clientId;
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? _currentCallPeerId;

  final StreamController<CallEvent> _callEventController =
      StreamController<CallEvent>.broadcast();

  Stream<CallEvent> get callEvents => _callEventController.stream;

  // Data channel for sending control messages (e.g., toggle mic, camera, etc.)
  RTCDataChannel? dataChannel;
  final StreamController<Map<String, dynamic>> _remoteControlController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get remoteControlEvents => _remoteControlController.stream;

  CallManager({required this.signaling, required this.clientId});

  /// Ensures that required permissions (camera, mic, notifications) are granted.
  Future<bool> _ensurePermissions() async {
    final statuses =
        await [
          Permission.camera,
          Permission.microphone,
          Permission.notification,
        ].request();
    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final microphoneGranted = statuses[Permission.microphone]?.isGranted ?? false;
    if (!cameraGranted || !microphoneGranted) {
      debugPrint(
        "[CallManager] Permissions not granted. Camera: $cameraGranted, Microphone: $microphoneGranted",
      );
      return false;
    }
    return true;
  }

  Future<void> startRedialCall() async {
    if (_currentCallPeerId != null) {
      startOutgoingCall(_currentCallPeerId!);
    } else {
      debugPrint("[CallManager] No current call to redial.");
      throw Exception("No current call to redial.");
    }
  }
  /// Starts an outgoing call by ensuring permissions, obtaining local media,
  /// creating the peer connection and establishing a data channel.
  Future<void> startOutgoingCall(String targetPeerId) async {
    _currentCallPeerId = targetPeerId;
    final permissionsGranted = await _ensurePermissions();
    if (!permissionsGranted) {
      debugPrint("[CallManager] Required permissions not granted. Aborting call start.");
      return;
    }

    try {
      // Obtain local media stream.
      localStream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });

      // Create the peer connection.
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      }, {});

      // Add local tracks.
      localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, localStream!);
      });

      // Create a data channel for control messages.
      dataChannel = await _peerConnection!.createDataChannel(
        'control',
        RTCDataChannelInit(),
      );
      dataChannel?.onMessage = (RTCDataChannelMessage message) {
        try {
          final data = jsonDecode(message.text);
          _remoteControlController.add(data);
        } catch (e) {
          debugPrint("[CallManager] Error decoding data channel message: $e");
        }
      };

      // Handle ICE candidates.
      _peerConnection?.onIceCandidate = (candidate) {
        if (_currentCallPeerId != null) {
          signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
        }
      };

      // Handle remote stream.
      _peerConnection?.onAddStream = (stream) {
        remoteStream = stream;
        _callEventController.add(CallEvent.remoteStreamAdded);
      };

      // Create offer and send via signaling.
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      await signaling.sendOffer(targetPeerId, offer.toMap());
      _callEventController.add(CallEvent.callStarted);
    } catch (e) {
      debugPrint("[CallManager] Error starting outgoing call: $e");
    }
  }

  /// Answers an incoming call by obtaining permissions, local media,
  /// creating the peer connection and handling the incoming data channel.
  Future<void> answerIncomingCall(String senderId, dynamic offer) async {
    _currentCallPeerId = senderId;
    final permissionsGranted = await _ensurePermissions();
    if (!permissionsGranted) {
      signaling.sendCallDecline(senderId, {"reason": "permissions not granted"});
      return;
    }

    try {
      // Obtain local media stream.
      localStream = await navigator.mediaDevices.getUserMedia({
        'video': true,
        'audio': true,
      });

      // Create the peer connection.
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ],
      }, {});

      // Add local tracks.
      localStream?.getTracks().forEach((track) {
        _peerConnection?.addTrack(track, localStream!);
      });

      // Set up ICE candidate handler.
      _peerConnection?.onIceCandidate = (candidate) {
        if (_currentCallPeerId != null) {
          signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
        }
      };

      // Listen for incoming data channel.
      _peerConnection?.onDataChannel = (RTCDataChannel channel) {
        dataChannel = channel;
        dataChannel?.onMessage = (RTCDataChannelMessage message) {
          try {
            final data = jsonDecode(message.text);
            _remoteControlController.add(data);
          } catch (e) {
            debugPrint("[CallManager] Error decoding incoming data channel message: $e");
          }
        };
      };

      // Handle remote stream.
      _peerConnection?.onAddStream = (stream) {
        remoteStream = stream;
        _callEventController.add(CallEvent.remoteStreamAdded);
      };

      // Set remote description from the received offer.
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      // Create answer.
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      await signaling.sendAnswer(senderId, answer.toMap());
      _callEventController.add(CallEvent.callStarted);
    } catch (e) {
      debugPrint("[CallManager] Error answering incoming call: $e");
    }
  }

  Future<void> switchCamera() async {
    try {
      final videoTrack = localStream?.getVideoTracks().first;
      if (videoTrack != null) {
        Helper.switchCamera(videoTrack);
      }

      sendControlMessage("switch_camera", true);
    } catch (e) {
      debugPrint("[CallManager] Error during switch Camera: $e");
    }
  }

  /// Hangs up the call.
  Future<void> hangUp() async {
    try {
      await _peerConnection?.close();
    } catch (e) {
      debugPrint("[CallManager] Error during hang up: $e");
    }
    _peerConnection = null;
    _currentCallPeerId = null;
    _callEventController.add(CallEvent.callEnded);
  }

  /// Sends a control message over the data channel.
  Future<void> sendControlMessage(String event, dynamic value) async {
    if (dataChannel != null) {
      try {
        final message = jsonEncode({"event": event, "value": value});
        dataChannel!.send(RTCDataChannelMessage(message));
      } catch (e) {
        debugPrint("[CallManager] Error sending control message: $e");
      }
    }
  }

  Future<void> setupIncomingCallListener() async {
    await _ensurePermissions();
    signaling.events.listen((event) async {
      try {
        switch (event.type) {
          case SignalingEventType.incomingOffer:
            await _handleIncomingOffer(event.data);
            break;
          case SignalingEventType.incomingAnswer:
            await _handleIncomingAnswer(event.data);
            break;
          case SignalingEventType.incomingIceCandidate:
            await _handleIncomingIceCandidate(event.data);
            break;
          case SignalingEventType.callDeclined:
            _handleCallDeclined();
            break;
          default:
            debugPrint("[CallManager] unknown signaling event: $event");
            break;
        }
      } catch (e) {
        debugPrint("[CallManager] Error handling signaling event: $e");
      }
    });
  }

  /// Handles an incoming offer by automatically answering it
  /// and emitting the appropriate event.
  Future<void> _handleIncomingOffer(dynamic data) async {
    final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
    final String senderId = parsedData['senderId'];
    final dynamic offer = parsedData['offer'];

    // Automatically answer the call.
    await answerIncomingCall(senderId, offer);
    _callEventController.add(CallEvent.callStarted);
  }

  /// Handles an incoming answer by setting the remote description.
  Future<void> _handleIncomingAnswer(dynamic data) async {
    final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
    final dynamic answer = parsedData['answer'];
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
    _callEventController.add(CallEvent.callStarted);
  }

  /// Handles an incoming ICE candidate.
  Future<void> _handleIncomingIceCandidate(dynamic data) async {
    final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
    final dynamic candidate = parsedData['candidate'];
    final rtcCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    await _peerConnection?.addCandidate(rtcCandidate);
  }

  /// Handles the call-declined event.
  void _handleCallDeclined() {
    _callEventController.add(CallEvent.callEnded);
  }
}
