import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/src/call_overlay_Manager.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/ui/call_timer_mixin.dart';
import 'package:flutter_rtc/src/ui/widgets/call_duration_text.dart';
import 'package:flutter_rtc/src/ui/widgets/floating_draggable_renderer_widget.dart';
import 'package:flutter_rtc/src/ui/widgets/floating_draggable_widget.dart';
import 'package:flutter_rtc/src/ui/widgets/video_box.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../context/model/member.dart';

part 'call_container_screen/full_screen_call_view.dart';

part 'call_container_screen/decline_call_view.dart';

part 'call_container_screen/minimized_call_view.dart';

part 'call_container_screen/incoming_call_view.dart';

part 'call_container_screen/outgoing_call_view.dart';

part 'widgets/call_control_option.dart';

part 'widgets/call_overlay.dart';

part 'widgets/call_status_widget.dart';

part 'widgets/incoming_call_controls.dart';

part 'widgets/outgoing_call_controls.dart';

part 'widgets/full_screen_call_controls.dart';

typedef ControlHandler = void Function();
typedef DragUpdateHandler = void Function(Offset);
typedef CallViewBuilder =
    Widget Function(BuildContext context, CallBloc bloc, CallBlocState state);

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
  final Map<String, RTCVideoRenderer> _remoteRenderer = {};

  @override
  void initState() {
    super.initState();
    _initializeRenderer(widget.callBloc.state);
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    for (var renderer in _remoteRenderer.values) {
      renderer.dispose();
    }
    _remoteRenderer.clear();
    super.dispose();
  }

  RTCVideoRenderer get activeRenderer {
    //TODO: Replace with Active remote renderer, only one render in minimized view
    var state = widget.callBloc.state;
    var firstId = state.callInfo.remoteMembers.first.id;
    final renderer = _remoteRenderer.putIfAbsent(firstId, () {
      return RTCVideoRenderer();
    });
    return renderer;
  }

  Future<void> _initializeRenderer(CallBlocState state) async {
    await _localRenderer.initialize();

    for (var member in state.callInfo.remoteMembers) {
      final renderer = _remoteRenderer.putIfAbsent(member.id, () {
        return RTCVideoRenderer();
      });

      await renderer.initialize();
      _updateRenderer(member, renderer, state.isVideoCall);
    }
  }

  Future<void> _updateRenderer(
    Member member,
    RTCVideoRenderer render,
    bool isVideo,
  ) async {
    if (!isVideo) {
      // If it's not a video track, clear any video src
      if (render.srcObject != null) {
        render.srcObject = null;
      }
      return;
    }

    // 2. Video case
    if (member.cameraEnabled) {
      // Assign only if it's different
      if (render.srcObject != member.mediaStream) {
        render.srcObject = member.mediaStream;
      }
    } else {
      // Disable video: clear srcObject
      if (render.srcObject != null) {
        render.srcObject = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc, CallBlocState>(
      bloc: widget.callBloc,
      builder: (context, state) {
        _initializeRenderer(state);
        switch (state.lifecycleStatus) {
          case CallLifeCycleStatus.incoming:
            return _buildIncoming(context, widget.callBloc, state);
          case CallLifeCycleStatus.calling:
          case CallLifeCycleStatus.ringing:
            return _buildOutgoing(context, widget.callBloc, state);
          case CallLifeCycleStatus.active:
            return _buildActive(context, widget.callBloc, state);
          case CallLifeCycleStatus.failed:
            return _buildError(context, widget.callBloc, state);
          case CallLifeCycleStatus.declined:
            return _buildDecline(context, widget.callBloc, state);
          default:
            return _buildOtherState(context, widget.callBloc, state);
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
    if (widget.activeCallView == null) {
      if (state.isUiMinimized) {
        return MinimizedCallView(
          callBloc: bloc,
          state: state,
          activeRenderer: activeRenderer,
        );
      } else {
        return FullScreenCallView(
          callBloc: bloc,
          state: state,
          localRenderer: _localRenderer,
          activeRenderer: activeRenderer,
        );
      }
    } else {
      return widget.activeCallView!.call(context, bloc, state);
    }
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

  Widget _buildOtherState(BuildContext context, CallBloc bloc, CallBlocState state) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(
              iconSize: 60,
              icon: Icon(Icons.minimize, color: Colors.white),
              onPressed:
                  () => widget.callBloc.add(
                    UIEvent(
                      event: UIEventType.changeOverlay,
                      value: OverlayStatus.minimized,
                    ),
                  ),
            ),
            Text(
              "UnkHandle state: [${state.lifecycleStatus.name.toUpperCase()}]",
              style: const TextStyle(color: Colors.white, fontSize: 20.0),
            ),
            FullScreenCallControls(
              isScreenShareEnabled: state.localScreenShareOn,
              isMicrophoneEnabled: state.localMicOn,
              isCameraEnabled: state.localCameraOn,
              isSpeakerEnabled: state.localSpeakerOn,
              onScreenShareTap:
                  () => widget.callBloc.add(
                    ToggleLocalControlEvent(control: LocalControlType.screenShare),
                  ),
              onCancelCallTap: () => widget.callBloc.add(HangUpCallEvent()),
              onMicrophoneTap:
                  () => widget.callBloc.add(
                    ToggleLocalControlEvent(control: LocalControlType.mic),
                  ),
              onCameraTap:
                  () => widget.callBloc.add(
                    ToggleLocalControlEvent(control: LocalControlType.camera),
                  ),
              onSpeakerTap:
                  () => widget.callBloc.add(
                    ToggleLocalControlEvent(control: LocalControlType.speaker),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
