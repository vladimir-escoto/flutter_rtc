import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
        return CallOverlay(
          child: child!,
          // outgoingView: (context, bloc, state) =>
          //     CustomCallScreen(bloc: bloc, state: state)
        );
      },
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _callIdController = TextEditingController(
    text: "7",
  );
  String? errorMessage;
  bool get isConnected => CallCoordinator.instance.isSignalingConnected;
  String? _clientId;

  @override
  void initState() {
    super.initState();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
    _loadClientId();

    CallCoordinator.instance.onGlobalEvent.listen((event) async {
      if (event is SignalingEvent) {
        if (event.type == SignalingEventType.error) {
          setState(() {
            errorMessage = event.data;
          });
          return;
        }

        if (event.type == SignalingEventType.connected) {
          CallCoordinator.instance.registerUser(await ClientPreferences.getClientId());
        }
      }
    });
  }

  Future<void> _loadClientId() async {
    final id = await ClientPreferences.getClientId();
    setState(() {
      _clientId = id;
    });
  }

  @override
  void dispose() {
    _callIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const Text('RTC Demo'),
            Text(
              isConnected ? 'Connected' : 'Disconnected',
              style: TextStyle(
                decoration: TextDecoration.none,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child:
            _clientId == null
                ? CircularProgressIndicator()
                : _buildHomeScreen(context, _clientId!),
      ),
    );
  }

  Widget _buildHomeScreen(BuildContext context, String clientId) {


    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          if (errorMessage != null)
            GestureDetector(
              onTap: () {
                setState(() {
                  errorMessage = null;
                });
              },
              child: Text(
                  'Error: $errorMessage',
                  style: TextStyle(
                    decoration: TextDecoration.none,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            ),
          Text(
            'Client ID: $clientId',
            style: TextStyle(
              decoration: TextDecoration.none,
              fontSize: 20,
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _callIdController,
            decoration: const InputDecoration(
              labelText: 'Call ID (target) or Group call user1:user2',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 10,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.startSingleCall(
                        clientId,
                        targetId.first,
                        mode: CallMode.video,
                      );
                    }
                  },
                  child: const Text('Make Video Call'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.startSingleCall(
                          clientId, targetId.first);
                    }
                  },
                  child: const Text('Make Audio Call'),
                ),
              ),
            ],
          ),
          //--------------------------------------------------------------------
          Container(
            margin: EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(border: Border.symmetric(
                horizontal: BorderSide(color: Colors.black12))),),
          //--------------------------------------------------------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 10,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.startCall(
                        mode: CallMode.video,
                        userId: clientId,
                        members: targetId.map((id) => Member(id: id)).toList(),
                      );
                    }
                  },
                  child: const Text('Group Video Call'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    if (targetId.isNotEmpty) {
                      CallCoordinator.instance.startCall(
                        mode: CallMode.audio,
                        userId: clientId,
                        members: targetId.map((id) => Member(id: id)).toList(),
                      );
                    }
                  },
                  child: const Text('Group Audio Call'),
                ),
              ),
            ],
          ),
          Container(margin: EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(border: Border.symmetric(
                horizontal: BorderSide(color: Colors.black12))),),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    CallCoordinator.instance.simulateCall(
                      userId: clientId,
                      members: targetId.map((id) => Member(id: id)).toList(),
                      state: CallLifeCycleStatus.active,
                    );
                  },
                  child: const Text('Simulate Active'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    CallCoordinator.instance.simulateCall(
                      userId: clientId,
                      members: targetId.map((id) => Member(id: id)).toList(),
                      state: CallLifeCycleStatus.failed,
                    );
                  },
                  child: const Text('Simulate Error'),
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    CallCoordinator.instance.simulateCall(
                      userId: clientId,
                      members: targetId.map((id) => Member(id: id)).toList(),
                      state: CallLifeCycleStatus.declined,
                    );
                  },
                  child: const Text('Simulate Declined'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    CallCoordinator.instance.simulateCall(
                      userId: clientId,
                      members: targetId.map((id) => Member(id: id)).toList(),
                      state: CallLifeCycleStatus.hold,
                    );
                  },
                  child: const Text('Simulate Hold'),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    CallCoordinator.instance.simulateCall(
                      userId: clientId,
                      members: targetId.map((id) => Member(id: id)).toList(),
                      state: CallLifeCycleStatus.incoming,
                    );
                  },
                  child: const Text('Simulate Incoming'),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    final targetId = _callIdController.text.trim().split(":");
                    CallCoordinator.instance.simulateCall(
                      userId: clientId,
                      members: targetId.map((id) => Member(id: id)).toList(),
                      state: CallLifeCycleStatus.ringing,
                    );
                  },
                  child: const Text('Simulate calling'),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  CallCoordinator.instance.clearAllSessions();
                },
                child: const Text('Clear All Sessions'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
