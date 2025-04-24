// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter_rtc/src/context/bloc/call_enums.dart';
// import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:flutter_rtc/src/bloc/call_enums.dart';
//
//
// class CallManager {
//   final SignalingInterface signaling;
//   final String clientId;
//   RTCPeerConnection? _peerConnection;
//   MediaStream? localStream;
//   MediaStream? remoteStream;
//   MediaStream? screenStream;
//   String? _currentCallPeerId;
//
//   final List<RTCIceCandidate> _iceCandidates = [];
//   Map<String, dynamic>? _offer;
//
//   final StreamController<CallEvent> _callEventController =
//       StreamController<CallEvent>.broadcast();
//
//   Stream<CallEvent> get callEvents => _callEventController.stream;
//
//   RTCDataChannel? dataChannel;
//   final StreamController<Map<String, dynamic>> _remoteControlController =
//       StreamController<Map<String, dynamic>>.broadcast();
//
//   Stream<Map<String, dynamic>> get remoteControlEvents => _remoteControlController.stream;
//
//   StreamSubscription? _signalingSubscription;
//
//   CallManager({required this.signaling, required this.clientId});
//
//   void _sendCallEvent(CallLifecycleStatus status, {dynamic value}) {
//     _callEventController.add(CallEvent(type: status, value: value));
//   }
//
//   /// Ensures that necessary permissions are granted.
//   Future<bool> _ensurePermissions() async {
//     final statuses =
//         await [
//           Permission.camera,
//           Permission.microphone,
//           Permission.notification,
//         ].request();
//
//     final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
//     final microphoneGranted = statuses[Permission.microphone]?.isGranted ?? false;
//     final notificationGranted = statuses[Permission.notification]?.isGranted ?? false;
//
//     if (!cameraGranted || !microphoneGranted) {
//       _sendCallEvent(CallLifecycleStatus.failed);
//       debugPrint(
//         "[CallManager] Permissions denied. Camera: $cameraGranted, Microphone: $microphoneGranted, Notification: $notificationGranted",
//       );
//       return false;
//     }
//     return true;
//   }
//
//   /// Obtains the local media stream.
//   Future<MediaStream> _getLocalMediaStream({
//     bool enableVideo = false,
//     bool enableAudio = true,
//   }) async {
//     final Map<String, dynamic> mediaConstraints = {
//       'audio': enableAudio,
//       'video':
//           enableVideo
//               ? {
//                 'minWidth': '640',
//                 'minHeight': '480',
//                 'minFrameRate': '24',
//                 'facingMode': 'user',
//                 'optional': [],
//               }
//               : false,
//     };
//     return await navigator.mediaDevices.getUserMedia(mediaConstraints);
//   }
//
//   /// Creates a new RTCPeerConnection.
//   Future<RTCPeerConnection> _createPeerConnection() async {
//     final config = {
//       'iceServers': [
//         {'urls': 'stun:stun.l.google.com:19302'},
//       ],
//     };
//     return await createPeerConnection(config, {});
//   }
//
//   Future<void> startRedialCall(bool enableVideo) async {
//     if (_currentCallPeerId != null) {
//       startOutgoingCall(_currentCallPeerId!, enableVideo);
//     } else {
//       debugPrint("[CallManager] No current call to redial.");
//       throw Exception("No current call to redial.");
//     }
//   }
//
//   /// Starts an outgoing call by initializing permissions, local media,
//   /// peer connection, data channel and sending the offer via signaling.
//   Future<void> startOutgoingCall(String targetPeerId, bool enableVideo) async {
//     try {
//       _sendCallEvent(CallLifecycleStatus.initial);
//       _currentCallPeerId = targetPeerId;
//       _sendCallEvent(CallLifecycleStatus.calling, value: {"enableVideo": enableVideo});
//
//       if (!await _ensurePermissions()) {
//         debugPrint(
//           "[CallManager] Required permissions not granted. Aborting call start.",
//         );
//         throw Exception("Required permissions not granted");
//       }
//       // Obtain local media stream.
//       localStream = await _getLocalMediaStream(enableVideo: enableVideo);
//
//       // Create the peer connection.
//       _peerConnection = await _createPeerConnection();
//
//       // Setup peer connection with local stream; store ICE candidates.
//       _setupPeerConnection(_peerConnection!, localStream!, sendIceImmediately: false);
//
//       // Create a data channel for control messages.
//       dataChannel = await _peerConnection!.createDataChannel(
//         'control',
//         RTCDataChannelInit(),
//       );
//       // Setup data channel messages callback.
//       dataChannel?.onMessage = _handleDataChanelMessage;
//
//       // Create offer and send via signaling.
//       RTCSessionDescription offer = await _peerConnection!.createOffer();
//       await _peerConnection!.setLocalDescription(offer);
//       debugPrint("[CallManager] Sent offer: $offer");
//       // await signaling.sendOffer(targetPeerId, offer.toMap(), enableVideo);
//       _sendCallEvent(CallLifecycleStatus.ringing);
//     } catch (e) {
//       debugPrint("[CallManager] Error starting outgoing call: $e");
//       _sendCallEvent(CallLifecycleStatus.failed);
//     }
//   }
//
//   /// Answers an incoming call by obtaining permissions, local media,
//   /// setting up the peer connection and sending the answer via signaling.
//   Future<void> answerIncomingCall() async {
//     try {
//       debugPrint("[CallManager] Answering incoming call.");
//       if (_currentCallPeerId == null) {
//         throw Exception("No current call senderId to answer.");
//       }
//       if (_offer == null || _offer!.isEmpty) {
//         throw Exception("No current offer to answer.");
//       }
//
//       String senderId = _currentCallPeerId!;
//       var offer = _offer!;
//
//       if (!await _ensurePermissions()) {
//         debugPrint(
//           "[CallManager] Required permissions not granted. Aborting call start.",
//         );
//         declineCall();
//         throw Exception("Required permissions not granted");
//       }
//
//       // Obtain local media stream.
//       localStream = await _getLocalMediaStream(enableVideo: true);
//
//       // Create the peer connection.
//       _peerConnection = await _createPeerConnection();
//
//       // Setup peer connection with local stream; send ICE candidates immediately.
//       _setupPeerConnection(_peerConnection!, localStream!, sendIceImmediately: true);
//
//       // Listen for incoming data channel.
//       _peerConnection?.onDataChannel = (RTCDataChannel channel) {
//         dataChannel = channel;
//         // Setup data channel messages callback.
//         dataChannel?.onMessage = _handleDataChanelMessage;
//       };
//
//       // Set remote description from the received offer.
//       await _peerConnection!.setRemoteDescription(
//         RTCSessionDescription(offer['sdp'], offer['type']),
//       );
//       // Create answer.
//       RTCSessionDescription answer = await _peerConnection!.createAnswer();
//       await _peerConnection!.setLocalDescription(answer);
//       debugPrint("[CallManager] Sent answer: $answer");
//       // await signaling.sendAnswer(senderId, answer.toMap());
//
//       //_sendCallEvent(CallLifecycleStatus.connecting);
//     } catch (e) {
//       debugPrint("[CallManager] Error answering incoming call: $e");
//       _sendCallEvent(CallLifecycleStatus.failed);
//     }
//   }
//
//   /// Switches the camera during a call.
//   Future<void> switchCamera() async {
//     try {
//       final videoTrack = localStream?.getVideoTracks().first;
//       if (videoTrack != null) {
//         Helper.switchCamera(videoTrack);
//       }
//       _sendControlMessage("switch_camera", true);
//     } catch (e) {
//       debugPrint("[CallManager] Error during switch Camera: $e");
//     }
//   }
//
//   /// Toggles the speaker output.
//   /// This method calls a platform-specific helper to set the speaker state.
//   Future<void> toggleSpeaker(bool enabled) async {
//     try {
//       await Helper.setSpeakerphoneOn(enabled);
//       debugPrint("[CallManager] Speaker toggled: $enabled");
//     } catch (e) {
//       debugPrint("[CallManager] Error toggling speaker: $e");
//     }
//   }
//
//   /// Toggles the microphone by enabling or disabling local audio tracks.
//   Future<void> toggleMicrophone(bool enabled) async {
//     if (localStream != null) {
//       for (var track in localStream!.getAudioTracks()) {
//         track.enabled = enabled;
//         debugPrint("[CallManager] Microphone toggled. Enabled: ${track.enabled}");
//       }
//     } else {
//       debugPrint("[CallManager] No local stream available for microphone toggle.");
//     }
//   }
//
//   /// Toggles the video by enabling or disabling local video tracks.
//   Future<void> toggleVideo(bool enabled) async {
//     if (localStream != null) {
//       for (var track in localStream!.getVideoTracks()) {
//         track.enabled = enabled;
//         debugPrint("[CallManager] Video toggled. Enabled: ${track.enabled}");
//       }
//     } else {
//       debugPrint("[CallManager] No local stream available for video toggle.");
//     }
//   }
//
//   /// Starts screen sharing by obtaining a display media stream and adding it to the peer connection.
//   /// Returns the screen media stream.
//   Future<void> startScreenSharing() async {
//     try {
//       screenStream = await navigator.mediaDevices.getDisplayMedia({
//         'video': true,
//         'audio': true,
//         // You may add additional constraints if needed.
//       });
//
//       var newTrack =
//           screenStream
//               ?.getTracks()
//               .where((element) => element.kind == 'video')
//               .firstOrNull;
//       if (newTrack != null) {
//         var senders = await _peerConnection?.getSenders();
//
//         senders?.forEach((s) async {
//           if (s.track != null && s.track?.kind == 'video') {
//             await s.replaceTrack(newTrack);
//           }
//         });
//       }
//       localStream?.getTracks().forEach((track) => track.stop());
//       localStream = null;
//       _sendCallEvent(CallLifecycleStatus.connected);
//       debugPrint("[CallManager] Screen sharing started.");
//     } catch (e) {
//       debugPrint("[CallManager] Error starting screen sharing: $e");
//     }
//   }
//
//   /// Stops screen sharing by removing the screen stream from the peer connection and stopping all tracks.
//   Future<void> stopScreenSharing() async {
//     try {
//       localStream = await _getLocalMediaStream(enableVideo: true, enableAudio: true);
//       var newTrack =
//           localStream
//               ?.getTracks()
//               .where((element) => element.kind == 'video')
//               .firstOrNull;
//
//       if (newTrack != null) {
//         var senders = await _peerConnection?.getSenders();
//         senders?.forEach((s) async {
//           if (s.track != null && s.track?.kind == 'video') {
//             await s.replaceTrack(newTrack);
//           }
//         });
//       }
//       screenStream?.getTracks().forEach((track) => track.stop());
//       screenStream = null;
//       _sendCallEvent(CallLifecycleStatus.connected);
//       debugPrint("[CallManager] Screen sharing stopped.");
//     } catch (e) {
//       debugPrint("[CallManager] Error stopping screen sharing: $e");
//     }
//   }
//
//   /// Sets up the listener for incoming signaling events.
//   Future<void> setupSignalingEventsListener() async {
//     await _ensurePermissions();
//     // _signalingSubscription = signaling.events.listen((event) async {
//     //   try {
//     //     switch (event.type) {
//     //       case SignalingEventType.incomingOffer:
//     //         await _handleIncomingOffer(event.data);
//     //         break;
//     //       case SignalingEventType.incomingAnswer:
//     //         await _handleIncomingAnswer(event.data);
//     //         break;
//     //       case SignalingEventType.incomingIceCandidate:
//     //         await _handleIncomingIceCandidate(event.data);
//     //         break;
//     //       case SignalingEventType.callDeclined:
//     //         _sendCallEvent(CallLifecycleStatus.declined);
//     //         break;
//     //       case SignalingEventType.callEnded:
//     //         await _disposeCall();
//     //         _sendCallEvent(CallLifecycleStatus.ended);
//     //         break;
//     //       default:
//     //         debugPrint("[CallManager] Unknown signaling event: ${event.type}");
//     //         break;
//     //     }
//     //   } catch (e) {
//     //     await _disposeCall();
//     //     _sendCallEvent(CallLifecycleStatus.failed);
//     //     debugPrint("[CallManager] Error handling signaling event: $e");
//     //   }
//     // });
//   }
//
//   /// Configures common settings for the peer connection.
//   /// The parameter [sendIceImmediately] determines if ICE candidates
//   /// should be sent immediately (for incoming calls) or stored (for outgoing calls).
//   void _setupPeerConnection(
//     RTCPeerConnection connection,
//     MediaStream stream, {
//     required bool sendIceImmediately,
//   }) {
//     // Add local tracks.
//     for (var track in stream.getTracks()) {
//       debugPrint("[CallManager] Adding local track: $track");
//       connection.addTrack(track, stream);
//     }
//
//     // ICE candidate handler.
//     connection.onIceCandidate = (candidate) {
//       if (sendIceImmediately) {
//         if (_currentCallPeerId != null) {
//           debugPrint(
//             "[CallManager] Sending ICE candidate immediately: ${candidate.toMap()}",
//           );
//           // signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
//         }
//       } else {
//         _iceCandidates.add(candidate);
//       }
//     };
//
//     // Remote stream handler.
//     connection.onAddStream = (stream) {
//       debugPrint("[CallManager] Received remote stream: $stream");
//       remoteStream = stream;
//     };
//
//     // Connection state change handler.
//     connection.onConnectionState = _onConnectionState;
//   }
//
//   void _handleDataChanelMessage(RTCDataChannelMessage message) {
//     try {
//       debugPrint("[CallManager] Received control message: ${message.text}");
//       final data = jsonDecode(message.text);
//       _remoteControlController.add(data);
//     } catch (e) {
//       debugPrint("[CallManager] Error decoding data channel message: $e");
//     }
//   }
//
//   /// Handles connection state changes.
//   void _onConnectionState(state) {
//     debugPrint("[CallManager] Connection state changed: $state");
//     if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
//       _disposeCall();
//       _sendCallEvent(CallLifecycleStatus.ended);
//     }
//     if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
//       _disposeCall();
//       _sendCallEvent(CallLifecycleStatus.failed);
//     }
//     if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
//       _disposeCall();
//       _sendCallEvent(CallLifecycleStatus.failed);
//     }
//     if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
//       _sendCallEvent(CallLifecycleStatus.connected);
//     }
//     if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnecting) {
//       _sendCallEvent(CallLifecycleStatus.connecting);
//     }
//   }
//
//   /// Sends a control message over the data channel.
//   Future<void> _sendControlMessage(String event, dynamic value) async {
//     if (dataChannel != null) {
//       try {
//         final message = jsonEncode({"event": event, "value": value});
//         dataChannel!.send(RTCDataChannelMessage(message));
//       } catch (e) {
//         debugPrint("[CallManager] Error sending control message: $e");
//       }
//     }
//   }
//
//   /// Handles an incoming offer by storing the offer data and notifying listeners.
//   Future<void> _handleIncomingOffer(dynamic data) async {
//     final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
//     debugPrint("[CallManager] Received offer: $parsedData");
//     _currentCallPeerId = parsedData['senderId'];
//     _offer = parsedData['offer'];
//     _sendCallEvent(CallLifecycleStatus.incoming, value: parsedData);
//   }
//
//   /// Handles an incoming answer by setting the remote description
//   /// and sending any stored ICE candidates.
//   Future<void> _handleIncomingAnswer(dynamic data) async {
//     final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
//     final dynamic answer = parsedData['answer'];
//     await _peerConnection?.setRemoteDescription(
//       RTCSessionDescription(answer['sdp'], answer['type']),
//     );
//     debugPrint("[CallManager] Received answer: $answer");
//     _sendCallEvent(CallLifecycleStatus.ringing);
//
//     if (_currentCallPeerId?.isNotEmpty ?? false) {
//       debugPrint(
//         "[CallManager] Sending stored ICE candidates [${_iceCandidates.length}]",
//       );
//       for (var candidate in _iceCandidates) {
//         // signaling.sendIceCandidate(_currentCallPeerId!, candidate.toMap());
//       }
//     }
//   }
//
//   /// Handles an incoming ICE candidate.
//   Future<void> _handleIncomingIceCandidate(dynamic data) async {
//     final Map<String, dynamic> parsedData = data as Map<String, dynamic>;
//     final dynamic candidate = parsedData['candidate'];
//     final rtcCandidate = RTCIceCandidate(
//       candidate['candidate'],
//       candidate['sdpMid'],
//       candidate['sdpMLineIndex'],
//     );
//     await _peerConnection?.addCandidate(rtcCandidate);
//     debugPrint("[CallManager] Received ICE candidate: ${rtcCandidate.toMap()}");
//   }
//
//   /// Disposes the call resources.
//   Future<void> _disposeCall() async {
//     try {
//       localStream?.getTracks().forEach((track) => track.stop());
//       remoteStream?.getTracks().forEach((track) => track.stop());
//       screenStream?.getTracks().forEach((track) => track.stop());
//       await _peerConnection?.close();
//     } catch (e) {
//       debugPrint("[CallManager] Error during hang up: $e");
//     }
//     _peerConnection = null;
//     _currentCallPeerId = null;
//     localStream = null;
//     remoteStream = null;
//     screenStream = null;
//   }
//
//   /// Hangs up the call.
//   Future<void> hangUp() async {
//     if (_currentCallPeerId != null) {
//       // await signaling.sendCallEnded(_currentCallPeerId!, "");
//     }
//     await _disposeCall();
//     _sendCallEvent(CallLifecycleStatus.ended);
//   }
//
//   /// Declines an incoming call.
//   Future<void> declineCall() async {
//     if (_currentCallPeerId != null) {
//       // await signaling.sendCallDecline(_currentCallPeerId!, "");
//     }
//     await _disposeCall();
//     _sendCallEvent(CallLifecycleStatus.ended);
//   }
//
//   /// Dispose method to cancel subscriptions and close stream controllers.
//   void dispose() {
//     _disposeCall();
//     _signalingSubscription?.cancel();
//     _callEventController.close();
//     _remoteControlController.close();
//   }
// }
