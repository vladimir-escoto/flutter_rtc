import 'dart:async';
import 'package:flutter/material.dart';

import 'floating_collapsed_shape_decoration.dart';

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

  /// Which vertical positions are allowed (e.g. corners only).
  final List<VerticalPosition> allowedVerticalPositions;

  /// Margins to clamp vertical movement in idle/expanded.
  final double topMargin;
  final double bottomMargin;

  /// Base size and margins.
  final double baseWidth;
  final double baseHeight;

  /// Horizontal clamp margin.
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

  const FloatingDraggableWidget({
    super.key,
    required this.builder,
    this.onTap,
    this.initialHPos = HorizontalPosition.right,
    this.initialVPos = VerticalPosition.bottom,
    this.allowedVerticalPositions = const [VerticalPosition.top, VerticalPosition.bottom],
    this.topMargin = 16,
    this.bottomMargin = 16,
    this.baseWidth = 120,
    this.baseHeight = 160,
    this.horizontalMargin = 8,
    this.collapseFactor = 0.5,
    this.expandFactor = 1.4,
    this.collapsedWidth = 30,
    this.collapsedHeight = 140,
    this.flingThreshold = 50,
    this.idleDuration = const Duration(seconds: 2),
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
    this.backgroundColor = Colors.grey,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
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
    // ensure initial V pos is allowed, else default to first allowed
    _vPos =
        widget.allowedVerticalPositions.contains(widget.initialVPos)
            ? widget.initialVPos
            : widget.allowedVerticalPositions.first;
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
    if (isCollapsed) {
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

  bool get isCollapsed => _status == RenderStatus.collapsed;

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;
    final double width =
        (_status == RenderStatus.expanded)
            ? widget.baseWidth * widget.expandFactor
            : (isCollapsed ? widget.collapsedWidth : widget.baseWidth);
    final double height =
        (_status == RenderStatus.expanded)
            ? widget.baseHeight * widget.expandFactor
            : (isCollapsed ? widget.collapsedHeight : widget.baseHeight);

    final double leftX =
        (_hPos == HorizontalPosition.left)
            ? widget.horizontalMargin
            : screen.width - width - widget.horizontalMargin;

    // Compute allowed Y centers
    Map<VerticalPosition, double> yMap = {
      for (var v in widget.allowedVerticalPositions)
        v:
            (v == VerticalPosition.top)
                ? widget.topMargin
                : (v == VerticalPosition.middle)
                ? (screen.height - height) / 2
                : (screen.height - height - widget.bottomMargin),
    };

    final double rawLeft = leftX + _dragOffset.dx;
    final double rawTop = (yMap[_vPos] ?? 0) + _dragOffset.dy;
    final double threshold = width * widget.collapseFactor;
    double finalLeft, finalTop;

    if (isCollapsed) {
      finalLeft = (_hPos == HorizontalPosition.left) ? 0 : screen.width - width;
      finalTop = yMap[_vPos]!;
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

    return AnimatedPositioned(
      left: finalLeft,
      top: finalTop,
      width: width,
      height: height,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      child: GestureDetector(
        onPanUpdate: (d) => setState(() => _dragOffset += d.delta),
        onPanEnd: (details) {
          if (isCollapsed) {
            final double relThr = widget.collapsedWidth / 2;
            if ((_hPos == HorizontalPosition.left && _dragOffset.dx > relThr) ||
                (_hPos == HorizontalPosition.right && _dragOffset.dx < -relThr)) {
              _enterIdle();
            }
            _dragOffset = Offset.zero;
            return;
          }
          if (rawLeft < -threshold) {
            _enterCollapsed(HorizontalPosition.left, _vPos);
            return;
          }
          if (rawLeft + width > screen.width + threshold) {
            _enterCollapsed(HorizontalPosition.right, _vPos);
            return;
          }
          // Snap horizontal
          final Offset vel = details.velocity.pixelsPerSecond;
          final bool flingH = vel.dx.abs() > widget.flingThreshold;
          final HorizontalPosition newH =
              flingH
                  ? (vel.dx < 0 ? HorizontalPosition.left : HorizontalPosition.right)
                  : ((rawLeft + width / 2) < screen.width / 2
                      ? HorizontalPosition.left
                      : HorizontalPosition.right);
          // Snap vertical to nearest allowed
          final double centerY = rawTop + height / 2;
          VerticalPosition newV = widget.allowedVerticalPositions.first;
          double minDist = double.infinity;
          yMap.forEach((v, yVal) {
            final dist = (centerY - (yVal + height / 2)).abs();
            if (dist < minDist) {
              minDist = dist;
              newV = v;
            }
          });
          setState(() {
            _hPos = newH;
            _vPos = newV;
            _dragOffset = Offset.zero;
          });
        },
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          alignment: Alignment.center,
          decoration: FloatingCollapsedShapeDecoration(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            isCollapsed: isCollapsed,
            flipHorizontally: _hPos == HorizontalPosition.left,
          ),
          child: (isCollapsed) ? null : widget.builder(context, _status, _hPos, _vPos),
        ),
      ),
    );
  }
}
