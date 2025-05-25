import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandableContainer extends StatefulWidget {
  final Widget leftChild;
  final Widget Function(bool isExpanded, bool animating) rightChildBuilder;
  final Widget pinnedChild;

  final double dragThreshold;
  final double leftInitialWidthFactor;
  final double rightInitialWidthFactor;
  final double rightExpandedWidthFactor;
  final double maxLeftShiftFactor;

  final Duration animationDuration;
  final Duration offsetReturnDuration;
  final Curve slideCurve;

  final VoidCallback? onStart;
  final VoidCallback? onCancel;
  final VoidCallback? onStop;
  final VoidCallback? onFastCancel;

  const ExpandableContainer({
    super.key,
    required this.leftChild,
    required this.rightChildBuilder,
    required this.pinnedChild,
    this.dragThreshold = 90.0,
    this.leftInitialWidthFactor = 0.8,
    this.rightInitialWidthFactor = 0.2,
    this.rightExpandedWidthFactor = 1.0,
    double? maxLeftShiftFactor,
    this.animationDuration = const Duration(milliseconds: 300),
    this.offsetReturnDuration = const Duration(milliseconds: 300),
    this.slideCurve = Curves.easeInOut,
    this.onStart,
    this.onCancel,
    this.onStop,
    this.onFastCancel,
  }) : maxLeftShiftFactor = maxLeftShiftFactor ?? leftInitialWidthFactor;

  @override
  State<ExpandableContainer> createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _offsetBackController;

  late Animation<double> _leftWidthFactor;
  late Animation<double> _rightWidthFactor;
  late Animation<double> _offsetAnimation;

  bool _isExpanded = false;
  bool _isInteracting = false;
  double _dragOffset = 0.0;
  double _dragDistance = 0.0;

  bool get isExpanding => _controller.status == AnimationStatus.forward;

  bool get isAnimating => _controller.status.isAnimating;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _offsetBackController = AnimationController(
      vsync: this,
      duration: widget.offsetReturnDuration,
    );

    _leftWidthFactor = Tween<double>(
      begin: widget.leftInitialWidthFactor,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.slideCurve));

    _rightWidthFactor = Tween<double>(
      begin: widget.rightInitialWidthFactor,
      end: widget.rightExpandedWidthFactor,
    ).animate(CurvedAnimation(parent: _controller, curve: widget.slideCurve));

    _controller.addStatusListener((status) {
      if (_controller.isAnimating) {
        setState(() {});
      }
      if (status == AnimationStatus.dismissed) {
        setState(() {
          _isExpanded = false;
          _dragOffset = 0.0;
          _dragDistance = 0.0;
          _isInteracting = false;
        });
      }
      if (status == AnimationStatus.completed) {
        setState(() {
          _isExpanded = true;
          _isInteracting = false;
        });
      }
    });

    _offsetBackController.addListener(() {
      setState(() {
        _dragOffset = _offsetAnimation.value;
      });
    });
  }

  void _startExpand() {
    if (_isInteracting || _isExpanded) return;
    _isInteracting = true;
    HapticFeedback.lightImpact();
    widget.onStart?.call();
    _controller.forward();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isExpanded || _isInteracting) return;

    _dragDistance += details.delta.dx;
    _dragOffset += details.delta.dx;

    if (_dragDistance.abs() > widget.dragThreshold) {
      widget.onCancel?.call();
      _reverseCollapse();
    } else {
      setState(() {});
    }
  }

  void _animateOffsetBackToZero() {
    if (_dragOffset.abs() <= 0) return;

    _offsetAnimation = Tween<double>(
      begin: _dragOffset,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _offsetBackController,
      curve: widget.slideCurve,
    ));

    _offsetBackController.reset();
    _offsetBackController.forward();
  }

  void _handleTapUp() {
    if (_isExpanded) {
      widget.onStop?.call();
      _animateOffsetBackToZero();
      _reverseCollapse();
    } else if (isExpanding) {
      _isInteracting = false;
      _reverseCollapse();
      widget.onFastCancel?.call();
    }
  }

  void _reverseCollapse() {
    if (_isInteracting) return;
    _isInteracting = true;
    HapticFeedback.mediumImpact();
    _controller.reverse();
  }

  @override
  void dispose() {
    _controller.dispose();
    _offsetBackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool showPinned = _controller.status.isCompleted;

    debugPrint("_controller.status: ${_controller.status}");

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            AnimatedBuilder(
              animation: Listenable.merge(
                  [_leftWidthFactor, _rightWidthFactor]),
              builder: (_, __) {
                final rightExpansion = _rightWidthFactor.value -
                    widget.rightInitialWidthFactor;
                final leftShift = -constraints.maxWidth * rightExpansion;

                return Transform.translate(
                  offset: Offset(
                    leftShift.clamp(
                        -constraints.maxWidth * widget.maxLeftShiftFactor, 0),
                    0,
                  ),
                  child: SizedBox(
                    width: constraints.maxWidth * _leftWidthFactor.value,
                    child: widget.leftChild,
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _rightWidthFactor,
              builder: (_, __) =>
                  GestureDetector(
                    onTapDown: (_) => _startExpand(),
                    onTapUp: (_) => _handleTapUp(),
                    onHorizontalDragUpdate: _handleDragUpdate,
                    onHorizontalDragEnd: (_) => _handleTapUp(),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      width: constraints.maxWidth * _rightWidthFactor.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Right child (main)
                          Transform.translate(
                            offset: Offset(_dragOffset, 0),
                            child: widget.rightChildBuilder(_isExpanded,isAnimating),
                          ),
                          // Pinned child (overlay, to the left)
                          if (showPinned)
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              child: widget.pinnedChild,
                            ),
                        ],
                      ),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}
