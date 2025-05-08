import 'dart:async';

import 'package:flutter/material.dart';

mixin CallTimerMixin<T extends StatefulWidget> on State<T> {
  late final Timer _timer;

  Duration get callDuration => DateTime.now().difference(initialCreatedAt);

  final ValueNotifier<Duration> durationNotifier = ValueNotifier(Duration.zero);

  /// Must be overridden to return the call's creation timestamp.
  @protected
  DateTime get initialCreatedAt;

  @override
  void initState() {
    super.initState();
    durationNotifier.value = callDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _handleTick());
  }

  void _handleTick() {
    final duration = callDuration;
    durationNotifier.value = duration;
  }

  @override
  void dispose() {
    _timer.cancel();
    durationNotifier.dispose();
    super.dispose();
  }
}
