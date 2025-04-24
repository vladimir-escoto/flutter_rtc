import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

part 'call_container_screen/call_screen_view.dart';

part 'call_container_screen/decline_call_view.dart';

part 'call_container_screen/minimized_call_view.dart';

part 'widgets/call_control_option.dart';

part 'widgets/call_overlay.dart';

part 'widgets/call_status_widget.dart';

part 'widgets/incoming_call_controls.dart';

part 'widgets/outgoing_call_controls.dart';

part 'widgets/incoming_call_view.dart';

part 'widgets/outgoing_call_view.dart';

typedef ControlHandler = void Function();
typedef DragUpdateHandler = void Function(Offset);
typedef CallViewBuilder = Widget Function(BuildContext, CallBloc, CallBlocState);

/// CallContainerScreen displays the call UI using a BLoC for state management.
/// All call-related information (streams, controls, lifecycle, minimization, etc.)
/// is maintained within the bloc state.
class CallContainerScreen extends StatefulWidget {
  static const route = 'call_container_screen';

  final CallBloc callBloc;

  final CallViewBuilder? outgoingView;
  final CallViewBuilder? incomingView;
  final CallViewBuilder? activeCallView;
  final CallViewBuilder? endedView;
  final CallViewBuilder? declineView;
  final CallViewBuilder? errorView;

  const CallContainerScreen({
    super.key,
    required this.callBloc,
    this.outgoingView,
    this.incomingView,
    this.activeCallView,
    this.endedView,
    this.declineView,
    this.errorView,
  });

  @override
  State<CallContainerScreen> createState() => _CallContainerScreenState();
}

