import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../flutter_rtc.dart';
import 'bloc/call_enums.dart';

class CallManager {
  final SignalingInterface signaling;
  final String clientId;
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? _currentCallPeerId;

  final List<RTCIceCandidate> _iceCandidates = [];
  Map<String, dynamic>? _offer;

  final StreamController<CallLifecycleStatus> _callEventController =
      StreamController<CallLifecycleStatus>.broadcast();

  Stream<CallLifecycleStatus> get callEvents => _callEventController.stream;

  RTCDataChannel? dataChannel;
  final StreamController<Map<String, dynamic>> _remoteControlController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get remoteControlEvents => _remoteControlController.stream;

  CallManager({required this.signaling, required this.clientId});

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
      _callEventController.add(CallLifecycleStatus.failed);
      debugPrint(
        "[CallManager] Permissions denied. Camera: $cameraGranted, Microphone: $microphoneGranted",
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
    _callEventController.add(CallLifecycleStatus.initial);



    _callEventController.add(CallLifecycleStatus.calling);
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
        debugPrint("[CallManager] Adding local track: $track");
        _peerConnection?.addTrack(track, localStream!);
      });

      // Create a data channel for control messages.
      dataChannel = await _peerConnection!.createDataChannel(
        'control',
        RTCDataChannelInit(),
      );

      dataChannel?.onMessage = (RTCDataChannelMessage message) {
        try {
          debugPrint("[CallManager] Received control message: ${message.text}");
          final data = jsonDecode(message.text);
          _remoteControlController.add(data);
        } catch (e) {
          debugPrint("[CallManager] Error decoding data channel message: $e");
        }
      };

      // Handle ICE candidates.
      _iceCandidates.clear();
      _peerConnection?.onIceCandidate = (candidate) {
        _iceCandidates.add(candidate);
      };

      _peerConnection?.onAddStream = (stream) {
        debugPrint("[CallManager] Received remote stream: $stream");
        remoteStream = stream;
      };

      _peerConnection?.onConnectionState = _onConnectionState;

      // Create offer and send via signaling.
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      debugPrint("[CallManager] Sent offer: $offer");
      await signaling.sendOffer(targetPeerId, offer.toMap());
    } catch (e) {
      _callEventController.add(CallLifecycleStatus.failed);
      debugPrint("[CallManager] Error starting outgoing call: $e");
    }
  }

  /// Answers an incoming call by obtaining permissions, local media,
  /// creating the peer connection and handling the incoming data channel.
  Future<void> answerIncomingCall() async {
    debugPrint("[CallManager] Answering incoming call.");
    try {
      _callEventController.add(CallLifecycleStatus.initial);

      if (_currentCallPeerId == null) {
        throw Exception("No current call senderId to answer.");
      }

      if (_offer == null || _offer!.isEmpty) {
        throw Exception("No current offer to answer.");
      }

      String senderId = _currentCallPeerId!;
      var offer = _offer!;

      final permissionsGranted = await _ensurePermissions();
      if (!permissionsGranted) {
        declineCall();
        return;
      }
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
        debugPrint("[CallManager] Adding local track: $track");
        _peerConnection?.addTrack(track, localStream!);
      });

      // Set up ICE candidate handler.
      _peerConnection?.onIceCandidate = (candidate) {
        if (_currentCallPeerId != null) {
          debugPrint("[CallManager] Sending IceCandidate [B]");
          signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
        }
      };

      _peerConnection?.onConnectionState = _onConnectionState;

      // Listen for incoming data channel.
      _peerConnection?.onDataChannel = (RTCDataChannel channel) {
        dataChannel = channel;
        dataChannel?.onMessage = (RTCDataChannelMessage message) {
          try {
            final data = jsonDecode(message.text);
            debugPrint("[CallManager] Received control message: $data");
            _remoteControlController.add(data);
          } catch (e) {
            debugPrint("[CallManager] Error decoding incoming data channel message: $e");
          }
        };
      };

      // Handle remote stream.
      _peerConnection?.onAddStream = (stream) {
        debugPrint("[CallManager] Received remote stream: $stream");
        remoteStream = stream;
      };

      // Set remote description from the received offer.
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      // Create answer.
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      debugPrint("[CallManager] Sent answer: $answer");
      await signaling.sendAnswer(senderId, answer.toMap());

      _callEventController.add(CallLifecycleStatus.connecting);
    } catch (e) {
      _callEventController.add(CallLifecycleStatus.failed);
      debugPrint("[CallManager] Error answering incoming call: $e");
    }
  }

  void _onConnectionState(state) {
    debugPrint("[CallManager] Connection state changed: $state");
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
      _disposeCall();
      _callEventController.add(CallLifecycleStatus.ended);
    }
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
      _disposeCall();
      _callEventController.add(CallLifecycleStatus.failed);
    }
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
      _disposeCall();
      _callEventController.add(CallLifecycleStatus.failed);
    }
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
      _callEventController.add(CallLifecycleStatus.connected);
    }
    if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
      _callEventController.add(CallLifecycleStatus.connecting);
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

  Future<void> _disposeCall() async {

    try {
      localStream?.getTracks().forEach((track) => track.stop());
      remoteStream?.getTracks().forEach((track) => track.stop());
      await _peerConnection?.close();
    } catch (e) {
      debugPrint("[CallManager] Error during hang up: $e");
    }
    _peerConnection = null;
    _currentCallPeerId = null;
    localStream = null;
    remoteStream = null;
  }

  /// Hangs up the call.
  Future<void> hangUp() async {
    await signaling.sendCallEnded(_currentCallPeerId!, "");
    _disposeCall();
    _callEventController.add(CallLifecycleStatus.ended);
  }

  Future<void> declineCall() async {
    await signaling.sendCallDecline(_currentCallPeerId!, "");
    _disposeCall();
    _callEventController.add(CallLifecycleStatus.ended);
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
            _callEventController.add(CallLifecycleStatus.declined);
            break;
          case SignalingEventType.callEnded:
            _disposeCall();
            _callEventController.add(CallLifecycleStatus.ended);
            break;
          default:
            debugPrint("[CallManager] unknown signaling event: ${event.type}");
            break;
        }
      } catch (e) {
        _disposeCall();
        _callEventController.add(CallLifecycleStatus.failed);
        debugPrint("[CallManager] Error handling signaling event: $e");
      }
    });
  }

  /// Handles an incoming offer by automatically answering it
  /// and emitting the appropriate event.
  Future<void> _handleIncomingOffer(dynamic data) async {
    final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
    debugPrint("[CallManager] Receive offer: $parsedData");
    _currentCallPeerId = parsedData['senderId'];
    _offer = parsedData['offer'];
    // Emit event to notify an incoming call.
    _callEventController.add(CallLifecycleStatus.incoming);
  }

  /// Handles an incoming answer by setting the remote description.
  Future<void> _handleIncomingAnswer(dynamic data) async {
    final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
    final dynamic answer = parsedData['answer'];
    await _peerConnection?.setRemoteDescription(
      RTCSessionDescription(answer['sdp'], answer['type']),
    );
    debugPrint("[CallManager] Receive answer: $answer");
    // Notify that the receiver is ringing
    _callEventController.add(CallLifecycleStatus.ringing);

    if (_currentCallPeerId?.isNotEmpty ?? false) {
      debugPrint("[CallManager] Sending IceCandidate [A] [${_iceCandidates.length}]");
      for (var candidate in _iceCandidates) {
        signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
      }
    }
  }

  Future<void> _handleIncomingIceCandidate(dynamic data) async {
    final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
    final dynamic candidate = parsedData['candidate'];
    final rtcCandidate = RTCIceCandidate(
      candidate['candidate'],
      candidate['sdpMid'],
      candidate['sdpMLineIndex'],
    );
    await _peerConnection?.addCandidate(rtcCandidate);
    debugPrint("[CallManager] Receive IceCandidate: ${rtcCandidate.toMap()}");
  }
}
