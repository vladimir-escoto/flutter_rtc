import 'package:flutter/material.dart';
import 'package:flutter_rtc/flutter_rtc.dart';

import 'chat_input_test_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  //CallCoordinator.instance.initialize();
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
        return CallOverlay(
          child: child!,
          // outgoingView: (context, bloc, state) =>
          //     CustomCallScreen(bloc: bloc, state: state)
        );
      },
      home: ChatInputTestScreen(),
    );
  }
}
