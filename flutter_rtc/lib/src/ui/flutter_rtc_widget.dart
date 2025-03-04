// lib/src/ui/flutter_rtc_widget.dart
import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    flutterRTC = FlutterRTC(
        clientId: widget.clientId, navigatorKey: widget.navigatorKey);
    // Inicia la librería; el contexto se usará para configurar listeners, etc.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      flutterRTC.initialize(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Check if there is already a MaterialApp in the widget tree.
    final hasMaterialApp = context.findAncestorWidgetOfExactType<
        MaterialApp>() != null;
    // If not, wrap the child in a MaterialApp.
    return hasMaterialApp ? widget.child : MaterialApp(
        navigatorKey: flutterRTC.navigatorKey,
        home: widget.child);
  }
}
