import 'dart:async';
import 'package:flutter/material.dart';

/// States for the floating widget.
enum RenderStatus { idle, expanded, collapsed }

enum HorizontalPosition { left, right }

enum VerticalPosition { top, middle, bottom }

typedef TabCallback =
    bool Function(RenderStatus status, HorizontalPosition hPos, VerticalPosition vPos);

typedef FloatingBuilder =
    Widget Function(BuildContext, RenderStatus, HorizontalPosition, VerticalPosition);

/// A generic, floating, draggable widget that snaps to corners or
/// collapses to a side tab. It supports idle, expanded, and collapsed states,
/// and delegates content rendering via a builder.
class FloatingDraggableWidget extends StatefulWidget {
  /// Builds the child when not collapsed. Receives the current state and position.
  final FloatingBuilder builder;

  /// Called when tapping in expanded state.
  final TabCallback? onTap;

  /// Initial horizontal and vertical positions when created.
  final HorizontalPosition initialHPos;
  final VerticalPosition initialVPos;

  /// Margins to clamp vertical movement in idle/expanded.
  final double topMargin;
  final double bottomMargin;

  /// Base size and margins.
  final double baseWidth;
  final double baseHeight;
  final double horizontalMargin;

  /// Collapse and expand configuration.
  final double collapseFactor;
  final double expandFactor;
  final double collapsedWidth;
  final double collapsedHeight;

  /// Fling detection threshold.
  final double flingThreshold;

  /// Durations and curves for animations.
  final Duration idleDuration;
  final Duration animationDuration;
  final Curve animationCurve;

  /// Styling.
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final Radius collapsedBorderRadius;

  const FloatingDraggableWidget({
    super.key,
    required this.builder,
    this.onTap,
    this.initialHPos = HorizontalPosition.right,
    this.initialVPos = VerticalPosition.bottom,
    this.topMargin = 16,
    this.bottomMargin = 16,
    this.baseWidth = 120,
    this.baseHeight = 160,
    this.horizontalMargin = 8,
    this.collapseFactor = 0.5,
    this.expandFactor = 1.4,
    this.collapsedWidth = 30,
    this.collapsedHeight = 140,
    this.flingThreshold = 800,
    this.idleDuration = const Duration(seconds: 2),
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
    this.backgroundColor = Colors.grey,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.collapsedBorderRadius = const Radius.circular(25),
  });

  @override
  State<FloatingDraggableWidget> createState() => _FloatingDraggableWidgetState();
}

