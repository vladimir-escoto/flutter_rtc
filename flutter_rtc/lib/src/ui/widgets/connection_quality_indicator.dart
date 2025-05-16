import 'package:flutter/material.dart';

/// A widget to display connection quality using a series of bars.
///
/// This widget represents connection strength with a number of vertical bars,
/// where the number of active (colored) bars indicates the quality.
class ConnectionQualityIndicator extends StatelessWidget {
  /// The current connection quality, determining how many bars are active.
  /// Must be between 0 and [barCount].
  final int quality;

  /// The total number of bars to display.
  final int barCount;

  /// The color of the active bars. Inactive bars will use this color
  /// with reduced opacity.
  final Color activeColor;

  /// Creates a [ConnectionQualityIndicator].
  const ConnectionQualityIndicator({
    super.key,
    required this.quality,
    this.barCount = 3,
    this.activeColor = Colors.green,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(barCount, (index) {
        final bool isActive = index < quality;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 1),
          width: 4,
          height: (index + 1) * 4.0,
          decoration: BoxDecoration(
            color: isActive ? activeColor : activeColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        );
      }),
    );
  }
}
