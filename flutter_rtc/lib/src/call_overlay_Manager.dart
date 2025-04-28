import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/context/bloc/call_bloc.dart';
import 'package:flutter_rtc/src/ui/call_container_screen.dart';

import 'context/call_context.dart';
import 'coordinator/call_coordinator.dart';

class CallOverlayManager {
  static final CallOverlayManager instance = CallOverlayManager._internal();

  final Map<String, OverlayEntry> _entries = {};
  late StreamSubscription _sub;

  CallOverlayManager._internal();

  CallViewBuilder? outgoingView;
  CallViewBuilder? incomingView;
  CallViewBuilder? activeCallView;
  CallViewBuilder? endedView;
  CallViewBuilder? declineView;
  CallViewBuilder? errorView;

  OverlayState? _overlayState;
  bool _initialized = false;

  void setOutgoingView(CallViewBuilder builder) {
    outgoingView = builder;
  }

  void initialize(OverlayState overlayState) {
    if (_initialized) return;
    debugPrint('[CallOverlayManager] setAppLifecycleState initialize');

    _overlayState = overlayState;
    _sub = CallCoordinator.instance.callStateStream.listen(_onCallsChanged);
    _initialized = true;
  }

  void _onCallsChanged(List<CallContext> calls) {
    debugPrint('[CallOverlayManager] _onCallsChanged calls:${calls.length}');
    final callIds = calls.map((c) => c.callId).toSet();

    // Remove overlays that no longer exist
    for (final id in _entries.keys.toList()) {
      if (!callIds.contains(id)) {
        debugPrint('[CallOverlayManager] Remove Overlay for CallId:$id ');
        _entries[id]?.remove();
        _entries.remove(id);
      }
    }

    if (calls.any((c) => c.isActive)) {
      final activeCall = calls.firstWhere((c) => c.isActive);
      _addOverlay(activeCall);
    } else if (calls.any((c) => c.isOnHold)) {
      final holdCall = calls.firstWhere((c) => c.isOnHold);
      _addOverlay(holdCall);
    }
  }

  void _addOverlay(CallContext call) {
    if (_overlayState == null || _entries.containsKey(call.callId)) return;

    final entry = OverlayEntry(
      builder: (_) => _callContainerScreenBuilder(call.callBloc),
    );

    _clearAllOverlays();
    debugPrint('[CallOverlayManager] Add Overlay for CallId:${call.callId} ');
    _overlayState!.insert(entry);
    _entries[call.callId] = entry;
  }

  Widget _callContainerScreenBuilder(CallBloc callBloc) => CallContainerScreen(
    callBloc: callBloc,
    outgoingView: outgoingView,
    incomingView: incomingView,
    activeCallView: activeCallView,
    endedView: endedView,
    declineView: declineView,
    errorView: errorView,
  );

  void _clearAllOverlays() {
    for (final entry in _entries.values) {
      entry.remove();
    }
    _entries.clear();
  }

  void setCustomBuilders({
    CallViewBuilder? outgoingView,
    CallViewBuilder? incomingView,
    CallViewBuilder? activeCallView,
    CallViewBuilder? endedView,
    CallViewBuilder? declineView,
    CallViewBuilder? errorView,
  }) {
    this.outgoingView = outgoingView;
    this.incomingView = incomingView;
    this.activeCallView = activeCallView;
    this.endedView = endedView;
    this.declineView = declineView;
    this.errorView = errorView;
  }

  void dispose() {
    _sub.cancel();
    _clearAllOverlays();
  }
}
