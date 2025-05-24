import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExpandableContainer extends StatefulWidget {
  final Widget leftChild;
  final Widget Function(double offset) rightChildBuilder;
  final double dragThreshold;

  final VoidCallback? onStart;
  final VoidCallback? onCancel;
  final VoidCallback? onStop;

  const ExpandableContainer({
    super.key,
    required this.leftChild,
    required this.rightChildBuilder,
    this.dragThreshold = 90.0,
    this.onStart,
    this.onCancel,
    this.onStop,
  });

  @override
  State<ExpandableContainer> createState() => _ExpandableContainerState();
}

class _ExpandableContainerState extends State<ExpandableContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _leftWidthFactor;
  late Animation<double> _rightWidthFactor;

  bool _isExpanded = false;
  bool _isInteracting = false;
  double _dragOffset = 0.0;
  double _dragDistance = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _leftWidthFactor = Tween<double>(begin: 0.8, end: 0.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _rightWidthFactor = Tween<double>(begin: 0.2, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.addStatusListener((status) {
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

  void _reverseCollapse() {
    if (_isInteracting) return;
    _isInteracting = true;
    HapticFeedback.mediumImpact();
    _controller.reverse();
  }

  void _handleTapUp() {
    Future.delayed(const Duration(milliseconds: 300), () {
        if (_isExpanded) {
          widget.onStop?.call();
          _reverseCollapse();
        }
      });
  }


  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      child: _isExpanded
                          ? Transform.translate(
                        offset: Offset(_dragOffset, 0),
                        child: widget.rightChildBuilder(_dragOffset),
                      ) : widget.rightChildBuilder(0),
                    ),
                  ),
            ),
          ],
        );
      },
    );
  }
}
