import 'package:flutter/material.dart';

class AttachedTooltip extends StatelessWidget {
  final LayerLink link;
  final String message;
  final Offset offset;
  final double width;
  final Duration duration;
  final Color backgroundColor;
  final TextStyle textStyle;

  const AttachedTooltip({
    super.key,
    required this.link,
    required this.message,
    this.offset = const Offset(0, -50),
    this.width = 300,
    this.duration = const Duration(seconds: 2),
    this.backgroundColor = Colors.black87,
    this.textStyle = const TextStyle(color: Colors.white),
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      width: width,
      child: CompositedTransformFollower(
        link: link,
        showWhenUnlinked: false,
        offset: offset,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(message, style: textStyle),
          ),
        ),
      ),
    );
  }
}


