// lib/enhanced_call_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../bloc/call_bloc.dart';
import '../bloc/call_enums.dart';
import '../bloc/call_events.dart';
import '../bloc/call_state.dart';

/// EnhancedCallScreen displays the call UI using a BLoC for state management.
/// All call-related information (streams, controls, lifecycle, minimization, etc.)
/// is maintained within the bloc state.
class EnhancedCallScreen extends StatefulWidget {
  final CallBloc callBloc;

  static const route = 'enhanced_call_screen';

  const EnhancedCallScreen({super.key, required this.callBloc});

  @override
  EnhancedCallScreenState createState() => EnhancedCallScreenState();
}

class EnhancedCallScreenState extends State<EnhancedCallScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderers();
  }

  /// Initialize the RTC renderers based on the streams from the bloc state.
  Future<void> _initializeRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  void dispose() {
    debugPrint("dispose renders");
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  // --- UI Control Handlers: dispatch events to the bloc ---
  void _onToggleMic() =>
      widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.mic));

  void _onToggleCamera() =>
      widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.camera));

  void _onToggleSpeaker() =>
      widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.speaker));

  void _onToggleScreenShare() =>
      widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.screenshare));

  void _onSwitchCamera() => widget.callBloc.add(SwitchCameraEvent());

  /// Safely closes the call screen if it is still in the navigation stack.
  void _closeCallScreen() {
    if (mounted && Navigator.canPop(context)) {
      Navigator.of(
        context,
      ).popUntil((route) => route.settings.name != EnhancedCallScreen.route);
    }
  }

  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallBlocState>(
      bloc: widget.callBloc,
      listener: (context, state) {
        if (state.lifecycleStatus == CallLifecycleStatus.ended) {
          _closeCallScreen();
        }
      },
      builder: (context, state) {
        // Set the renderer sources from the state.
        if (state.localStream != null && _localRenderer.textureId != null) {
          _localRenderer.srcObject = state.localStream;
        }
        if (state.remoteStream != null && _localRenderer.textureId != null) {
          _remoteRenderer.srcObject = state.remoteStream;
        }
        // If an incoming call is detected, show the incoming call view.
        if (state.lifecycleStatus == CallLifecycleStatus.incoming) {
          return _buildIncomingCallView(state);
        }
        // For an outgoing video call that is not yet connected,
        // display the local stream full screen.
        if (state.callMode == CallMode.video &&
            (state.lifecycleStatus == CallLifecycleStatus.calling ||
                state.lifecycleStatus == CallLifecycleStatus.connecting) &&
            state.remoteStream == null) {
          return _buildOutgoingLocalOnlyView(state);
        }
        // Otherwise, show full-screen or minimized view based on state.
        return state.uiMinimized
            ? _buildMinimizedView(state)
            : _buildFullScreenView(state);
      },
    );
  }

  /// Builds the view for an outgoing video call when only the local stream is available.
  Widget _buildOutgoingLocalOnlyView(CallBlocState state) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child:
                state.localStream != null
                    ? RTCVideoView(_localRenderer)
                    : Container(color: Colors.black),
          ),
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
                  onPressed: () {
                    widget.callBloc.add(HangUpCallEvent());
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the incoming call view.
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
                    heroTag: 'declined',
                    onPressed: () {
                      widget.callBloc.add(
                        DeclineIncomingCallEvent(reason: "declined by user"),
                      );
                    },
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.call_end, size: 30),
                  ),
                  FloatingActionButton(
                    heroTag: 'Call',
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
          // Remote video or placeholder if remote camera is off.
          Positioned.fill(
            child:
                state.remoteStream != null && state.remoteCameraOn
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
              feedback: _buildLocalVideoBox(state),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                widget.callBloc.add(
                  UIEvent(event: UIEventType.dragged, value: details.offset),
                );
              },
              child: _buildLocalVideoBox(state),
            ),
          ),
          // Bottom call controls (visible when connected).
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
          // Error overlay.
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
              final newOffset = state.uiPosition + details.delta;
              widget.callBloc.add(UIEvent(event: UIEventType.dragged, value: newOffset));
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
                  state.remoteStream != null && state.remoteCameraOn
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
  Widget _buildLocalVideoBox(CallBlocState state) {
    return Container(
      width: 120,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey,
      ),
      child: (state.localStream != null) ? RTCVideoView(_localRenderer) : Container(),
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
            if (mounted) {
              Navigator.of(context).pop();
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
                  onPressed: () {
                    widget.callBloc.add(RedialCallEvent());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 40),
                  onPressed: () {
                    widget.callBloc.add(HangUpCallEvent());
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
      case CallLifecycleStatus.calling:
        return "Calling";
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
      case CallLifecycleStatus.failed:
        return "Failed";
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
