import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/signaling/signaling_interface.dart';

import '../coordinator/call_coordinator.dart';

class FlutterRTCWidget extends StatefulWidget {
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const FlutterRTCWidget({super.key, required this.child, required this.navigatorKey});

  @override
  FlutterRTCWidgetState createState() => FlutterRTCWidgetState();

  // /// Static method to access the FlutterRTC instance from descendant widgets.
  // static FlutterRTC? of(BuildContext context) {
  //   final state = context.findAncestorStateOfType<FlutterRTCWidgetState>();
  //   return state?.flutterRTC;
  // }
}

class FlutterRTCWidgetState extends State<FlutterRTCWidget> {
  // late final FlutterRTC flutterRTC;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      CallCoordinator.instance.onGlobalEvent.listen((event) {
        if (event is SignalingEvent) {
          if (event.type == SignalingEventType.error) return;

          setState(() {
            isConnected = event.type == SignalingEventType.connected;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if there is already a MaterialApp in the widget tree.
    final hasMaterialApp = context.findAncestorWidgetOfExactType<MaterialApp>() != null;
    //
    Widget body = Stack(
      children: [
        widget.child,
        Positioned(
          top: 60,
          right: 2,
          child: Text(
            "MQTT ${isConnected ? "Connected" : "Disconnected"}",
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
    // If not, wrap the child in a MaterialApp.
    return hasMaterialApp
        ? body
        : MaterialApp(navigatorKey: widget.navigatorKey, home: body);
  }
}
