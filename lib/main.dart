import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  CallCoordinator.instance.initialize();
  runApp(MyApp());
}

final globalNavigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: globalNavigatorKey,
      builder: (context, child) {
        return CallOverlay(child: child!,
        //     outgoingView: (context, bloc, state) {
        //   return Container(
        //     width: double.infinity,
        //     height: double.infinity,
        //     color: Colors.black87,
        //     child: Center(
        //       child: Column(
        //         crossAxisAlignment: CrossAxisAlignment.center,
        //         mainAxisAlignment: MainAxisAlignment.center,
        //         children: [
        //           Text("Test Builder"),
        //           Text(state.self.id),
        //           Text(state.callInfo.members.first.id),
        //
        //           CallControlOption(
        //             icon: const Icon(Icons.call_end_rounded),
        //             iconColor: Colors.white,
        //             backgroundColor: Colors.red,
        //             onPressed: () =>
        //                bloc.add(HangUpCallEvent()),
        //             padding: const EdgeInsets.all(24),
        //           ),
        //         ],
        //       ),
        //     ),
        //   );
        // }
        );
      },
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('[HomeScreen] build');
    return Scaffold(
      appBar: AppBar(title: Text('Universal Call Overlay Example')),
      body: Center(
        child: ElevatedButton(
          child: Text("Start New Call"),
          onPressed: () => CallCoordinator.instance.simulateCall(),
        ),
      ),
    );
  }
}





