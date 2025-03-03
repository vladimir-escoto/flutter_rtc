import 'package:flutter/material.dart';

import '../../flutter_rtc.dart';

class FlutterRTCWidget extends StatefulWidget {
  final String clientId;
  final Widget child;

  const FlutterRTCWidget({super.key, required this.clientId, required this.child});

  @override
  FlutterRTCWidgetState createState() => FlutterRTCWidgetState();

  static FlutterRTC? of(BuildContext context) {
    final state = context.findAncestorStateOfType<FlutterRTCWidgetState>();
    return state?.flutterRTC;
  }
}

class FlutterRTCWidgetState extends State<FlutterRTCWidget> {
  late final FlutterRTC flutterRTC;

  @override
  void initState() {
    super.initState();
    flutterRTC = FlutterRTC(clientId: widget.clientId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flutterRTC.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: flutterRTC.navigatorKey,
      home: widget.child,
    );
  }
}
