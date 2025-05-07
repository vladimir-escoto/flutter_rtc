import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Display states for the floating renderer.
enum RenderStatus { idle, expanded, collapsed }

enum HorizontalPosition { left, right }

enum VerticalPosition { top, middle, bottom }

class SecondaryRendererWidget extends StatefulWidget {
  final bool secondaryStreamAvailable;
  final RTCVideoRenderer? secondaryRenderer;
  final bool isLocalMain;
  final VoidCallback onSwitchRenderers;
  final double topMargin;
  final double bottomMargin;

  /// [topMargin]/[bottomMargin] configure vertical clamp for idle/expanded.
  const SecondaryRendererWidget({
    super.key,
    required this.secondaryStreamAvailable,
    required this.secondaryRenderer,
    required this.isLocalMain,
    required this.onSwitchRenderers,
    this.topMargin = 125,
    this.bottomMargin = 150,
  });

  @override
  State<SecondaryRendererWidget> createState() => _SecondaryRendererWidgetState();
}

class _SecondaryRendererWidgetState extends State<SecondaryRendererWidget> {
  // Base dimensions
  static const double _baseWidth = 120;
  static const double _baseHeight = 160;

  // Horizontal clamp margin
  static const double _horizontalMargin = 16;

  // Fling threshold
  static const double _velocityThreshold = 800;

  // Fraction of current width to trigger collapse
  static const double _collapseFactor = 0.5;

  // Fraction of current width to trigger collapse
  static const double _expandFactor = 1.4;

  // Width when collapsed as a vertical tab
  static const double _collapsedWidth = 40;

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
    _idleTimer = Timer(const Duration(seconds: 2), _enterIdle);
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

    // Dimensions by state
    final double width =
        _status == RenderStatus.expanded
            ? _baseWidth * _expandFactor
            : _status == RenderStatus.collapsed
            ? _collapsedWidth
            : _baseWidth;
    final double height =
        _status == RenderStatus.expanded
            ? _baseHeight * _expandFactor
            : _status == RenderStatus.collapsed
            ? _baseHeight
            : _baseHeight;

    // Base x by horizontal position
    final double leftX =
        _hPos == HorizontalPosition.left
            ? _horizontalMargin
            : screen.width - width - _horizontalMargin;

    // Base y by vertical position
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

    // Raw position from drag
    final double rawLeft = leftX + _dragOffset.dx;
    final double rawTop = topY + _dragOffset.dy;

    // Collapse threshold
    final double collapseThreshold = width * _collapseFactor;

    double finalLeft;
    double finalTop;

    if (_status == RenderStatus.collapsed) {
      // Collapsed: flush to chosen side
      finalLeft = _hPos == HorizontalPosition.left ? 0 : screen.width - width;
      finalTop = topY;
    } else {
      // Idle/expanded: clamp inside
      finalLeft = rawLeft.clamp(
        _horizontalMargin,
        screen.width - width - _horizontalMargin,
      );
      finalTop = rawTop.clamp(
        widget.topMargin,
        screen.height - height - widget.bottomMargin,
      );
    }

    final radius = Radius.circular(_status == RenderStatus.collapsed ? 30 : 8);

    var borderRadius =
        _status == RenderStatus.collapsed
            ? (_hPos == HorizontalPosition.left
                ? BorderRadius.only(topRight: radius, bottomRight: radius)
                : BorderRadius.only(topLeft: radius, bottomLeft: radius))
            : BorderRadius.all(radius);

    return AnimatedPositioned(
      left: finalLeft,
      top: finalTop,
      width: width,
      height: height,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _dragOffset += details.delta;
          });
        },
        onPanEnd: (details) {
          if (_status == RenderStatus.collapsed) return;

          // Collapse if dragged beyond side
          if (rawLeft < -collapseThreshold) {
            _enterCollapsed(HorizontalPosition.left, _vPos);
            return;
          }

          if (rawLeft + width > screen.width + collapseThreshold) {
            _enterCollapsed(HorizontalPosition.right, _vPos);
            return;
          }

          // Determine horizontal position by fling or center
          final Offset velocity = details.velocity.pixelsPerSecond;
          final bool flingH = velocity.dx.abs() > _velocityThreshold;
          final HorizontalPosition h =
              flingH
                  ? (velocity.dx < 0 ? HorizontalPosition.left : HorizontalPosition.right)
                  : ((rawLeft + width / 2) < screen.width / 2
                      ? HorizontalPosition.left
                      : HorizontalPosition.right);

          // Determine vertical by nearest band: top/middle/bottom
          final double centerY = rawTop + height / 2;
          final double band = screen.height / 3;
          VerticalPosition v;
          if (centerY < band) {
            v = VerticalPosition.top;
          } else if (centerY > 2 * band) {
            v = VerticalPosition.bottom;
          } else {
            v = VerticalPosition.middle;
          }

          setState(() {
            _hPos = h;
            _vPos = v;
            _dragOffset = Offset.zero;
          });
        },
        onTap: _handleTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          decoration: BoxDecoration(color: Colors.grey, borderRadius: borderRadius),
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
      return RTCVideoView(widget.secondaryRenderer!, mirror: !widget.isLocalMain);
    }
    return const Center(child: Icon(Icons.person, color: Colors.white, size: 60));
  }
}