class _CallContainerScreenState extends State<CallContainerScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  @override
  void initState() {
    super.initState();
    _initializeRenderer();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  Future<void> _initializeRenderer() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  void _updateRenderers(CallBlocState state) {
    if (state.isVideoCall && state.localCameraOn && _localRenderer.textureId != null) {
      _localRenderer.srcObject = state.localStream;
    }

    if (state.isVideoCall && state.remoteCameraOn && _remoteRenderer.textureId != null) {
      _remoteRenderer.srcObject = state.remoteStream;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CallBloc, CallBlocState>(
      bloc: widget.callBloc,
      listener: (context, state) {
        if (state.lifecycleStatus == CallLifecycleStatus.ended) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        _updateRenderers(state);
        switch (state.lifecycleStatus) {
          case CallLifecycleStatus.incoming:
            return _buildIncoming(context, widget.callBloc, state);
          case CallLifecycleStatus.calling:
          case CallLifecycleStatus.ringing:
            return _buildOutgoing(context, widget.callBloc, state);
          case CallLifecycleStatus.connected:
            return _buildActive(context, widget.callBloc, state);
          case CallLifecycleStatus.failed:
            return _buildError(context, widget.callBloc, state);
          case CallLifecycleStatus.declined:
            return _buildDecline(context, widget.callBloc, state);
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }

  // Default fallback UIs
  Widget _buildOutgoing(BuildContext context, CallBloc bloc, CallBlocState state) {
    return widget.outgoingView?.call(context, bloc, state) ??
        OutgoingCallView(callBloc: bloc, state: state, localRenderer: _localRenderer);
  }

  Widget _buildIncoming(BuildContext context, CallBloc bloc, CallBlocState state) {
    return widget.incomingView?.call(context, bloc, state) ??
        IncomingCallView(callBloc: bloc, state: state);
  }

  Widget _buildActive(BuildContext context, CallBloc bloc, CallBlocState state) {
    var view =
        state.uiMinimized
            ? MinimizedCallView(
              callBloc: bloc,
              state: state,
              remoteRenderer: _remoteRenderer,
            )
            : CallScreenView(
              callBloc: bloc,
              state: state,
              localRenderer: _localRenderer,
              remoteRenderer: _remoteRenderer,
            );
    return widget.activeCallView?.call(context, bloc, state) ?? view;
  }

  Widget _buildDecline(BuildContext context, CallBloc bloc, CallBlocState state) {
    return widget.declineView?.call(context, bloc, state) ??
        DeclineCallView(callBloc: bloc);
  }

  Widget _buildError(BuildContext context, CallBloc bloc, CallBlocState state) {
    return widget.errorView?.call(context, bloc, state) ??
        Center(
          child: Text(
            'Call error: ${state.errorMessage}',
            style: const TextStyle(color: Colors.red),
          ),
        );
  }
}

// class CallContainerScreenState extends State<CallContainerScreen> {
//   final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
//   final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
//
//   @override
//   void initState() {
//     super.initState();
//     _localRenderer.initialize();
//     _remoteRenderer.initialize();
//   }
//
//   @override
//   void dispose() {
//     _localRenderer.dispose();
//     _remoteRenderer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<CallBloc, CallBlocState>(
//       bloc: widget.callBloc,
//       listener: (context, state) {
//         if (state.lifecycleStatus == CallLifecycleStatus.ended) {
//           _closeCallScreen();
//         }
//         // Set the renderer sources from the state.
//         if (state.localStream != null &&
//             state.isVideoCall &&
//             state.localCameraOn &&
//             _localRenderer.textureId != null) {
//           _localRenderer.srcObject = state.localStream;
//         }
//
//         if (state.remoteStream != null &&
//             state.isVideoCall &&
//             state.remoteCameraOn &&
//             _localRenderer.textureId != null) {
//           _remoteRenderer.srcObject = state.remoteStream;
//         }
//       },
//       builder: (context, state) {
//         if (state.lifecycleStatus == CallLifecycleStatus.initial) return Container();
//
//         // If an incoming call is detected, show the incoming call view.
//         if (state.isIncomingCall) {
//           return _buildIncomingCallView(state);
//         }
//
//         // For an outgoing call that is not yet connected,
//         if (state.isOutgoingCall) {
//           return _buildOutgoingLocalOnlyView(state);
//         }
//
//         if (state.lifecycleStatus == CallLifecycleStatus.failed) {
//           return _buildErrorOverlay();
//         }
//
//         if (state.lifecycleStatus == CallLifecycleStatus.declined) {
//           return _buildErrorOverlay();
//         }
//
//         // Otherwise, show full-screen or minimized view based on state.
//         return state.uiMinimized
//             ? _buildMinimizedView(state)
//             : _buildFullScreenView(state);
//       },
//     );
//   }
//
//   /// Builds the view for an outgoing video call when only the local stream is available.
//   Widget _buildOutgoingLocalOnlyView(CallBlocState state) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           Positioned.fill(
//             child:
//                 state.localStream != null
//                     ? RTCVideoView(_localRenderer)
//                     : Container(color: Colors.black),
//           ),
//           Positioned(
//             top: 40,
//             left: 20,
//             right: 20,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   _mapLifecycleStatusToText(state.lifecycleStatus),
//                   style: const TextStyle(color: Colors.white, fontSize: 18),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.call_end, color: Colors.red),
//                   onPressed: () {
//                     widget.callBloc.add(HangUpCallEvent());
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// Builds the incoming call view.
//   Widget _buildIncomingCallView(CallBlocState state) {
//     final bool isVideoCall = state.callMode == CallMode.video;
//     return Scaffold(
//       backgroundColor: Colors.blueGrey[900],
//       body: SafeArea(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // Caller info.
//             Column(
//               children: [
//                 const SizedBox(height: 40),
//                 CircleAvatar(
//                   radius: 50,
//                   backgroundImage: const NetworkImage("https://i.pravatar.cc/100"),
//                 ),
//                 const SizedBox(height: 16),
//                 const Text(
//                   "Incoming Call",
//                   style: TextStyle(color: Colors.white, fontSize: 24),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   isVideoCall ? "Video Call" : "Audio Call",
//                   style: const TextStyle(color: Colors.white70, fontSize: 18),
//                 ),
//               ],
//             ),
//             // Accept and Decline buttons.
//             Padding(
//               padding: const EdgeInsets.only(bottom: 40.0),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                 children: [
//                   FloatingActionButton(
//                     heroTag: 'declined',
//                     onPressed: () {
//                       widget.callBloc.add(
//                         DeclineIncomingCallEvent(reason: "declined by user"),
//                       );
//                     },
//                     backgroundColor: Colors.red,
//                     child: const Icon(Icons.call_end, size: 30),
//                   ),
//                   FloatingActionButton(
//                     heroTag: 'Call',
//                     onPressed: () {
//                       widget.callBloc.add(
//                         AcceptIncomingCallEvent(callMode: state.callMode),
//                       );
//                     },
//                     backgroundColor: Colors.green,
//                     child: const Icon(Icons.call, size: 30),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Builds the full-screen call UI when connected.
//   Widget _buildFullScreenView(CallBlocState state) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // Remote video or placeholder if remote camera is off.
//           Positioned.fill(
//             child:
//                 state.isVideoCall
//                     ? state.remoteStream != null && state.remoteCameraOn
//                         ? RTCVideoView(_remoteRenderer)
//                         : Container(
//                           color: Colors.black,
//                           child: const Center(
//                             child: Icon(
//                               Icons.videocam_off,
//                               color: Colors.white,
//                               size: 60,
//                             ),
//                           ),
//                         )
//                     : Container(),
//           ),
//           // Top bar: contact info and call status.
//           Positioned(
//             top: 40,
//             left: 20,
//             right: 20,
//             child: Column(
//               children: [
//                 const Text(
//                   "Contact Name",
//                   style: TextStyle(color: Colors.white, fontSize: 24),
//                 ),
//                 const SizedBox(height: 8),
//                 AnimatedSwitcher(
//                   duration: const Duration(milliseconds: 300),
//                   child: Text(
//                     _mapLifecycleStatusToText(state.lifecycleStatus),
//                     key: ValueKey(state.lifecycleStatus),
//                     style: const TextStyle(color: Colors.white70, fontSize: 16),
//                   ),
//                 ),
//                 if (state.lifecycleStatus == CallLifecycleStatus.connected)
//                   Text(
//                     _formatDuration(state.callDuration),
//                     style: const TextStyle(color: Colors.white70, fontSize: 16),
//                   ),
//               ],
//             ),
//           ),
//           // Draggable local video overlay.
//           Positioned(
//             top: 100,
//             right: 20,
//             child: Draggable(
//               feedback: _buildLocalVideoBox(state),
//               childWhenDragging: Container(),
//               onDragEnd: (details) {
//                 widget.callBloc.add(
//                   UIEvent(event: UIEventType.dragged, value: details.offset),
//                 );
//               },
//               child: _buildLocalVideoBox(state),
//             ),
//           ),
//           // Bottom call controls (visible when connected).
//           if (state.lifecycleStatus == CallLifecycleStatus.connected)
//             Positioned(bottom: 40, left: 0, right: 0, child: _buildCallControls(state)),
//           // Minimize button.
//           Positioned(
//             top: 40,
//             right: 20,
//             child: IconButton(
//               icon: const Icon(Icons.minimize, color: Colors.white),
//               onPressed: () {
//                 widget.callBloc.add(UIEvent(event: UIEventType.minimized));
//               },
//             ),
//           ),
//           // Error overlay.
//           if (state.lifecycleStatus == CallLifecycleStatus.failed ||
//               state.lifecycleStatus == CallLifecycleStatus.declined)
//             _buildErrorOverlay(),
//         ],
//       ),
//     );
//   }
//
//   /// Builds the minimized (floating) view.
//   Widget _buildMinimizedView(CallBlocState state) {
//     return Stack(
//       children: [
//         Positioned(
//           left: state.uiPosition.dx,
//           top: state.uiPosition.dy,
//           child: GestureDetector(
//             onPanUpdate: (details) {
//               final newOffset = state.uiPosition + details.delta;
//               widget.callBloc.add(UIEvent(event: UIEventType.dragged, value: newOffset));
//             },
//             onTap: () {
//               widget.callBloc.add(UIEvent(event: UIEventType.maximized));
//             },
//             child: Container(
//               width: 150,
//               height: 100,
//               decoration: BoxDecoration(
//                 color: Colors.black87,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Stack(
//                 children: [
//                   state.remoteStream != null && state.remoteCameraOn
//                       ? RTCVideoView(_remoteRenderer)
//                       : Container(color: Colors.black),
//                   Positioned(
//                     top: 5,
//                     left: 5,
//                     child: Text(
//                       _mapLifecycleStatusToText(state.lifecycleStatus),
//                       style: const TextStyle(color: Colors.white, fontSize: 12),
//                     ),
//                   ),
//                   const Positioned(
//                     bottom: 5,
//                     right: 5,
//                     child: Icon(Icons.call, color: Colors.white, size: 16),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Builds the local video box.
//   Widget _buildLocalVideoBox(CallBlocState state) {
//     return Container(
//       width: 120,
//       height: 160,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8),
//         color: Colors.grey,
//       ),
//       child: (state.localStream != null) ? RTCVideoView(_localRenderer) : Container(),
//     );
//   }
//
//   /// Builds the row of call control buttons.
//   Widget _buildCallControls(CallBlocState state) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//       children: [
//         IconButton(
//           icon: Icon(
//             Icons.volume_up,
//             color: state.localSpeakerOn ? Colors.white : Colors.grey,
//           ),
//           onPressed: _onToggleSpeaker,
//         ),
//         IconButton(
//           icon: const Icon(Icons.switch_camera, color: Colors.white),
//           onPressed: _onSwitchCamera,
//         ),
//         IconButton(
//           icon: Icon(
//             state.localCameraOn ? Icons.videocam : Icons.videocam_off,
//             color: Colors.white,
//           ),
//           onPressed: _onToggleCamera,
//         ),
//         IconButton(
//           icon: Icon(state.localMicOn ? Icons.mic : Icons.mic_off, color: Colors.white),
//           onPressed: _onToggleMic,
//         ),
//         IconButton(
//           icon: Icon(
//             Icons.screen_share,
//             color: state.localScreenShareOn ? Colors.white : Colors.grey,
//           ),
//           onPressed: _onToggleScreenShare,
//         ),
//         IconButton(
//           icon: const Icon(Icons.call_end, color: Colors.red),
//           onPressed: () async {
//             widget.callBloc.add(HangUpCallEvent());
//             if (mounted) {
//               Navigator.of(context).pop();
//             }
//           },
//         ),
//       ],
//     );
//   }
//
//   /// Builds an overlay to display when the call is failed or declined.
//   Widget _buildErrorOverlay() {
//     return Positioned.fill(
//       child: Container(
//         color: Colors.black54,
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.end,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: [
//                 IconButton(
//                   icon: const Icon(Icons.phone, color: Colors.green, size: 40),
//                   onPressed: () {
//                     widget.callBloc.add(RedialCallEvent());
//                   },
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.close, color: Colors.red, size: 40),
//                   onPressed: () {
//                     widget.callBloc.add(HangUpCallEvent());
//                   },
//                 ),
//               ],
//             ),
//             const SizedBox(height: 40),
//           ],
//         ),
//       ),
//     );
//   }
//
//   /// Maps the call lifecycle status to a user-friendly string.
//   String _mapLifecycleStatusToText(CallLifecycleStatus status) {
//     switch (status) {
//       case CallLifecycleStatus.calling:
//         return "Calling";
//       case CallLifecycleStatus.incoming:
//         return "Incoming";
//       case CallLifecycleStatus.ringing:
//         return "Ringing";
//       case CallLifecycleStatus.connecting:
//         return "Connecting";
//       case CallLifecycleStatus.connected:
//         return "Connected";
//       case CallLifecycleStatus.ended:
//         return "Ended";
//       case CallLifecycleStatus.declined:
//         return "Declined";
//       case CallLifecycleStatus.failed:
//         return "Failed";
//       default:
//         return "";
//     }
//   }
//
//   /// Formats a Duration into a mm:ss string.
//   String _formatDuration(Duration duration) {
//     final minutes = duration.inMinutes;
//     final seconds = duration.inSeconds % 60;
//     return "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
//   }
//
//   // --- UI Control Handlers: dispatch events to the bloc ---
//   void _onToggleMic() =>
//       widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.mic));
//
//   void _onToggleCamera() =>
//       widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.camera));
//
//   void _onToggleSpeaker() =>
//       widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.speaker));
//
//   void _onToggleScreenShare() async {
//     if (WebRTC.platformIsAndroid) {
//       // Android specific
//       Future<void> requestBackgroundPermission([bool isRetry = false]) async {
//         // Required for android screenShare.
//         try {
//           var hasPermissions = await FlutterBackground.hasPermissions;
//           if (!isRetry) {
//             const androidConfig = FlutterBackgroundAndroidConfig(
//               notificationTitle: 'Screen Sharing',
//               notificationText: 'you are sharing the screen.',
//               notificationImportance: AndroidNotificationImportance.normal,
//               notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
//             );
//             hasPermissions = await FlutterBackground.initialize(
//               androidConfig: androidConfig,
//             );
//           }
//           if (hasPermissions && !FlutterBackground.isBackgroundExecutionEnabled) {
//             await FlutterBackground.enableBackgroundExecution();
//           }
//         } catch (e) {
//           if (!isRetry) {
//             return await Future<void>.delayed(
//               const Duration(seconds: 1),
//               () => requestBackgroundPermission(true),
//             );
//           }
//           debugPrint('could not publish video: $e');
//         }
//       }
//
//       await requestBackgroundPermission();
//     }
//
//     widget.callBloc.add(ToggleLocalControlEvent(control: LocalControlType.screenShare));
//   }
//
//   void _onSwitchCamera() => widget.callBloc.add(SwitchCameraEvent());
//
//   /// Safely closes the call screen if it is still in the navigation stack.
//   void _closeCallScreen() {
//     if (mounted && Navigator.canPop(context)) {
//       Navigator.of(
//         context,
//       ).popUntil((route) => route.settings.name != CallContainerScreen.route);
//     }
//   }
//
//   // ------------------------------------------------------------------
// }
