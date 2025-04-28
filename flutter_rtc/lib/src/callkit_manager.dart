import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_rtc/src/context/model/member.dart';

typedef GlobalEventCallback = void Function(CallKitEventData event);

enum CallKitEvent {
  incoming,
  start,
  accept,
  decline,
  ended,
  timeout,
  actionCallback,
  toggleHold,
  toggleMute,
  toggleDmtf,
  toggleGroup,
  toggleAudioSession,
  actionCustom,
}

class CallKitEventData {
  final String callId;
  final CallKitEvent event;
  final dynamic body;

  CallKitEventData(this.callId, this.event, this.body);
}

class CallKitManager {
  // Singleton
  static final CallKitManager _instance = CallKitManager._internal();

  factory CallKitManager() => _instance;

  CallKitManager._internal() {
    // Subscribe only once to the native events
    _nativeSub = FlutterCallkitIncoming.onEvent.listen(_onNativeEvent);
  }

  late final StreamSubscription<dynamic> _nativeSub;
  final Map<String, StreamController<CallKitEventData>> _controllers = {};

  GlobalEventCallback? _onGlobalEvent;

  bool isCallShowing(String callId) {
    return _controllers.containsKey(callId);
  }

  void setGlobalEventCallback(GlobalEventCallback? callback) {
    _onGlobalEvent = callback;
  }

  /// Gets an event stream for a specific call.
  /// If it does not exist, it creates it in broadcast mode.
  Stream<CallKitEventData> eventsFor(String callId) {
    return _controllers
        .putIfAbsent(callId, () => StreamController<CallKitEventData>.broadcast())
        .stream;
  }

  /// Displays the incoming call notification.
  Future<void> showOutgoingCall({
    required String callId,
    required String callerName,
    Map<String, dynamic>? body = const {},
    Map<String, dynamic>? headers = const {},
    int type = 0,
  }) async {
    final params = await _makeCallKitParams(
      callId: callId,
      callerName: callerName,
      body: body,
      headers: headers,
      type: type,
    );
    if (params == null) return;

    debugPrint("[CallKit] showOutgoingCall from $callerName (id: $callId)");
    await FlutterCallkitIncoming.startCall(params);
  }

  Future<void> showCallkitIncoming({
    required String callId,
    required String callerName,
    Map<String, dynamic>? body = const {},
    Map<String, dynamic>? headers = const {},
    int type = 0,
  }) async {
    final params = await _makeCallKitParams(
      callId: callId,
      callerName: callerName,
      body: body,
      headers: headers,
      type: type,
    );
    if (params == null) return;
    debugPrint("[CallKit] showCallkitIncoming from $callerName (id: $callId)");
    await FlutterCallkitIncoming.showCallkitIncoming(params);
  }

  Future<CallKitParams?> _makeCallKitParams({
    required String callId,
    required String callerName,
    Map<String, dynamic>? body = const {},
    Map<String, dynamic>? headers = const {},
    int type = 0,
  }) async {
    if (isCallShowing(callId)) {
      debugPrint("[CallKit] Call $callId already exists");
      return null;
    }

    if (Platform.isAndroid) {
      await FlutterCallkitIncoming.requestFullIntentPermission();
    }

    // Creates a new controller for this call
    final controller = StreamController<CallKitEventData>.broadcast();
    _controllers[callId] = controller;

    return CallKitParams(
      id: callId,
      nameCaller: callerName,
      appName: 'Tr3sPass',
      avatar: 'https://i.pravatar.cc/100',
      type: type,
      duration: 30000,
      textAccept: 'Accept',
      textDecline: 'Decline',
      missedCallNotification: _getMissedCallNotification(),
      extra: body,
      headers: headers,
      android: _androidParams(),
      ios: _getIosParams(),
    );
  }

  Future<void> setCallConnected(String callId) async {
    if (!isCallShowing(callId)) return;
    await FlutterCallkitIncoming.setCallConnected(callId);
  }

  Future<void> endCall(String callId) async {
    //TODO: validate Callkit active calls
    if (!isCallShowing(callId)) return;
    debugPrint("[CallKit] Ending call $callId");
    await FlutterCallkitIncoming.endCall(callId);
    _controllers.remove(callId)?.close();
  }

  Future<void> holdCall(String callId, {bool isOnHold = true}) async {
    //TODO: validate Callkit active calls
    if (!isCallShowing(callId)) return;
    debugPrint("[CallKit] hold call $callId");
    await FlutterCallkitIncoming.holdCall(callId, isOnHold: isOnHold);
  }

  Future<void> endAllCalls() async {
    await FlutterCallkitIncoming.endAllCalls();
    for (final ctrl in _controllers.values) {
      await ctrl.close();
    }
    _controllers.clear();
  }

  Future<void> muteCall(String callId, bool micEnabled) async {
    if (!isCallShowing(callId)) return;
    var isMute = await FlutterCallkitIncoming.isMuted(callId);
    if (isMute != micEnabled) {
      await FlutterCallkitIncoming.muteCall(callId, isMuted: micEnabled);
    }
  }

  Future<void> dispose() async {
    await _nativeSub.cancel();
    endAllCalls();
  }

  /// Handles all native events and routes them by callId.
  void _onNativeEvent(CallEvent? raw) {
    if (raw is CallEvent) {
      final id = raw.body['id'] as String?;
      final action = _mapEvent(raw.event);
      if (id != null && action != null) {
        final event = CallKitEventData(id, action, raw.body);
        _onGlobalEvent?.call(event);
        final ctrl = _controllers[id];
        if (ctrl != null && !ctrl.isClosed) {
          ctrl.add(event);
        }
      }
    }
  }

  /// Translates native events to our enum
  CallKitEvent? _mapEvent(Event e) {
    switch (e) {
      case Event.actionCallAccept:
        return CallKitEvent.accept;
      case Event.actionCallDecline:
        return CallKitEvent.decline;
      case Event.actionDidUpdateDevicePushTokenVoip:
        debugPrint("[CallKit] actionDidUpdateDevicePushTokenVoip received");
        return null;
      case Event.actionCallIncoming:
        return CallKitEvent.incoming;
      case Event.actionCallStart:
        return CallKitEvent.start;
      case Event.actionCallEnded:
        return CallKitEvent.ended;
      case Event.actionCallTimeout:
        return CallKitEvent.timeout;
      case Event.actionCallCallback:
        return CallKitEvent.actionCallback;
      case Event.actionCallToggleHold:
        return CallKitEvent.toggleHold;
      case Event.actionCallToggleMute:
        return CallKitEvent.toggleMute;
      case Event.actionCallToggleDmtf:
        return CallKitEvent.toggleDmtf;
      case Event.actionCallToggleGroup:
        return CallKitEvent.toggleGroup;
      case Event.actionCallToggleAudioSession:
        return CallKitEvent.toggleAudioSession;
      case Event.actionCallCustom:
        return CallKitEvent.actionCustom;
    }
  }

  NotificationParams _getMissedCallNotification() => NotificationParams(
    showNotification: true,
    isShowCallback: true,
    subtitle: 'Missed call',
    callbackText: 'Call back',
  );

  IOSParams _getIosParams() => IOSParams(
    iconName: 'AppIcon',
    handleType: '',
    supportsVideo: true,
    maximumCallGroups: 3,
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
  );

  AndroidParams _androidParams() => AndroidParams(
    isCustomNotification: true,
    isShowLogo: true,
    ringtonePath: 'system_ringtone_default',
    backgroundColor: '#0955fa',
    backgroundUrl: 'assets/test.png',
    actionColor: '#4CAF50',
    textColor: '#ffffff',
  );
}