class _FloatingDraggableWidgetState extends State<FloatingDraggableWidget> {
  RenderStatus _status = RenderStatus.idle;
  late HorizontalPosition _hPos;
  late VerticalPosition _vPos;
  Offset _dragOffset = Offset.zero;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _hPos = widget.initialHPos;
    _vPos = widget.initialVPos;
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    super.dispose();
  }

  void _enterIdle() {
    _idleTimer?.cancel();
    setState(() {
      _status = RenderStatus.idle;
      _dragOffset = Offset.zero;
    });
  }

  void _enterExpanded() {
    _idleTimer?.cancel();
    setState(() {
      _status = RenderStatus.expanded;
      _dragOffset = Offset.zero;
    });
    _idleTimer = Timer(widget.idleDuration, _enterIdle);
  }

  void _enterCollapsed(HorizontalPosition h, VerticalPosition v) {
    _idleTimer?.cancel();
    setState(() {
      _status = RenderStatus.collapsed;
      _hPos = h;
      _vPos = v;
      _dragOffset = Offset.zero;
    });
  }

  void _handleTap() {
    if (_status == RenderStatus.collapsed) {
      _enterIdle();
      return;
    }

    if (widget.onTap?.call(_status, _hPos, _vPos) ?? false) {
      return;
    }

    if (_status == RenderStatus.idle) {
      _enterExpanded();
    } else if (_status == RenderStatus.expanded) {
      _enterIdle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    // Compute dynamic width & height
    final double width =
        _status == RenderStatus.expanded
            ? widget.baseWidth * widget.expandFactor
            : (_status == RenderStatus.collapsed
                ? widget.collapsedWidth
                : widget.baseWidth);

    final double height =
        _status == RenderStatus.expanded
            ? widget.baseHeight * widget.expandFactor
            : (_status == RenderStatus.collapsed
                ? widget.collapsedHeight
                : widget.baseHeight);

    // Base X and Y positions
    final double leftX =
        _hPos == HorizontalPosition.left
            ? widget.horizontalMargin
            : screen.width - width - widget.horizontalMargin;
    double topY;
    switch (_vPos) {
      case VerticalPosition.top:
        topY = widget.topMargin;
        break;
      case VerticalPosition.middle:
        topY = (screen.height - height) / 2;
        break;
      case VerticalPosition.bottom:
        topY = screen.height - height - widget.bottomMargin;
        break;
    }

    // Raw drag-adjusted
    final double rawLeft = leftX + _dragOffset.dx;
    final double rawTop = topY + _dragOffset.dy;

    // Collapse threshold
    final double threshold = width * widget.collapseFactor;

    // Final position
    double finalLeft, finalTop;
    if (_status == RenderStatus.collapsed) {
      finalLeft = _hPos == HorizontalPosition.left ? 0 : screen.width - width;
      finalTop = topY;
    } else {
      finalLeft = rawLeft.clamp(
        widget.horizontalMargin,
        screen.width - width - widget.horizontalMargin,
      );
      finalTop = rawTop.clamp(
        widget.topMargin,
        screen.height - height - widget.bottomMargin,
      );
    }

    // Adaptive border radius
    final BorderRadius br =
        _status == RenderStatus.collapsed
            ? (_hPos == HorizontalPosition.left
                ? BorderRadius.only(
                  topRight: widget.collapsedBorderRadius,
                  bottomRight: widget.collapsedBorderRadius,
                )
                : BorderRadius.only(
                  topLeft: widget.collapsedBorderRadius,
                  bottomLeft: widget.collapsedBorderRadius,
                ))
            : widget.borderRadius;

    return AnimatedPositioned(
      left: finalLeft,
      top: finalTop,
      width: width,
      height: height,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      child: GestureDetector(
        onPanUpdate:
            (details) => setState(() {
              _dragOffset += details.delta;
            }),
        onPanEnd: (details) {
          // Handle dragging out of collapsed to idle
          if (_status == RenderStatus.collapsed) {
            final double releaseThreshold = widget.collapsedWidth / 2;
            if ((_hPos == HorizontalPosition.left && _dragOffset.dx > releaseThreshold) ||
                (_hPos == HorizontalPosition.right &&
                    _dragOffset.dx < -releaseThreshold)) {
              _enterIdle();
            }
            _dragOffset = Offset.zero;
            return;
          }
          // Collapse sides
          if (rawLeft < -threshold) {
            _enterCollapsed(HorizontalPosition.left, _vPos);
            return;
          }
          if (rawLeft + width > screen.width + threshold) {
            _enterCollapsed(HorizontalPosition.right, _vPos);
            return;
          }
          // Snap to corner or side band
          final Offset vel = details.velocity.pixelsPerSecond;
          final bool flingH = vel.dx.abs() > widget.flingThreshold;
          final HorizontalPosition newH =
              flingH
                  ? (vel.dx < 0 ? HorizontalPosition.left : HorizontalPosition.right)
                  : ((rawLeft + width / 2) < screen.width / 2
                      ? HorizontalPosition.left
                      : HorizontalPosition.right);
          final double centerY = rawTop + height / 2;
          final double band = screen.height / 3;
          final VerticalPosition newV =
              centerY < band
                  ? VerticalPosition.top
                  : (centerY > 2 * band
                      ? VerticalPosition.bottom
                      : VerticalPosition.middle);
          setState(() {
            _hPos = newH;
            _vPos = newV;
            _dragOffset = Offset.zero;
          });
        },
        onTap: _handleTap,
        child: Builder(
          builder: (context) {
            if (_status == RenderStatus.collapsed) {
              return Transform.rotate(
                angle: _hPos == HorizontalPosition.left ? 3.14159265359 : 0,
                child: CustomPaint(
                  size: Size(widget.collapsedWidth, widget.collapsedHeight),
                  painter: MyPainter(widget.backgroundColor),
                ),
              );
            }
            return widget.builder(context, _status, _hPos, _vPos);
          },
        ),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final Color backgroundColor;

  MyPainter(this.backgroundColor);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1
    paint.color = backgroundColor;
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
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
