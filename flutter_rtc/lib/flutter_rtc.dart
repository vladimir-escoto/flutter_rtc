import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rtc/src/bloc/call_enums.dart';
import 'package:flutter_rtc/src/bloc/call_event.dart';
import 'flutter_rtc.dart';
import 'src/bloc/call_bloc.dart';

export 'src/call_manager.dart';
export 'src/signaling/mqtt_signaling.dart';
export 'src/signaling/signaling_configuration.dart';
export 'src/signaling/signaling_event.dart';
export 'src/signaling/signaling_interface.dart';
export 'src/ui/call_screen.dart';
export 'src/ui/flutter_rtc_widget.dart';

class FlutterRTC {
  late final SignalingInterface signaling;
  late final CallManager callManager;
  late final CallBloc callBloc;
  final GlobalKey<NavigatorState> navigatorKey;

  FlutterRTC({
    required String clientId,
    SignalingInterface? customSignaling,
    GlobalKey<NavigatorState>? navigatorKey,
  }) : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
    signaling =
        customSignaling ??
        MQTTSignaling(
          config: SignalingConfiguration(
            brokerUrl: 'test.mosquitto.org',
            clientId: clientId,
          ),
          // config: SignalingConfiguration(brokerUrl: 'broker.hivemq.com', clientId: clientId),
          // config: SignalingConfiguration(brokerUrl: 'broker.emqx.io', clientId: clientId),
        );
    callManager = CallManager(signaling: signaling, clientId: clientId);
    callBloc = CallBloc(callManager: callManager);
  }

  /// Initializes the signaling and sets up incoming call listeners.
  Future<void> initialize(BuildContext context) async {
    await callManager.setupSignalingEventsListener();
    await signaling.connect();

    callManager.callEvents.listen((event) {
      if (event == CallLifecycleStatus.incoming) {
        _showCallScreen();
      }
    });
  }

  /// Initiates an outgoing call and navigates to the call UI.
  Future<void> makeVideCall(String targetPeerId) async {
    callBloc.add(
      StartOutgoingCallEvent(targetPeerId: targetPeerId, callMode: CallMode.video),
    );
    await _showCallScreen();
  }

  Future<void> makeAudioCall(String targetPeerId) async {
    callBloc.add(
      StartOutgoingCallEvent(targetPeerId: targetPeerId, callMode: CallMode.audio),
    );
    await _showCallScreen();
  }

  // Navigate to the call UI using the internal navigator.
  // This ensures that the call screen is displayed regardless of where
  // the user is in the app's navigation.
  Future<void> _showCallScreen() async {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        settings: RouteSettings(name: EnhancedCallScreen.route),
        builder:
            (_) => BlocProvider.value(
              value: callBloc,
              child: EnhancedCallScreen(callBloc: callBloc),
            ),
      ),
    );
  }

  /// Hangs up the call and resets the navigation.
  Future<void> hangUp() async {
    callBloc.add(HangUpCallEvent());
  }
}
