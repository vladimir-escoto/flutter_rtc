import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';
import 'package:flutter_rtc/src/signaling/mqtt_signaling.dart';
import 'package:uuid/uuid.dart';

// export 'src/signaling/mqtt_signaling.dart';
// export 'src/signaling/signaling_configuration.dart';
export 'src/ui/call_container_screen.dart';
export 'src/ui/flutter_rtc_widget.dart';
export 'package:flutter_rtc/src/coordinator/call_coordinator.dart';
export 'package:flutter_rtc/src/context/call_context.dart';
export 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
export 'package:flutter_rtc/src/signaling/signaling_interface.dart';


// class FlutterRTC {
//   late final ISignaling signaling;
//   final GlobalKey<NavigatorState> navigatorKey;
//
//   FlutterRTC({ISignaling? signaling, GlobalKey<NavigatorState>? navigatorKey})
//     : navigatorKey = navigatorKey ?? GlobalKey<NavigatorState>() {
//     signaling =
//         signaling ??
//         MQTTSignaling(
//           config: SignalingConfiguration(
//             brokerUrl: 'broker.triplecyber.com',
//             clientId: Uuid().v4(),
//           ),
//         );
//   }
//
//   /// Initializes the signaling and sets up incoming call listeners.
//   Future<void> initialize(BuildContext context) async {
//
//   }
//
//   /// Initiates an outgoing call and navigates to the call UI.
//   Future<void> makeVideCall(String targetPeerId) async {
//
//
//     await _showCallScreen();
//   }
//
//   Future<void> makeAudioCall(String targetPeerId) async {
//
//     await _showCallScreen();
//   }
//
//   // Navigate to the call UI using the internal navigator.
//   // This ensures that the call screen is displayed regardless of where
//   // the user is in the app's navigation.
//   Future<void> _showCallScreen() async {
//     // navigatorKey.currentState?.push(
//     //   MaterialPageRoute(
//     //     settings: RouteSettings(name: CallContainerScreen.route),
//     //     builder:
//     //         (_) => BlocProvider.value(
//     //           value: callBloc,
//     //           child: CallContainerScreen(callBloc: callBloc),
//     //         ),
//     //   ),
//     // );
//   }
//
// }
