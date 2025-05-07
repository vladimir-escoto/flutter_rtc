import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Display states for the floating renderer.
enum RenderStatus { idle, expanded, collapsed }

enum HorizontalPosition { left, right }
enum VerticalPosition { top, middle, bottom }

/// A floating, draggable WebRTC video renderer widget that snaps to
/// corners or collapses to a side tab. Fully configurable.
class SecondaryRendererWidget extends StatefulWidget {
  /// Whether the secondary stream is available.
  final bool secondaryStreamAvailable;
  /// The video renderer for secondary stream.
  final RTCVideoRenderer? secondaryRenderer;
  /// If true, local video is shown as main; determines mirroring logic.
  final bool isLocalMain;
  /// Callback when tapping in expanded state.
  final VoidCallback onSwitchRenderers;

  /// Vertical clamp margins when idle/expanded.
  final double topMargin;
  final double bottomMargin;

  /// Base dimensions in idle state.
  final double baseWidth;
  final double baseHeight;

  /// Horizontal clamp margin.
  final double horizontalMargin;

  /// Fraction of width to trigger collapse when dragging.
  final double collapseFactor;
  /// Scale factor for expanded state.
  final double expandFactor;
  /// Width of the collapsed tab.
  final double collapsedWidth;
  /// Height of the collapsed tab.
  final double collapsedHeight;
  /// Velocity threshold for fling detection (px/s).
  final double flingThreshold;

  /// Duration to remain expanded before returning to idle.
  final Duration idleDuration;
  /// Animation duration for position/size transitions.
  final Duration animationDuration;
  /// Curve for animations.
  final Curve animationCurve;

  /// Background color for renderer container.
  final Color backgroundColor;
  /// Border radius when not collapsed.
  final BorderRadius borderRadius;
  /// Border radius when collapsed.
  final Radius collapsedBorderRadius;

  const SecondaryRendererWidget({
    super.key,
    required this.secondaryStreamAvailable,
    required this.secondaryRenderer,
    required this.isLocalMain,
    required this.onSwitchRenderers,
    this.topMargin = 125,
    this.bottomMargin = 150,
    this.baseWidth = 120,
    this.baseHeight = 160,
    this.horizontalMargin = 16,
    this.collapseFactor = 0.5,
    this.expandFactor = 1.4,
    this.collapsedWidth = 30,
    this.collapsedHeight = 100,
    this.flingThreshold = 800,
    this.idleDuration = const Duration(seconds: 2),
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOut,
    this.backgroundColor = Colors.grey,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.collapsedBorderRadius = const Radius.circular(25),
  });

  @override
  State<SecondaryRendererWidget> createState() => _SecondaryRendererWidgetState();
}

class _SecondaryRendererWidgetState extends State<SecondaryRendererWidget> {
  RenderStatus _status = RenderStatus.idle;
  HorizontalPosition _hPos = HorizontalPosition.right;
  VerticalPosition _vPos = VerticalPosition.bottom;
  Offset _dragOffset = Offset.zero;
  Timer? _idleTimer;

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
    switch (_status) {
      case RenderStatus.idle:
        _enterExpanded();
        break;
      case RenderStatus.expanded:
        widget.onSwitchRenderers();
        break;
      case RenderStatus.collapsed:
        _enterIdle();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.of(context).size;

    // Compute dimensions
    final double width = _status == RenderStatus.expanded
        ? widget.baseWidth * widget.expandFactor
        : (_status == RenderStatus.collapsed
        ? widget.collapsedWidth
        : widget.baseWidth);

    final double height = _status == RenderStatus.expanded
        ? widget.baseHeight * widget.expandFactor
        : (_status == RenderStatus.collapsed
        ? widget.collapsedHeight
        : widget.baseHeight);

    // Base X and Y positions
    final double leftX = _hPos == HorizontalPosition.left
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

    // Border radius adapts for collapsed
    final BorderRadius br = _status == RenderStatus.collapsed
        ? (_hPos == HorizontalPosition.left
        ? BorderRadius.only(
        topRight: widget.collapsedBorderRadius,
        bottomRight: widget.collapsedBorderRadius)
        : BorderRadius.only(
        topLeft: widget.collapsedBorderRadius,
        bottomLeft: widget.collapsedBorderRadius))
        : widget.borderRadius;

    return AnimatedPositioned(
      left: finalLeft,
      top: finalTop,
      width: width,
      height: height,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
      child: GestureDetector(
        onPanUpdate: (details) => setState(() {
          _dragOffset += details.delta;
        }),
        onPanEnd: (details) {
          if (_status == RenderStatus.collapsed) return;
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
          final HorizontalPosition newH = flingH
              ? (vel.dx < 0
              ? HorizontalPosition.left
              : HorizontalPosition.right)
              : ((rawLeft + width / 2) < screen.width / 2
              ? HorizontalPosition.left
              : HorizontalPosition.right);
          final double centerY = rawTop + height / 2;
          final double band = screen.height / 3;
          final VerticalPosition newV = centerY < band
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
        child: AnimatedContainer(
          duration: widget.animationDuration,
          curve: widget.animationCurve,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: br,
          ),
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_status == RenderStatus.collapsed) {
      return Center(
        child: Icon(
          _hPos == HorizontalPosition.left
              ? Icons.arrow_forward_ios
              : Icons.arrow_back_ios,
          color: Colors.white,
        ),
      );
    }
    if (widget.secondaryStreamAvailable) {
      return RTCVideoView(
        widget.secondaryRenderer!,
        mirror: !widget.isLocalMain,
      );
    }
    return const Center(
      child: Icon(Icons.person, color: Colors.white, size: 60),
    );
  }
}
