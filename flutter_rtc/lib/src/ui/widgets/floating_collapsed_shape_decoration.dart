import 'package:flutter/material.dart';

/// Custom Decoration that can flip its shape horizontally based on [flipHorizontally].
class FloatingCollapsedShapeDecoration extends Decoration {
  final Color color;
  final Radius radius;

  /// If true, the shape is mirrored horizontally.
  final bool flipHorizontally;

  final bool isCollapsed;

  const FloatingCollapsedShapeDecoration({
    required this.color,
    this.radius = const Radius.circular(25),
    this.flipHorizontally = false,
    this.isCollapsed = false,
  });

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _FloatingCollapsedShapePainter(this);
  }

  @override
  EdgeInsetsGeometry get padding => EdgeInsets.zero;
}

class _FloatingCollapsedShapePainter extends BoxPainter {
  final FloatingCollapsedShapeDecoration decoration;

  _FloatingCollapsedShapePainter(this.decoration);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration config) {
    final Size size = config.size ?? Size.zero;
    canvas.save();
    // translate to the container's origin
    canvas.translate(offset.dx, offset.dy);

    // Flip horizontally if needed
    if (decoration.flipHorizontally) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    Paint paint = Paint();
    Path path = Path();

    // Path number 1
    paint.color = decoration.color;
    path = Path();
    path.lineTo(size.width, 0);
    path.cubicTo(
      size.width,
      size.height * 0.06,
      size.width * 0.78,
      size.height * 0.11,
      size.width / 2,
      size.height * 0.11,
    );
    path.cubicTo(
      size.width / 2,
      size.height * 0.11,
      size.width / 2,
      size.height * 0.11,
      size.width / 2,
      size.height * 0.11,
    );
    path.cubicTo(
      size.width * 0.22,
      size.height * 0.11,
      0,
      size.height * 0.16,
      0,
      size.height * 0.22,
    );
    path.cubicTo(0, size.height * 0.22, 0, size.height * 0.78, 0, size.height * 0.78);
    path.cubicTo(
      0,
      size.height * 0.84,
      size.width * 0.22,
      size.height * 0.89,
      size.width / 2,
      size.height * 0.89,
    );
    path.cubicTo(
      size.width / 2,
      size.height * 0.89,
      size.width / 2,
      size.height * 0.89,
      size.width / 2,
      size.height * 0.89,
    );
    path.cubicTo(
      size.width * 0.78,
      size.height * 0.89,
      size.width,
      size.height * 0.94,
      size.width,
      size.height,
    );
    path.cubicTo(size.width, size.height, size.width, 0, size.width, 0);
    path.cubicTo(size.width, 0, size.width, 0, size.width, 0);
    canvas.drawPath(path, paint);

    // Path number 2
    paint.color = Colors.white;
    path = Path();
    path.lineTo(size.width * 0.58, size.height * 0.62);
    path.cubicTo(
      size.width * 0.56,
      size.height * 0.62,
      size.width * 0.53,
      size.height * 0.61,
      size.width * 0.52,
      size.height * 0.61,
    );
    path.cubicTo(
      size.width * 0.52,
      size.height * 0.61,
      size.width * 0.3,
      size.height * 0.51,
      size.width * 0.3,
      size.height * 0.51,
    );
    path.cubicTo(
      size.width * 0.28,
      size.height / 2,
      size.width * 0.28,
      size.height / 2,
      size.width * 0.3,
      size.height * 0.49,
    );
    path.cubicTo(
      size.width * 0.3,
      size.height * 0.49,
      size.width * 0.52,
      size.height * 0.39,
      size.width * 0.52,
      size.height * 0.39,
    );
    path.cubicTo(
      size.width * 0.54,
      size.height * 0.38,
      size.width * 0.58,
      size.height * 0.38,
      size.width * 0.62,
      size.height * 0.39,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.39,
      size.width * 0.67,
      size.height * 0.4,
      size.width * 0.65,
      size.height * 0.41,
    );
    path.cubicTo(
      size.width * 0.65,
      size.height * 0.41,
      size.width * 0.44,
      size.height / 2,
      size.width * 0.44,
      size.height / 2,
    );
    path.cubicTo(
      size.width * 0.44,
      size.height / 2,
      size.width * 0.65,
      size.height * 0.59,
      size.width * 0.65,
      size.height * 0.59,
    );
    path.cubicTo(
      size.width * 0.67,
      size.height * 0.6,
      size.width * 0.65,
      size.height * 0.61,
      size.width * 0.62,
      size.height * 0.61,
    );
    path.cubicTo(
      size.width * 0.61,
      size.height * 0.62,
      size.width * 0.59,
      size.height * 0.62,
      size.width * 0.58,
      size.height * 0.62,
    );
    path.cubicTo(
      size.width * 0.58,
      size.height * 0.62,
      size.width * 0.58,
      size.height * 0.62,
      size.width * 0.58,
      size.height * 0.62,
    );
    canvas.drawPath(path, paint);

    canvas.restore();
  }
}
