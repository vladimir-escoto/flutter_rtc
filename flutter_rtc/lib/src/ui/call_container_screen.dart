import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/flutter_rtc.dart';
import 'package:flutter_rtc/src/call_overlay_Manager.dart';
import 'package:flutter_rtc/src/ui/call_renderer_mixin.dart';
import 'package:flutter_rtc/src/ui/call_timer_mixin.dart';
import 'package:flutter_rtc/src/ui/widgets/call_duration_text.dart';
import 'package:flutter_rtc/src/ui/widgets/call_members_view.dart';
import 'package:flutter_rtc/src/ui/widgets/floating_draggable_widget.dart';
import 'package:flutter_rtc/src/ui/widgets/remote_members_carousel.dart';
import 'package:flutter_rtc/src/ui/widgets/video_box.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

part 'call_container_screen/base_call_screen.dart';

part 'call_container_screen/decline_call_view.dart';

part 'call_container_screen/error_call_View.dart';

part 'call_container_screen/full_screen_call_view.dart';

part 'call_container_screen/hold_call_view.dart';

part 'call_container_screen/incoming_call_view.dart';

part 'call_container_screen/minimized_call_view.dart';

part 'call_container_screen/outgoing_call_view.dart';

part 'widgets/call_control_option.dart';

part 'widgets/call_overlay.dart';

part 'widgets/call_status_widget.dart';

part 'widgets/full_screen_call_controls.dart';

part 'widgets/incoming_call_controls.dart';

part 'widgets/outgoing_call_controls.dart';

part 'widgets/decline_call_controls.dart';

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
  final CallViewBuilder? holdView;
  final CallViewBuilder? minimizedView;
  final CallViewBuilder? errorView;

  const CallContainerScreen({
    super.key,
    required this.callBloc,
    this.outgoingView,
    this.incomingView,
    this.activeCallView,
    this.endedView,
    this.declineView,
    this.minimizedView,
    this.holdView,
    this.errorView,
  });

  @override
  State<CallContainerScreen> createState() => _CallContainerScreenState();
}

class _CallContainerScreenState extends State<CallContainerScreen>
    with CallRendererMixin {
  @override
  void initState() {
    super.initState();
    FocusManager.instance.primaryFocus?.unfocus(); // hidden keyboard here
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CallBloc, CallBlocState>(
      bloc: widget.callBloc,
      builder: (context, state) {
        updateRenderers(state);
        if (state.isUiMinimized) {
          return _buildMinimized(context, widget.callBloc, state);
        }
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
          case CallLifeCycleStatus.hold:
            return _buildHoldView(context, widget.callBloc, state);
          case CallLifeCycleStatus.initial:
          case CallLifeCycleStatus.ended:
            return const SizedBox.shrink();
        }
      },
    );
  }

  // Default fallback UIs
  Widget _buildHoldView(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.holdView?.call(context, bloc, state) ??
      HoldCallView(callBloc: bloc, state: state);

  Widget _buildMinimized(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.minimizedView?.call(context, bloc, state) ??
      MinimizedCallView(callBloc: bloc, state: state, renderer: activeRenderer(state));

  Widget _buildOutgoing(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.outgoingView?.call(context, bloc, state) ??
      OutgoingCallView(callBloc: bloc, state: state, localRenderer: localRenderer);

  Widget _buildIncoming(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.incomingView?.call(context, bloc, state) ??
      IncomingCallView(callBloc: bloc, state: state, localRenderer: localRenderer);

  Widget _buildActive(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.activeCallView?.call(context, bloc, state) ??
      FullScreenCallView(
        callBloc: bloc,
        state: state,
        localRenderer: localRenderer,
        remoteRenderer: renderers,
      );

  Widget _buildDecline(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.declineView?.call(context, bloc, state) ??
      DeclineCallView(callBloc: bloc, state: state, localRenderer: localRenderer);

  Widget _buildError(BuildContext context, CallBloc bloc, CallBlocState state) =>
      widget.errorView?.call(context, bloc, state) ??
      CallErrorView(callBloc: bloc, state: state);
}
