import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rtc/src/common.dart';

typedef DurationFormatter = String Function(Duration);

/// Displays a duration that updates every second.
///
/// - [notifier]: the ValueListenable<Duration> that emits the ticks.
/// - [style]: the text style.
/// - [formatter]: optional function to convert Duration to String;
///   defaults to `duration.toCallFormat()`.
class CallDurationText extends StatelessWidget {
  final _defaultStyle = const TextStyle(
    color: Colors.white70,
    fontSize: 14,
    decoration: TextDecoration.none,
  );
  final ValueListenable<Duration> notifier;
  final TextStyle? style;
  final DurationFormatter? formatter;

  const CallDurationText({super.key, required this.notifier, this.style, this.formatter});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: notifier,
      builder: (context, duration, child) {
        final text = formatter?.call(duration) ?? duration.toCallFormat();
        return Text(text, style: style ?? _defaultStyle, textAlign: TextAlign.center);
      },
    );
  }
}
