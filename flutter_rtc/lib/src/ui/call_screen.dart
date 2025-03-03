// lib/enhanced_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../call_manager.dart';
import '../bloc/call_bloc.dart';
import '../bloc/call_state.dart';
import '../bloc/call_enums.dart';
import '../bloc/call_events.dart';

/// EnhancedCallScreen displays the call UI using a BLoC for state management.
/// It provides controls for mic, camera, speaker, screen share, etc.,
/// and updates the UI based on call lifecycle and control events.
/// It shows different views based on the call lifecycle:
/// - For an outgoing video call that has not yet connected, display the local stream full screen.
/// - When the remote stream becomes available (call connected), show the remote stream in full screen
///   with the local stream as a small draggable overlay.
/// - An incoming call view is also provided for audio and video calls.
class EnhancedCallScreen extends StatefulWidget {
  final CallManager callManager;
  final CallBloc callBloc;
  final Future<void> Function() onHangUp;
  final VoidCallback onRedial;

  const EnhancedCallScreen({
    super.key,
    required this.callManager,
    required this.callBloc,
    required this.onHangUp,
    required this.onRedial,
  });

  @override
  EnhancedCallScreenState createState() => EnhancedCallScreenState();
}

class EnhancedCallScreenState extends State<EnhancedCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // Local UI state for the draggable/minimized view.
  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  /// Initialize local and remote video renderers.
  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    if (widget.callManager.localStream != null) {
      _localRenderer.srcObject = widget.callManager.localStream;
    }
    if (widget.callManager.remoteStream != null) {
      _remoteRenderer.srcObject = widget.callManager.remoteStream;
    }
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  // ---UI Control Handlers: dispatch events to the bloc (the bloc computes the new state)
  void _onToggleMic() {
    widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.mic));
  }

  void _onToggleCamera() {
    widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.camera));
  }

  void _onToggleSpeaker() {
    widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.speaker));
  }

  void _onToggleScreenShare() {
    widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.screenshare));
  }

  void _onSwitchCamera() {
    // This is a one-time command; its result is handled separately.
    widget.callManager.sendControlMessage("switch_camera", true);
  }

  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocListener<CallBloc, CallBlocState>(
      bloc: widget.callBloc,
      listener: (context, state) {
        // Side effects: update local media tracks based on bloc state.
        widget.callManager.localStream?.getAudioTracks().forEach((track) {
          track.enabled = state.localMicOn;
        });
        widget.callManager.localStream?.getVideoTracks().forEach((track) {
          track.enabled = state.localCameraOn;
        });
      },
      child: BlocBuilder<CallBloc, CallBlocState>(
        bloc: widget.callBloc,
        builder: (context, state) {
          // If an incoming call is detected, show the incoming call view.
          if (state.lifecycleStatus == CallLifecycleStatus.incoming) {
            return _buildIncomingCallView(state);
          }
          // For outgoing video calls that are not connected yet,
          // display the local stream full screen if remote stream is not available.
          if (state.callMode == CallMode.video &&
              (state.lifecycleStatus == CallLifecycleStatus.outgoing ||
                  state.lifecycleStatus == CallLifecycleStatus.connecting) &&
              widget.callManager.remoteStream == null) {
            return _buildOutgoingLocalOnlyView(state);
          }
          // Otherwise, show the normal full-screen view (remote primary, local overlay)
          return state.uiMinimized
              ? _buildMinimizedView(state)
              : _buildFullScreenView(state);
        },
      ),
    );
  }

  /// Builds the outgoing call view when it's a video call and not yet connected.
  /// The local stream is shown full screen.
  Widget _buildOutgoingLocalOnlyView(CallBlocState state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child:
                widget.callManager.localStream != null
                    ? RTCVideoView(_localRenderer)
                    : Container(color: Colors.black),
          ),
          // Top bar: display call status and a hang-up button.
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _mapLifecycleStatusToText(state.lifecycleStatus),
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                IconButton(
                  icon: const Icon(Icons.call_end, color: Colors.red),
                  onPressed: () async {
                    widget.callBloc.add(HangUpCallEvent());
                    await widget.onHangUp();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the incoming call view for both audio and video calls.
  Widget _buildIncomingCallView(CallBlocState state) {
    final bool isVideoCall = state.callMode == CallMode.video;
    return Scaffold(
      backgroundColor: Colors.blueGrey[900],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Caller info.
            Column(
              children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: const NetworkImage("https://i.pravatar.cc/100"),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Incoming Call",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  isVideoCall ? "Video Call" : "Audio Call",
                  style: const TextStyle(color: Colors.white70, fontSize: 18),
                ),
              ],
            ),
            // Accept and Decline buttons.
            Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      widget.callBloc.add(
                        DeclineIncomingCallEvent(reason: "declined by user"),
                      );
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, size: 30),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      widget.callBloc.add(
                        AcceptIncomingCallEvent(callMode: state.callMode),
                      );
                    },
                    backgroundColor: Colors.green,
                    child: const Icon(Icons.call, size: 30),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the full-screen call UI when connected.
  Widget _buildFullScreenView(CallBlocState state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video or a placeholder if remote camera is off.
          Positioned.fill(
            child:
                widget.callManager.remoteStream != null && state.remoteCameraOn
                    ? RTCVideoView(_remoteRenderer)
                    : Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white, size: 60),
                      ),
                    ),
          ),
          // Top bar: contact info and call status.
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                const Text(
                  "Contact Name",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _mapLifecycleStatusToText(state.lifecycleStatus),
                    key: ValueKey(state.lifecycleStatus),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ),
                if (state.lifecycleStatus == CallLifecycleStatus.connected)
                  Text(
                    _formatDuration(state.callDuration),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
              ],
            ),
          ),
          // Draggable local video overlay.
          Positioned(
            top: 100,
            right: 20,
            child: Draggable(
              feedback: _buildLocalVideoBox(),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                widget.callBloc.add(
                  UIEvent(event: UIEventType.dragged, value: details.offset),
                );
              },
              child: _buildLocalVideoBox(),
            ),
          ),
          // Bottom call controls (only visible when connected).
          if (state.lifecycleStatus == CallLifecycleStatus.connected)
            Positioned(bottom: 40, left: 0, right: 0, child: _buildCallControls(state)),
          // Minimize button.
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.minimize, color: Colors.white),
              onPressed: () {
                widget.callBloc.add(UIEvent(event: UIEventType.minimized));
              },
            ),
          ),
          // Error overlay if the call is failed or declined.
          if (state.lifecycleStatus == CallLifecycleStatus.failed ||
              state.lifecycleStatus == CallLifecycleStatus.declined)
            _buildErrorOverlay(),
        ],
      ),
    );
  }

  /// Builds the minimized (floating) view.
  Widget _buildMinimizedView(CallBlocState state) {
    return Stack(
      children: [
        Positioned(
          left: state.uiPosition.dx,
          top: state.uiPosition.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              var minimizedOffset = state.uiPosition + details.delta;
              widget.callBloc.add(
                UIEvent(event: UIEventType.dragged, value: minimizedOffset),
              );
            },
            onTap: () {
              widget.callBloc.add(UIEvent(event: UIEventType.maximized));
            },
            child: Container(
              width: 150,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                children: [
                  widget.callManager.remoteStream != null && state.remoteCameraOn
                      ? RTCVideoView(_remoteRenderer)
                      : Container(color: Colors.black),
                  Positioned(
                    top: 5,
                    left: 5,
                    child: Text(
                      _mapLifecycleStatusToText(state.lifecycleStatus),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  const Positioned(
                    bottom: 5,
                    right: 5,
                    child: Icon(Icons.call, color: Colors.white, size: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the local video box.
  Widget _buildLocalVideoBox() {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey,
      ),
      child:
          widget.callManager.localStream != null
              ? RTCVideoView(_localRenderer)
              : Container(),
    );
  }

  /// Builds the row of call control buttons.
  Widget _buildCallControls(CallBlocState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(
            Icons.volume_up,
            color: state.localSpeakerOn ? Colors.white : Colors.grey,
          ),
          onPressed: _onToggleSpeaker,
        ),
        IconButton(
          icon: const Icon(Icons.switch_camera, color: Colors.white),
          onPressed: _onSwitchCamera,
        ),
        IconButton(
          icon: Icon(
            state.localCameraOn ? Icons.videocam : Icons.videocam_off,
            color: Colors.white,
          ),
          onPressed: _onToggleCamera,
        ),
        IconButton(
          icon: Icon(state.localMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
          onPressed: _onToggleMic,
        ),
        IconButton(
          icon: Icon(
            Icons.screen_share,
            color: state.localScreenShareOn ? Colors.white : Colors.grey,
          ),
          onPressed: _onToggleScreenShare,
        ),
        IconButton(
          icon: const Icon(Icons.call_end, color: Colors.red),
          onPressed: () async {
            widget.callBloc.add(HangUpCallEvent());
            await widget.onHangUp();
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          },
        ),
      ],
    );
  }

  /// Builds an overlay to display when the call is failed or declined.
  Widget _buildErrorOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.phone, color: Colors.green, size: 40),
                  onPressed: widget.onRedial,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 40),
                  onPressed: () async {
                    widget.callBloc.add(HangUpCallEvent());
                    await widget.onHangUp();
                    if (mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  /// Maps the call lifecycle status to a user-friendly string.
  String _mapLifecycleStatusToText(CallLifecycleStatus status) {
    switch (status) {
      case CallLifecycleStatus.initiated:
        return "Initiated";
      case CallLifecycleStatus.outgoing:
        return "Outgoing";
      case CallLifecycleStatus.incoming:
        return "Incoming";
      case CallLifecycleStatus.ringing:
        return "Ringing";
      case CallLifecycleStatus.connecting:
        return "Connecting";
      case CallLifecycleStatus.connected:
        return "Connected";
      case CallLifecycleStatus.ended:
        return "Ended";
      case CallLifecycleStatus.declined:
        return "Declined";
      case CallLifecycleStatus.cancelled:
        return "Cancelled";
      case CallLifecycleStatus.failed:
        return "Failed";
      case CallLifecycleStatus.timedOut:
        return "Timed Out";
      default:
        return "";
    }
  }

  /// Formats a Duration into a mm:ss string.
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
  }
}
