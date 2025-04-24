import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/coordinator/call_coordinator.dart';

import '../../flutter_rtc.dart';

class FlutterRTCWidget extends StatefulWidget {
  final String clientId;
  final Widget child;
  final GlobalKey<NavigatorState> navigatorKey;

  const FlutterRTCWidget({
    super.key,
    required this.clientId,
    required this.child,
    required this.navigatorKey,
  });

  @override
  FlutterRTCWidgetState createState() => FlutterRTCWidgetState();

  /// Static method to access the FlutterRTC instance from descendant widgets.
  static FlutterRTC? of(BuildContext context) {
    final state = context.findAncestorStateOfType<FlutterRTCWidgetState>();
    return state?.flutterRTC;
  }
}

class FlutterRTCWidgetState extends State<FlutterRTCWidget> {
  late final FlutterRTC flutterRTC;
  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    flutterRTC = FlutterRTC(clientId: widget.clientId, navigatorKey: widget.navigatorKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flutterRTC.signaling.events.listen((event) {
        if (event.type == SignalingEventType.connected) {
          setState(() {
            isConnected = true;
          });
        } else if (event.type == SignalingEventType.disconnected) {
          setState(() {
            isConnected = false;
          });
        }
      });

      flutterRTC.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if there is already a MaterialApp in the widget tree.
    final hasMaterialApp = context.findAncestorWidgetOfExactType<MaterialApp>() != null;

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
        : MaterialApp(navigatorKey: flutterRTC.navigatorKey, home: body);
  }
}
