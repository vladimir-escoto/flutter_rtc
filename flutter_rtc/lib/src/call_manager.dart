// lib/call_manager.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/signaling/signaling_event.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_rtc/src/ui/incoming_call_screen.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';

/// Events emitted during the call process.
enum CallEvent { remoteStreamAdded, callStarted, callEnded }

class CallManager {
  final SignalingInterface signaling;
  final String clientId;
  RTCPeerConnection? _peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? _currentCallPeerId;
  final StreamController<CallEvent> _callEventController = StreamController<CallEvent>.broadcast();
  Stream<CallEvent> get callEvents => _callEventController.stream;

  // Data channel for sending control messages (e.g., toggle mic, camera, etc.)
  RTCDataChannel? dataChannel;
  final StreamController<Map<String, dynamic>> _remoteControlController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get remoteControlEvents => _remoteControlController.stream;

  CallManager({required this.signaling, required this.clientId});

  /// Checks and requests notification permission.
  Future<void> checkNotificationPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      if (status.isPermanentlyDenied) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Permission Required'),
            content: const Text(
              'Notification permission is permanently denied. Please open settings and enable it to receive call notifications.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  openAppSettings();
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
      } else {
        final result = await Permission.notification.request();
        if (!result.isGranted) {
          debugPrint("Notification permission not granted");
        }
      }
    }
  }

  /// Checks and requests camera and microphone permissions.
  Future<bool> _ensurePermissions() async {
    final statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.notification,
    ].request();

    final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
    final microphoneGranted = statuses[Permission.microphone]?.isGranted ?? false;

    if (!cameraGranted || !microphoneGranted) {
      debugPrint("[CallManager] Permissions not granted. Camera: $cameraGranted, Microphone: $microphoneGranted");
      return false;
    }
    return true;
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
      localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});

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
      dataChannel = await _peerConnection!.createDataChannel('control', RTCDataChannelInit());
      dataChannel?.onMessage = (RTCDataChannelMessage message) {
        try {
          final data = jsonDecode(message.text);
          _remoteControlController.add(data);
        } catch (e) {
          debugPrint("[CallManager] Error decoding data channel message: $e");
        }
      };

      // Set up ICE candidate handler.
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
      localStream = await navigator.mediaDevices.getUserMedia({'video': true, 'audio': true});

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
      await _peerConnection!.setRemoteDescription(RTCSessionDescription(offer['sdp'], offer['type']));
      // Create answer.
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      await signaling.sendAnswer(senderId, answer.toMap());
      _callEventController.add(CallEvent.callStarted);
    } catch (e) {
      debugPrint("[CallManager] Error answering incoming call: $e");
    }
  }

  /// Listens to signaling events for incoming calls.
  /// Since this is a library, we manage navigation internally.
  Future<void> setupIncomingCallListener(BuildContext context) async {
    await _ensurePermissions();
    signaling.events.listen((event) async {
      try {
        if (event.type == SignalingEventType.incomingOffer) {
          final data = event.data as Map<String, dynamic>;
          final String senderId = data['senderId'];
          final dynamic _ = data['offer'];
          // Show incoming call UI.
          await Navigator.of(context).push(MaterialPageRoute(
            fullscreenDialog: true,
            builder: (_) => IncomingCallScreen(
              callerName: senderId,
              onAccept: () async {
                // await answerIncomingCall(senderId, offer);
                // _callEventController.add(CallEvent.callStarted);
                // Navigator.of(context).pop(); // Close incoming call screen.
                // // Navigate to active call screen.
                // Navigator.of(context).push(MaterialPageRoute(
                //   builder: (_) => EnhancedCallScreen(
                //     callManager: this,
                //     onHangUp: () async {
                //       await hangUp();
                //       Navigator.of(context).popUntil((route) => route.isFirst);
                //     },
                //     onRedial: () {
                //       // Implement re-dial logic if desired.
                //     },
                //   ),
                // ));
              },
              onDecline: () {
                signaling.sendCallDecline(senderId, {"reason": "declined by user"});
                Navigator.of(context).pop();
              },
            ),
          ));
        } else if (event.type == SignalingEventType.incomingAnswer) {
          final data = event.data as Map<String, dynamic>;
          final answer = data['answer'];
          await _peerConnection?.setRemoteDescription(
            RTCSessionDescription(answer['sdp'], answer['type']),
          );
          _callEventController.add(CallEvent.callStarted);
        } else if (event.type == SignalingEventType.incomingIceCandidate) {
          final data = event.data as Map<String, dynamic>;
          final candidate = data['candidate'];
          final rtcCandidate = RTCIceCandidate(
            candidate['candidate'],
            candidate['sdpMid'],
            candidate['sdpMLineIndex'],
          );
          await _peerConnection?.addCandidate(rtcCandidate);
        } else if (event.type == SignalingEventType.callDeclined) {
          _callEventController.add(CallEvent.callEnded);
        }
      } catch (e) {
        debugPrint("[CallManager] Error handling signaling event: $e");
      }
    });
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
  /// For example: {"event": "toggle_mic", "value": true}
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
}
