import 'dart:async';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';

enum CallKitEvent { accepted, declined }

class CallKitManager {
  final StreamController<CallKitEvent> _callKitEventController =
      StreamController.broadcast();

  Stream<CallKitEvent> get callKitEvents => _callKitEventController.stream;

  /// Displays the incoming call notification.
  Future<void> showIncomingCall({
    required String callId,
    required String callerName,
    Map<String, dynamic>? body = const {},
    Map<String, dynamic>? headers = const {},
    int type = 0,
  }) async {
    final params = CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Tr3sPass',
      avatar: 'https://i.pravatar.cc/100',
      type: type,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      extra: body,
      headers: headers,
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: true,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        backgroundUrl: 'assets/test.png',
        actionColor: '#4CAF50',
        textColor: '#ffffff',
      ),
      ios: const IOSParams(
        iconName: 'AppIcon',
        handleType: '',
        supportsVideo: true,
        maximumCallGroups: 2,
        maximumCallsPerCallGroup: 1,
        audioSessionMode: 'voiceChat',
        audioSessionActive: false,
        audioSessionPreferredSampleRate: 44100.0,
        audioSessionPreferredIOBufferDuration: 0.005,
        supportsDTMF: true,
        supportsHolding: true,
        supportsGrouping: false,
        supportsUngrouping: false,
        ringtonePath: 'system_ringtone_default',
        configureAudioSession: false,
      ),
    );

    // Subscribe to native CallKit events.
    FlutterCallkitIncoming.onEvent.listen((dynamic event) {
      // Check if the event is an instance of the plugin's CallEvent type.
      if (event is CallEvent) {
        // Access the event property.
        if (event.event == Event.actionCallAccept) {
         _callKitEventController.add(CallKitEvent.accepted);
        } else if (event.event == Event.actionCallDecline) {
          _callKitEventController.add(CallKitEvent.declined);
        } else {
          print("[CallKit] Unknown action: $event.event");
        }
      } else {
        print("[CallKit] Unknown event type: $event");
      }
    });

    print("[CallKit] Showing incoming call from $callerName (id: $callId)");
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<void> hideIncomingCall({required String callId}) async {
    await FlutterCallkitIncoming.endCall(callId);
  }
}