// class DraggableCallWidget extends StatefulWidget {
//   final CallContext callContext;
//
//   const DraggableCallWidget({super.key, required this.callContext});
//
//   @override
//   State<DraggableCallWidget> createState() => _DraggableCallWidgetState();
// }
//
// class _DraggableCallWidgetState extends State<DraggableCallWidget> {
//   OverlayStatus overlayState = OverlayStatus.minimized;
//   Timer? revertTimer;
//   Offset position = Offset(20, 100);
//   late Timer _timer;
//   late Duration duration;
//
//   @override
//   void initState() {
//     super.initState();
//     _updateDuration();
//     _timer = Timer.periodic(Duration(seconds: 1), (_) => _updateDuration());
//   }
//
//   void _updateDuration() {
//     setState(() {
//       duration = DateTime.now().difference(widget.callContext.startTime);
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final onHoldCount = CallCoordinator.instance.onHoldCount;
//     return widget.callContext.isMinimize ? _buildMiniOverlay()
//         : _buildFullScreen(onHoldCount);
//   }
//
//   Widget _buildFullScreen(int onHoldCount) {
//     return Positioned.fill(
//       child: Material(
//         color: Colors.black,
//         child: Stack(
//           children: [
//             Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   ClipOval(
//                     child: Image.network(
//                         widget.callContext.avatarUrl, width: 150,
//                         height: 150,
//                         fit: BoxFit.cover),
//                   ),
//                   SizedBox(height: 20),
//                   Text(_formatDuration(),
//                       style: TextStyle(color: Colors.white, fontSize: 24)),
//                   if (onHoldCount > 0)
//                     Padding(
//                       padding: const EdgeInsets.only(top: 20),
//                       child: ElevatedButton(
//                         child: Text("Close $onHoldCount on-hold calls"),
//                         onPressed: () =>
//                             CallCoordinator.instance.closeAllOnHold(),
//                       ),
//                     ),
//                 ],
//               ),
//             ),
//             Positioned(top: 30, left: 30, child: _endCallButton()),
//             Positioned(top: 30, right: 30, child: _minimizeButton()),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildMiniOverlay() {
//     final screenHeight = MediaQuery
//         .sizeOf(context)
//         .height;
//     final screenWidth = MediaQuery
//         .sizeOf(context)
//         .width;
//     final isOnLeftScreen = position.dx < screenWidth / 2;
//     var isCollapsed = overlayState == OverlayStatus.collapsed;
//     final topLimit = 60.0;
//     final bottomLimit = screenHeight - _getHeightForState();
//     final rightLimit = screenWidth - _getWidthForState();
//     final collHeight = _getHeightForState(state: OverlayStatus.collapsed);
//
//     final left = isOnLeftScreen ? position.dx : null;
//     final right = isOnLeftScreen ? null : rightLimit - position.dx;
//
//     return Positioned(
//       top: position.dy,
//       left: left,
//       right: right,
//       child: GestureDetector(
//         onPanUpdate: (details) =>
//             setState(() {
//               final newPosition = position + details.delta;
//
//               var newDx = newPosition.dx.clamp(0.0, screenWidth);
//               var newDy = newPosition.dy.clamp(topLimit, bottomLimit);
//
//               position = Offset(isCollapsed ? position.dx : newDx, newDy);
//
//               if (isCollapsed) {
//                 return;
//               }
//
//               var isOnLeft = position.dx <= 0.0;
//               var isOnRight = position.dx >= rightLimit;
//               var sizeDiff = (_getHeightForState() - collHeight) / 2;
//               newDy = newDy + sizeDiff;
//
//               if (isOnLeft) {
//                 overlayState = OverlayStatus.collapsed;
//                 position = Offset(0.0, newDy);
//               } else if (isOnRight) {
//                 overlayState = OverlayStatus.collapsed;
//                 position = Offset(
//                     screenWidth - _getWidthForState(), newDy);
//               }
//             }),
//         onTap: () =>
//             setState(() {
//               if (overlayState == OverlayStatus.minimized ||
//                   overlayState == OverlayStatus.collapsed) {
//                 overlayState = OverlayStatus.intermediate;
//
//                 final sizeDiff = (_getHeightForState() - collHeight) / 2;
//                 final newDy = position.dy - sizeDiff;
//                 final screenLimit = screenWidth - _getWidthForState();
//                 final newDx = isOnLeftScreen ? position.dx : screenLimit;
//
//                 position = Offset(newDx, newDy);
//                 _resetTimerToMinimized();
//               } else if (overlayState == OverlayStatus.intermediate) {
//                 widget.callContext.isMinimize = false;
//               }
//             }),
//         child: AnimatedContainer(
//           width: _getWidthForState(),
//           height: _getHeightForState(),
//           duration: Duration(milliseconds: 200),
//           decoration: BoxDecoration(
//               color: Colors.blueGrey, borderRadius: BorderRadius.circular(16)),
//           child: _buildContentForState(),
//         ),
//       ),
//     );
//   }
//
//   Widget _endCallButton() {
//     return FloatingActionButton(
//       mini: true,
//       backgroundColor: Colors.red,
//       child: Icon(Icons.close),
//       onPressed: () =>
//           CallCoordinator.instance.endCall(widget.callContext.callId),
//     );
//   }
//
//   Widget _minimizeButton() {
//     return FloatingActionButton(
//       mini: true,
//       backgroundColor: Colors.blueGrey,
//       child: Icon(Icons.minimize),
//       onPressed: () {
//         setState(() {
//           widget.callContext.isMinimize = true;
//           CallCoordinator.instance.updateCallState();
//         });
//       },
//     );
//   }
//
//   Widget _maximizeButton() {
//     return FloatingActionButton(
//       mini: true,
//       backgroundColor: Colors.blueGrey,
//       child: Icon(Icons.open_in_full),
//       onPressed: () {
//         setState(() {
//           widget.callContext.isMinimize = false;
//           CallCoordinator.instance.updateCallState();
//         });
//       },
//     );
//   }
//
//   String _formatDuration() {
//     final hours = duration.inHours.remainder(24).toString().padLeft(2, '0');
//     final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
//     final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
//     return "$hours:$minutes:$seconds";
//   }
//
//   double _getWidthForState({OverlayStatus? state}) {
//     switch (state ?? overlayState) {
//       case OverlayStatus.minimized:
//         return 150;
//       case OverlayStatus.intermediate:
//         return 200;
//       case OverlayStatus.collapsed:
//         return 50;
//     }
//   }
//
//   double _getHeightForState({OverlayStatus? state}) {
//     switch (state ?? overlayState) {
//       case OverlayStatus.minimized:
//         return 200;
//       case OverlayStatus.intermediate:
//         return 250;
//       case OverlayStatus.collapsed:
//         return 100;
//     }
//   }
//
//   Widget _buildContentForState() {
//     switch (overlayState) {
//       case OverlayStatus.minimized:
//       case OverlayStatus.intermediate:
//         return Stack(
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(16),
//               child: Image.network(
//                   widget.callContext.avatarUrl, fit: BoxFit.cover),
//             ),
//             Positioned(
//               bottom: 4,
//               left: 4,
//               right: 4,
//               child: Container(
//                 color: Colors.black54,
//                 child: Text(_formatDuration(), textAlign: TextAlign.center,
//                     style: TextStyle(color: Colors.white, fontSize: 12)),
//               ),
//             ),
//             Positioned(top: 4, left: 4, child: _endCallButton()),
//             Positioned(top: 4, right: 4, child: _maximizeButton()),
//           ],
//         );
//       case OverlayStatus.collapsed:
//         bool isOnLeft = position.dx <= 0;
//         return Center(
//           child: Icon(
//             isOnLeft ? Icons.arrow_forward_ios : Icons.arrow_back_ios,
//             color: Colors.white,
//           ),
//         );
//     }
//   }
//
//   void _resetTimerToMinimized() {
//     revertTimer?.cancel();
//     revertTimer = Timer(Duration(seconds: 5), () {
//       if (mounted && overlayState == OverlayStatus.intermediate) {
//         setState(() {
//           overlayState = OverlayStatus.minimized;
//         });
//       }
//     });
//   }
// }


// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_rtc/flutter_rtc.dart';
//
// /// Generates a random 6-digit client ID.
// String generate6DigitClientId() {
//   final random = Random();
//   final number = random.nextInt(10);
//   return number.toString();
// }
//
// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   CallCoordinator.instance.initialize();
//
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return FlutterRTCWidget(
//       navigatorKey: GlobalKey<NavigatorState>(),
//       child: HomeScreen(),
//     );
//   }
// }
//
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({super.key});
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   final TextEditingController _callIdController = TextEditingController();
//
//   final clientId = generate6DigitClientId();
//
//   @override
//   void initState() {
//     super.initState();
//     SystemChannels.textInput.invokeMethod('TextInput.hide');
//   }
//
//   @override
//   void dispose() {
//     _callIdController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // final flutterRTC = FlutterRTCWidget.of(context);
//
//     CallCoordinator.instance.onGlobalEvent.listen((event) {
//       if (event is SignalingEvent && event.type == SignalingEventType.connected) {
//         CallCoordinator.instance.registerUser(clientId);
//       }
//     });
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('RTC Demo')),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           children: [
//             Text(
//               'Client ID: $clientId',
//               style: TextStyle(
//                 decoration: TextDecoration.none,
//                 fontSize: 20,
//                 color: Colors.black,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 20),
//             TextField(
//               controller: _callIdController,
//               decoration: const InputDecoration(
//                 labelText: 'Call ID (target) or Group call user1:user2',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: <Widget>[
//                 ElevatedButton(
//                   onPressed: () {
//                     final targetId = _callIdController.text.trim();
//                     if (targetId.isNotEmpty) {
//                       CallCoordinator.instance.startSingleCall(
//                         clientId,
//                         targetId,
//                         mode: CallMode.video,
//                       );
//                     }
//                   },
//                   child: const Text('Make Video Call'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     final targetId = _callIdController.text.trim();
//                     if (targetId.isNotEmpty) {
//                       CallCoordinator.instance.startSingleCall(clientId, targetId);
//                     }
//                   },
//                   child: const Text('Make Audio Call'),
//                 ),
//               ],
//             ),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//               children: <Widget>[
//                 ElevatedButton(
//                   onPressed: () {
//                     CallCoordinator.instance.clearAllSessions();
//                   },
//                   child: const Text('Clear All Sessions'),
//                 ),
//                 ElevatedButton(
//                   onPressed: () {
//                     final targetId = _callIdController.text.trim().split(":");
//                     if (targetId.isNotEmpty) {
//                       CallCoordinator.instance.startCall(
//                         userId: clientId,
//                         members: [
//                           Member(userId: targetId.first),
//                           Member(userId: targetId.last),
//                         ],
//                       );
//                     }
//                   },
//                   child: const Text('Group Call'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
