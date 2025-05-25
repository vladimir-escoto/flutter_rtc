import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandableContainer extends StatefulWidget {
  final Widget leftChild;
  final Widget Function(double offset) rightChildBuilder;
  final double dragThreshold;
  final Widget pinnedChild;

  final VoidCallback? onStart;
  final VoidCallback? onCancel;
  final VoidCallback? onStop;

  const ExpandableContainer({
    super.key,
    required this.leftChild,
    required this.rightChildBuilder,
    required this.pinnedChild,
    this.dragThreshold = 90.0,
    this.onStart,
    this.onCancel,
    this.onStop,
  });

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

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _offsetBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _leftWidthFactor = Tween<double>(begin: 0.8, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightWidthFactor = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
      curve: Curves.easeOut,
    ));

    _offsetBackController.reset();
    _offsetBackController.forward();
  }

  void _handleTapUp() {
    if (_isExpanded) {
      widget.onStop?.call();
      _animateOffsetBackToZero();
      _reverseCollapse();
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
              animation: _leftWidthFactor,
              builder: (_, __) =>
                  SizedBox(
                    width: constraints.maxWidth * _leftWidthFactor.value,
                    child: widget.leftChild,
                  ),
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
                      width: constraints.maxWidth * _rightWidthFactor.value,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Right child (main)
                          Transform.translate(
                            offset: Offset(_dragOffset, 0),
                            child: widget.rightChildBuilder(_dragOffset),
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
